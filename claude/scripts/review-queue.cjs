const fs = require('node:fs')
const path = require('node:path')
const { checksFields, directory, graphql, plainTitle, areaOf, checksOf, readMarks, stamp } = require('./pull-common.cjs')

const owner = 'augusthealth'
const repositories = ['valinor', 'august-backend', 'august-frontend', 'Experimental-Tools']
const migratedFromPattern = /Migrated from (https:\/\/github\.com\/augusthealth\/august-(?:backend|frontend)\/pull\/\d+)/
const me = 'camentree'
const team = 'move-ins'
const teammates = ['jessebutterfield', 'jkjustjoshing']
const stateWords = { APPROVED: 'approved', CHANGES_REQUESTED: 'requested changes', COMMENTED: 'commented', DISMISSED: 'approved, since dismissed by a push' }
const authorShortNames = { jessebutterfield: 'jbutterfield' }
const largeChange = 800

const fields = `number title url isDraft body createdAt
  author { login }
  reviewRequests(first: 15) { nodes { requestedReviewer { __typename ... on User { login } ... on Team { slug } } } }
  latestReviews(first: 20) { nodes { author { login } state submittedAt } }
  commits(last: 1) { nodes { commit { committedDate authoredDate } } }
  timelineItems(first: 50, itemTypes: [REVIEW_REQUESTED_EVENT]) {
    nodes { ... on ReviewRequestedEvent { requestedReviewer { __typename ... on User { login } ... on Team { slug } } } }
  }`

const query = `query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    pullRequests(states: OPEN, first: 100, orderBy: { field: UPDATED_AT, direction: DESC }) { nodes { ${fields} } }
  }
}`

const oneQuery = `query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) { pullRequest(number: $number) { ${fields} } }
}`

const dismissed = readMarks().dismissed

const reviewerName = (reviewer) => (reviewer ? reviewer.login || reviewer.slug : null)
const asked = (pullRequest) => [...pullRequest.reviewRequests.nodes, ...pullRequest.timelineItems.nodes].map((node) => reviewerName(node.requestedReviewer)).filter(Boolean)

const open = repositories.map((name) => ({ name, pullRequests: graphql(query, ['-f', `owner=${owner}`, '-f', `name=${name}`]).repository.pullRequests.nodes }))
const openByUrl = new Map(open.flatMap(({ pullRequests }) => pullRequests.map((pullRequest) => [pullRequest.url, pullRequest])))

const movedFrom = (url) => {
  if (!url) return null
  if (openByUrl.has(url)) return openByUrl.get(url)
  const [, name, number] = /augusthealth\/([^/]+)\/pull\/(\d+)/.exec(url)
  return graphql(oneQuery, ['-f', `owner=${owner}`, '-f', `name=${name}`, '-F', `number=${number}`]).repository.pullRequest
}

