const fs = require('node:fs')
const path = require('node:path')
const { reviewers, doNotMergeLabel, checksFields, directory, graphql, plainTitle, areaOf, checksOf, readMarks, stamp } = require('./pull-common.cjs')

const reviewDepthLimit = 3
const owner = 'augusthealth'
const repository = 'valinor'
const me = 'camentree'
const ticketPattern = /\b(?:MOV|INT|BILL)-\d+\b/gi
const pullReference = String.raw`(?:#|https://github\.com/augusthealth/valinor/pull/)(\d+)`
const dependencyPatterns = [
  new RegExp(String.raw`\b(?:do not merge until|depends on|blocked by|merge (?:only )?after|deploy(?:able)? (?:with or )?after|requires|needs(?: backend| frontend)?)\s+${pullReference}`, 'gi'),
  new RegExp(String.raw`\bafter\s+${pullReference}(?=\s+merges|\s*\([^)]*\)\s+merges)`, 'gi')
]
const migratedFromPattern = /Migrated from https:\/\/github\.com\/augusthealth\/([^/]+)\/pull\/(\d+)/

const pullsQuery = `query {
  search(query: "is:pr is:open author:${me} repo:${owner}/${repository}", type: ISSUE, first: 100) {
    nodes {
      ... on PullRequest {
        number url title body isDraft baseRefName headRefName additions deletions createdAt reviewDecision
        files(first: 100) { nodes { path } }
        labels(first: 20) { nodes { name } }
        reviewRequests(first: 15) { nodes { requestedReviewer { __typename ... on Team { slug } } } }
        commits(last: 1) { nodes { commit { committedDate ${checksFields} } } }
        latestReviews(first: 20) { nodes { author { login } state submittedAt } }
        reviewThreads(first: 100) { nodes { isResolved comments(first: 1) { nodes { author { __typename login } } } } }
      }
    }
  }
}`

const pullRequests = graphql(pullsQuery).search.nodes.filter((pullRequest) => pullRequest.number)
const migratedFrom = new Map(pullRequests.map((pullRequest) => [pullRequest.number, migratedFromPattern.exec(pullRequest.body || '')]).filter(([, match]) => match))
const originals = migratedFrom.size
  ? graphql(`query { ${[...migratedFrom].map(([number, match]) => `pull${number}: repository(owner: "${owner}", name: "${match[1]}") { pullRequest(number: ${match[2]}) { title body headRefName } }`).join('\n')} }`)
  : {}
const asked = readMarks().asked

const reviewWords = { COMMENTED: 'commented', CHANGES_REQUESTED: 'changes requested', APPROVED: 'approved', DISMISSED: 'dismissed' }

const pulls = pullRequests.map((pullRequest) => {
  const area = areaOf(pullRequest.files.nodes.map((file) => file.path))
  const lastCommit = pullRequest.commits.nodes[0].commit
  const doNotMerge = pullRequest.labels.nodes.some((label) => label.name === doNotMergeLabel)
  const openThreads = pullRequest.reviewThreads.nodes.filter((thread) => !thread.isResolved && thread.comments.nodes.length)
  const original = (originals[`pull${pullRequest.number}`] || {}).pullRequest || {}
  const ticketText = [pullRequest.title, pullRequest.body, pullRequest.headRefName, original.title, original.body, original.headRefName].join(' ')
  const needs = area === 'both' ? ['backend', 'frontend'] : [area]
  const reviews = {}
  for (const needed of needs) {
    const login = reviewers[needed].login
    const review = pullRequest.latestReviews.nodes.find((candidate) => candidate.author && candidate.author.login === login)
    const askedAt = (asked[pullRequest.url] || {})[login] || null
    const askStands = Boolean(askedAt) && (!review || askedAt > review.submittedAt)
    const pushedSince = Boolean(review) && lastCommit.committedDate > review.submittedAt
    let status
    if (review && review.state === 'APPROVED') status = 'approved'
    else if (!review) status = 'ask'
    else if (pushedSince || review.state === 'DISMISSED') status = 'rereview'
    else status = 'answer'
    reviews[login] = { review: review ? reviewWords[review.state] : 'none', reviewedAt: review ? review.submittedAt : null, pushedSince, asked: askStands ? askedAt : null, status }
  }
  return {
    number: pullRequest.number,
    url: pullRequest.url,
    title: plainTitle(pullRequest.title),
    draft: pullRequest.isDraft,
    area,
    needs: needs.map((needed) => reviewers[needed].login),
    createdAt: pullRequest.createdAt,
    additions: pullRequest.additions,
    deletions: pullRequest.deletions,
    size: pullRequest.additions + pullRequest.deletions,
    requestedTeams: pullRequest.reviewRequests.nodes.map((node) => node.requestedReviewer && node.requestedReviewer.slug).filter(Boolean),
    reviewDecision: pullRequest.reviewDecision,
    baseRefName: pullRequest.baseRefName,
    headRefName: pullRequest.headRefName,
    tickets: [...new Set((ticketText.match(ticketPattern) || []).map((ticket) => ticket.toUpperCase()))],
    checks: checksOf(lastCommit.statusCheckRollup, doNotMerge),
    doNotMerge,
    threads: { person: openThreads.filter((thread) => thread.comments.nodes[0].author && thread.comments.nodes[0].author.__typename !== 'Bot').length, bot: openThreads.filter((thread) => thread.comments.nodes[0].author && thread.comments.nodes[0].author.__typename === 'Bot').length },
    lastPush: lastCommit.committedDate,
    reviews,
    declared: dependencyPatterns.flatMap((pattern) => [...(pullRequest.body || '').split('\n').filter((line) => !migratedFromPattern.test(line)).join('\n').matchAll(pattern)].map((match) => Number(match[1])))
  }
})