const queue = []
const details = []
for (const { name, pullRequests } of open) {
  for (const pullRequest of pullRequests) {
    const author = pullRequest.author ? pullRequest.author.login : ''
    if (pullRequest.isDraft || author === me || author.startsWith('app/') || author.endsWith('[bot]')) continue
    const migratedFrom = (migratedFromPattern.exec(pullRequest.body || '') || [])[1] || null
    const source = movedFrom(migratedFrom)
    const pending = pullRequest.reviewRequests.nodes.map((node) => reviewerName(node.requestedReviewer)).filter(Boolean)
    const everAsked = new Set([...asked(pullRequest), ...(source ? asked(source) : [])])
    const ownReviews = pullRequest.latestReviews.nodes.filter((review) => review.author && review.author.login !== author)
    const carriedReviews = (source ? source.latestReviews.nodes : []).filter((review) => review.author && review.author.login !== author && !ownReviews.some((own) => own.author.login === review.author.login))
    const reviews = [...ownReviews, ...carriedReviews]
    const mine = reviews.find((review) => review.author.login === me)
    const askedMe = everAsked.has(me)
    const askedTeam = everAsked.has(team)
    if (!askedMe && !askedTeam && !mine) continue
    const lastCommitDates = pullRequest.commits.nodes.length ? pullRequest.commits.nodes[0].commit : null
    const lastCommit = lastCommitDates ? (carriedReviews.includes(mine) ? lastCommitDates.authoredDate : lastCommitDates.committedDate) : null
    const teammateReviews = reviews.filter((review) => teammates.includes(review.author.login))
    const pushedSince = Boolean(mine) && Boolean(lastCommit) && lastCommit > mine.submittedAt
    let needsMe
    let why
    if (mine) {
      needsMe = mine.state !== 'APPROVED' && pushedSince
      why = needsMe ? 'the author pushed after your review' : mine.state === 'APPROVED' ? 'you approved it' : 'you reviewed it and the author has not pushed since'
    } else if (pending.includes(me) || askedMe) {
      needsMe = true
      why = 'asks for you by name'
    } else if (teammateReviews.length) {
      continue
    } else {
      needsMe = true
      why = 'asks for move-ins and no move-ins teammate has reviewed'
    }
    const isDismissed = Boolean(dismissed[pullRequest.url])
    if (isDismissed) {
      needsMe = false
      why = 'you marked it as not needing you'
    }
    queue.push({
      repository: name,
      number: pullRequest.number,
      title: pullRequest.title,
      url: pullRequest.url,
      migratedFrom,
      author,
      asked: [askedMe ? 'you' : null, askedTeam ? team : null].filter(Boolean),
      reviews: reviews.map((review) => `${review.author.login} ${stateWords[review.state] || review.state.toLowerCase()}`),
      needsMe,
      why
    })
    const teams = [...new Set([...pullRequest.reviewRequests.nodes, ...pullRequest.timelineItems.nodes].map((node) => node.requestedReviewer).filter((reviewer) => reviewer && reviewer.__typename === 'Team').map((reviewer) => reviewer.slug))]
    details.push({
      repository: name,
      number: pullRequest.number,
      url: pullRequest.url,
      migratedFrom,
      title: plainTitle(pullRequest.title),
      author,
      createdAt: pullRequest.createdAt,
      area: name === 'august-frontend' ? 'frontend' : name === 'august-backend' ? 'backend' : null,
      teams,
      reviewCount: reviews.filter((review) => !review.author.login.endsWith('[bot]') && review.author.login !== 'greptile-apps').length,
      draft: pullRequest.isDraft,
      askedMe,
      reviewedByMe: Boolean(mine),
      pushedSince,
      section: isDismissed ? 'dismissed' : mine && pushedSince && mine.state !== 'APPROVED' ? 're-review' : mine ? 'reviewed' : 'needs-you',
      reason: askedMe ? 'asks you' : 'asks move-ins'
    })
  }
}

for (const name of repositories) {
  const entries = details.filter((entry) => entry.repository === name)
  if (!entries.length) continue
  const extra = graphql(`query { repository(owner: "${owner}", name: "${name}") { ${entries.map((entry) => `pull${entry.number}: pullRequest(number: ${entry.number}) { additions deletions reviewDecision files(first: 100) { nodes { path } } commits(last: 1) { nodes { commit { ${checksFields} } } } }`).join('\n')} } }`).repository
  for (const entry of entries) {
    const pullRequest = extra[`pull${entry.number}`]
    entry.additions = pullRequest.additions
    entry.deletions = pullRequest.deletions
    entry.reviewDecision = pullRequest.reviewDecision
    entry.area = entry.area || areaOf(pullRequest.files.nodes.map((file) => file.path))
    entry.checks = pullRequest.commits.nodes.length ? checksOf(pullRequest.commits.nodes[0].commit.statusCheckRollup, false) : 'pass'
    const words = entry.title.toLowerCase().replace(/[^a-z0-9 ]/g, '').split(/\s+/).filter(Boolean).slice(0, 3).join(' ')
    const model = entry.additions + entry.deletions > largeChange || entry.teams.length > 1 ? 'fable' : 'opus'
    entry.command = `cd ~/Projects/${name} && claude --model ${model} -n "${authorShortNames[entry.author] || entry.author} - ${words}" "/review ${entry.url}"`
  }
}

const moved = new Set(queue.map((entry) => entry.migratedFrom).filter(Boolean))
fs.writeFileSync(path.join(directory, 'reviews.js'), `window.REVIEWS = ${JSON.stringify({ updated: stamp(new Date()), pulls: details.filter((entry) => !moved.has(entry.url)) }, null, 2)};\n`)

console.log(JSON.stringify(queue.filter((entry) => !moved.has(entry.url)).sort((first, second) => Number(second.needsMe) - Number(first.needsMe)), null, 2))