const byHead = new Map(pulls.map((pull) => [pull.headRefName, pull]))
const bottomOf = (pull) => (byHead.has(pull.baseRefName) ? bottomOf(byHead.get(pull.baseRefName)) : pull)
const positionOf = (pull) => (byHead.has(pull.baseRefName) ? positionOf(byHead.get(pull.baseRefName)) + 1 : 1)
const hasAbove = (pull) => pulls.some((candidate) => candidate.baseRefName === pull.headRefName)
for (const pull of pulls) {
  const below = byHead.get(pull.baseRefName)
  pull.stack = below || hasAbove(pull) ? { id: bottomOf(pull).number, position: positionOf(pull), below: below ? below.number : null } : null
}
for (const pull of pulls) {
  if (pull.stack) pull.stack.size = pulls.filter((candidate) => candidate.stack && candidate.stack.id === pull.stack.id).length
  const halves = pulls.filter((candidate) => candidate !== pull && ['backend', 'frontend'].includes(candidate.area) && ['backend', 'frontend'].includes(pull.area) && candidate.area !== pull.area && (candidate.title === pull.title || candidate.tickets.some((ticket) => pull.tickets.includes(ticket))))
  pull.pair = halves.map((half) => half.number)
  pull.accepted = pull.needs.every((login) => pull.reviews[login].status === 'approved')
  delete pull.baseRefName
  delete pull.headRefName
}
const byNumber = new Map(pulls.map((pull) => [pull.number, pull]))
const nameOf = (login) => Object.values(reviewers).find((reviewer) => reviewer.login === login).name
const plural = (count, word) => `${count} ${word}${count === 1 ? '' : 's'}`
for (const pull of pulls) {
  pull.dependsOn = [...new Set(pull.declared)].filter((number) => number !== pull.number && byNumber.has(number))
  delete pull.declared
}
const levels = new Map()
const visiting = new Set()
const levelOf = (pull) => {
  if (levels.has(pull.number)) return levels.get(pull.number)
  visiting.add(pull.number)
  pull.after = null
  pull.cycleWith = null
  const below = byNumber.get(pull.stack && pull.stack.below)
  const stackLevel = below && !visiting.has(below.number) ? levelOf(below) : 0
  let declaredLevel = 0
  let deepestDependency = null
  for (const number of pull.dependsOn) {
    if (visiting.has(number)) {
      pull.cycleWith = number
      continue
    }
    const level = levelOf(byNumber.get(number))
    if (level > declaredLevel) {
      declaredLevel = level
      deepestDependency = number
    }
  }
  if (declaredLevel > stackLevel) pull.after = deepestDependency
  pull.reach = Math.max(stackLevel, declaredLevel)
  const level = (pull.accepted ? 0 : 1) + pull.reach
  visiting.delete(pull.number)
  levels.set(pull.number, level)
  return level
}
for (const pull of pulls) levelOf(pull)
for (const pull of pulls) {
  const reviews = Object.entries(pull.reviews)
  const answers = reviews.filter(([, review]) => review.status === 'answer')
  pull.waitsOn = [...new Set([...(pull.stack && pull.stack.below ? [pull.stack.below] : []), ...pull.pair, ...pull.dependsOn])]
  const notes = []
  if (pull.threads.person) notes.push(`${plural(pull.threads.person, 'thread')} to answer`)
  for (const [login, review] of answers) notes.push(review.review === 'changes requested' ? `${nameOf(login)} requested changes` : `${nameOf(login)} commented, nothing pushed since`)
  if (pull.checks === 'fail') notes.push('checks failing')
  if (pull.checks === 'pending') notes.push('checks running')
  if (pull.doNotMerge) notes.push('do not merge label')
  pull.depth = null
  if (pull.draft) pull.column = 'drafted'
  else if (pull.threads.person || answers.length || pull.checks === 'fail') pull.column = 'needs-me'
  else if (pull.accepted && (pull.doNotMerge || pull.waitsOn.length)) pull.column = 'blocked'
  else if (pull.accepted) pull.column = 'accepted'
  else {
    pull.depth = 1 + pull.reach
    pull.column = pull.depth === 1 ? 'needs-review' : pull.depth <= reviewDepthLimit ? 'can-review' : 'wait-to-review'
    if (pull.after) notes.push(`after valinor ${pull.after}`)
  }
  delete pull.reach
  if (pull.cycleWith) notes.push(`dependency cycle with valinor ${pull.cycleWith}, ignored`)
  if (pull.column === 'blocked') for (const number of pull.waitsOn) notes.push(`waits on valinor ${number}`)
  for (const [login, review] of reviews) if (review.status === 'rereview') notes.push(`updated since ${nameOf(login)}'s review`)
  const approvedBy = reviews.filter(([, review]) => review.status === 'approved').map(([login]) => nameOf(login))
  if (!pull.accepted && approvedBy.length) notes.push(`${approvedBy.join(' and ')} accepted, ${reviews.filter(([, review]) => review.status !== 'approved').map(([login]) => nameOf(login)).join(' and ')} left`)
  if (pull.threads.bot) notes.push(plural(pull.threads.bot, 'bot thread'))
  pull.notes = notes
  const sessionName = `pr ${pull.number} - ${pull.title.toLowerCase().replace(/[^a-z0-9 ]/g, '').split(/\s+/).slice(0, 3).join(' ')}`
  const checksOnly = pull.checks === 'fail' && !pull.threads.person && !answers.length
  pull.command = pull.column !== 'needs-me'
    ? null
    : checksOnly
      ? `cd ~/Projects/valinor && claude --model sonnet -n "${sessionName}" "In augusthealth/valinor, pull request ${pull.url} (${pull.title.replace(/"/g, "'")}) has failing checks. Find why they fail, fix it with a new commit on its branch and push it. Never rebase, amend or force-push."`
      : `cd ~/Projects/valinor && claude --model opus -n "${sessionName}" "/address-comments ${pull.url}"`
}

const result = {
  updated: stamp(new Date()),
  reviewers,
  pulls: pulls.sort((first, second) => first.number - second.number)
}
fs.writeFileSync(path.join(directory, 'prs.js'), `window.PRS = ${JSON.stringify(result, null, 2)};\n`)
if (process.argv.includes('--json')) console.log(JSON.stringify(result, null, 2))
else console.log(`wrote prs.js: ${pulls.length} open pull requests`)
