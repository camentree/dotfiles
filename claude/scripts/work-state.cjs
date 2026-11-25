const childProcess = require('node:child_process')
const fs = require('node:fs')
const path = require('node:path')
const { reviewers, graphql, usage, threadWaitsOn, lastCommentField, lastSpeakerOf } = require('./pull-common.cjs')
const { buildPulls, writePulls, migratedFromPattern: myMigratedFromPattern } = require('./my-prs.cjs')
const { repositories, fields: queueFields, migratedFromPattern: queueMigratedFromPattern, watchedPulls, buildQueue, addExtras, writeReviews } = require('./review-queue.cjs')

const owner = 'augusthealth'
const me = 'camentree'
const team = 'move-ins'
const workDirectory = path.join(process.env.HOME, 'Documents/notes/work')
const githubPath = path.join(workDirectory, 'github.json')
const cachePath = path.join(workDirectory, 'github-cache.json')
const staleMilliseconds = 30 * 60 * 1000
const fullScanMilliseconds = 60 * 60 * 1000
const teamsMilliseconds = 24 * 60 * 60 * 1000
const batchSize = 10

const listFields = 'number url state isDraft updatedAt headRefOid author { login }'
const knownFields = `${listFields} mergeable mergeStateStatus
  commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
  pendingReviews: reviews(states: PENDING, first: 5) { totalCount }`

const fullFields = `number url title body isDraft createdAt state updatedAt author { login } baseRefName headRefName headRefOid additions deletions reviewDecision mergeable mergeStateStatus
  files(first: 100) { nodes { path } }
  labels(first: 20) { nodes { name } }
  reviewRequests(first: 15) { nodes { requestedReviewer { __typename ... on User { login } ... on Team { slug } } } }
  commits(last: 1) { nodes { commit { committedDate authoredDate statusCheckRollup { state contexts(first: 100) { nodes { __typename ... on CheckRun { name status conclusion } ... on StatusContext { context state } } } } } } }
  latestReviews(first: 20) { nodes { author { __typename login } state submittedAt } }
  pendingReviews: reviews(states: PENDING, first: 5) { nodes { author { login } } }
  reviewThreads(first: 100) { nodes { isResolved comments(first: 20) { nodes { author { __typename login } createdAt body } } ${lastCommentField} } }
  timelineItems(first: 50, itemTypes: [REVIEW_REQUESTED_EVENT]) { nodes { ... on ReviewRequestedEvent { requestedReviewer { __typename ... on User { login } ... on Team { slug } } } } }
  requestEvents: timelineItems(last: 50, itemTypes: [REVIEW_REQUESTED_EVENT]) { nodes { ... on ReviewRequestedEvent { createdAt requestedReviewer { ... on User { login } ... on Team { slug } } } } }`

const readJson = (file, fallback) => {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'))
  } catch (error) {
    return fallback
  }
}
const writeJson = (file, value) => {
  const temporaryPath = `${file}.${process.pid}.tmp`
  fs.writeFileSync(temporaryPath, `${JSON.stringify(value, null, 2)}\n`)
  fs.renameSync(temporaryPath, file)
}

const pullOf = (url) => {
  const match = /github\.com\/augusthealth\/([^/]+)\/pull\/(\d+)/.exec(url || '')
  return match ? { repository: match[1], number: Number(match[2]) } : null
}
const aliasOf = (repository) => repository.replace(/[^A-Za-z]/g, '')
const byNumberQuery = (pulls, selection) => repositories.map((repository) => {
  const numbers = [...new Set(pulls.filter((pull) => pull.repository === repository).map((pull) => pull.number))]
  return numbers.length ? `${aliasOf(repository)}: repository(owner: "${owner}", name: "${repository}") { ${numbers.map((number) => `pull${number}: pullRequest(number: ${number}) { ${selection} }`).join('\n')} }` : ''
}).join('\n')
const byNumberNodes = (data, pulls) => pulls.map((pull) => data[aliasOf(pull.repository)] && data[aliasOf(pull.repository)][`pull${pull.number}`]).filter(Boolean)
const rollupStateOf = (node) => (node.commits && node.commits.nodes.length && node.commits.nodes[0].commit.statusCheckRollup ? node.commits.nodes[0].commit.statusCheckRollup.state : null)
const fingerprintOf = (node) => JSON.stringify([node.updatedAt, node.headRefOid, node.isDraft, rollupStateOf(node), node.pendingReviews ? node.pendingReviews.totalCount : null])

const cache = readJson(cachePath, { fullScanAt: null, teams: null, pulls: {} })
const startedAt = Date.now()
const fullScan = !cache.fullScanAt || startedAt - Date.parse(cache.fullScanAt) > fullScanMilliseconds
const teamsStale = !cache.teams || startedAt - Date.parse(cache.teams.at) > teamsMilliseconds
const watched = watchedPulls()
const repositoryFilter = repositories.map((repository) => `repo:${owner}/${repository}`).join(' ')
const searches = {
  mine: `is:pr is:open author:${me} repo:${owner}/valinor`,
  requested: `is:pr is:open review-requested:${me} ${repositoryFilter}`,
  teamRequested: `is:pr is:open team-review-requested:${owner}/${team} ${repositoryFilter}`,
  reviewed: `is:pr is:open reviewed-by:${me} ${repositoryFilter}`
}
const known = [...Object.keys(cache.pulls).filter((url) => cache.pulls[url].member), ...watched].map(pullOf).filter((pull) => pull && repositories.includes(pull.repository))
const scanField = (repository, after) => `scan${aliasOf(repository)}: repository(owner: "${owner}", name: "${repository}") { pullRequests(states: OPEN, first: 100${after ? `, after: "${after}"` : ''}) { pageInfo { hasNextPage endCursor } nodes { ${listFields} } } }`

const listing = graphql(`query {
  ${Object.entries(searches).map(([alias, text]) => `${alias}: search(query: "${text}", type: ISSUE, first: 100) { issueCount nodes { ... on PullRequest { ${listFields} } } }`).join('\n')}
  ${byNumberQuery(known, knownFields)}
  ${teamsStale ? `organization(login: "${owner}") { teams(first: 50, userLogins: ["${me}"]) { nodes { slug } } }` : ''}
}`)
for (const alias of Object.keys(searches)) if (listing[alias].issueCount > 100) console.error(`search ${alias} has ${listing[alias].issueCount} results, only 100 read`)
const lights = Object.keys(searches).flatMap((alias) => listing[alias].nodes)
if (fullScan) {
  for (const repository of repositories) {
    let after = null
    do {
      const page = graphql(`query { ${scanField(repository, after)} }`)[`scan${aliasOf(repository)}`].pullRequests
      lights.push(...page.nodes)
      after = page.pageInfo.hasNextPage ? page.pageInfo.endCursor : null
    } while (after)
  }
}
lights.push(...byNumberNodes(listing, known))
const myTeams = teamsStale ? listing.organization.teams.nodes.map((node) => node.slug) : cache.teams.slugs

const lightByUrl = new Map()
for (const light of lights) if (light.number && pullOf(light.url)) lightByUrl.set(light.url, light)
for (const [url, light] of lightByUrl) if (light.state !== 'OPEN') lightByUrl.delete(url)
const myUrls = new Set([...lightByUrl.values()].filter((light) => light.author && light.author.login === me && pullOf(light.url).repository === 'valinor').map((light) => light.url))
const considered = [...lightByUrl.values()].filter((light) => myUrls.has(light.url) || ((!light.author || light.author.login !== me) && (!light.isDraft || watched.has(light.url))))
const needsFetch = (light) => {
  const cached = cache.pulls[light.url]
  if (!cached || cached.fingerprint !== fingerprintOf(light)) return true
  if (!cached.node) return watched.has(light.url) || myUrls.has(light.url)
  return startedAt - Date.parse(cached.fetchedAt) > staleMilliseconds
}
const toFetch = considered.filter(needsFetch).map((light) => pullOf(light.url))
const fetched = new Map()
for (let start = 0; start < toFetch.length; start += batchSize) {
  const batch = toFetch.slice(start, start + batchSize)
  for (const node of byNumberNodes(graphql(`query { ${byNumberQuery(batch, fullFields)} }`), batch)) fetched.set(node.url, node)
}

const sourceUrlOf = (node) => {
  if (myUrls.has(node.url)) {
    const match = myMigratedFromPattern.exec(node.body || '')
    return match ? `https://github.com/${owner}/${match[1]}/pull/${match[2]}` : null
  }
  return (queueMigratedFromPattern.exec(node.body || '') || [])[1] || null
}
const sourceUrls = [...new Set([...fetched.values()].map(sourceUrlOf).filter(Boolean))]
const fetchedSources = new Map()
if (sourceUrls.length) {
  const data = graphql(`query { ${sourceUrls.map((url, index) => `source${index}: repository(owner: "${owner}", name: "${pullOf(url).repository}") { pullRequest(number: ${pullOf(url).number}) { ${queueFields} headRefName } }`).join('\n')} }`)
  sourceUrls.forEach((url, index) => fetchedSources.set(url, data[`source${index}`].pullRequest))
}

const nodes = new Map()
const sources = new Map()
for (const light of considered) {
  const cached = cache.pulls[light.url]
  if (fetched.has(light.url)) {
    const node = fetched.get(light.url)
    nodes.set(light.url, node)
    const sourceUrl = sourceUrlOf(node)
    if (sourceUrl) sources.set(light.url, { url: sourceUrl, node: fetchedSources.get(sourceUrl) })
  } else if (cached && cached.node) {
    nodes.set(light.url, light.mergeable ? { ...cached.node, mergeable: light.mergeable, mergeStateStatus: light.mergeStateStatus } : cached.node)
    if (cached.source) sources.set(light.url, cached.source)
  }
}
const nodeOf = (url) => nodes.get(url)
const sourceNodeOf = (url) => (sources.get(url) || {}).node || null

const myNodes = [...myUrls].map(nodeOf).filter(Boolean)
const originals = Object.fromEntries(myNodes.filter((node) => sources.has(node.url)).map((node) => [`pull${node.number}`, { pullRequest: sourceNodeOf(node.url) }]))
const myResult = buildPulls(myNodes, originals)
writePulls(myResult)
const myPulls = myResult.pulls

const sourceByUrl = new Map([...sources.values()].map((source) => [source.url, nodes.get(source.url) || source.node]))
const open = repositories.map((repository) => ({
  name: repository,
  pullRequests: [...nodes.values()].filter((node) => !myUrls.has(node.url) && pullOf(node.url).repository === repository).sort((first, second) => lightByUrl.get(second.url).updatedAt.localeCompare(lightByUrl.get(first.url).updatedAt))
}))
const built = buildQueue({ open, myTeams, watched, movedFrom: (url) => (url ? sourceByUrl.get(url) || null : null) })
addExtras(built.details, (entry) => nodeOf(entry.url))
const members = new Set([...myUrls, ...built.details.map((entry) => entry.url)])
const { queue, pulls: reviewDetails } = writeReviews(built)

const extras = Object.fromEntries([...nodes.values()].map((node) => [`${pullOf(node.url).repository}#${node.number}`, node]))

const latest = (moments) => moments.filter(Boolean).sort().pop() || null
const earliest = (moments) => moments.filter(Boolean).sort()[0] || null

const openThread = (thread) => !thread.isResolved && thread.comments.nodes.length > 0
const threadToAnswer = (thread) => thread.comments.nodes.length > 0 && threadWaitsOn(thread, me)
const threadsOf = (extra, counted) => {
  const open = extra.reviewThreads.nodes.filter(counted)
  const isBot = (thread) => Boolean(thread.comments.nodes[0].author) && thread.comments.nodes[0].author.__typename === 'Bot'
  const loginsOf = (threads) => [...new Set(threads.flatMap((thread) => thread.comments.nodes.map((comment) => comment.author && comment.author.login)).filter((login) => login && login !== me))]
  const personThreads = open.filter((thread) => !isBot(thread))
  const botThreads = open.filter(isBot)
  return {
    person: personThreads.length,
    bot: botThreads.length,
    people: loginsOf(personThreads),
    bots: loginsOf(botThreads),
    since: earliest(open.map((thread) => thread.comments.nodes[0].createdAt)),
    lastOther: latest(open.flatMap((thread) => thread.comments.nodes.filter((comment) => comment.author && comment.author.login !== me).map((comment) => comment.createdAt))),
    lastComment: latest(open.flatMap((thread) => thread.comments.nodes.map((comment) => comment.createdAt)))
  }
}

const isBotAuthor = (author) => author.__typename === 'Bot' || author.login.endsWith('[bot]')
const reviewedByOf = (extra, author) => {
  const reviewAuthors = extra.latestReviews.nodes.map((review) => review.author)
  const commentAuthors = extra.reviewThreads.nodes.filter(openThread).flatMap((thread) => thread.comments.nodes.map((comment) => comment.author && lastSpeakerOf(comment) !== comment.author.login ? { login: lastSpeakerOf(comment) } : comment.author))
  const others = [...reviewAuthors, ...commentAuthors].filter((who) => who && who.login !== author)
  return { people: [...new Set(others.filter((who) => !isBotAuthor(who)).map((who) => who.login))], bots: [...new Set(others.filter(isBotAuthor).map((who) => who.login))] }
}

const requestedAt = (extra, name) => latest(extra.requestEvents.nodes.filter((node) => node.requestedReviewer && (node.requestedReviewer.login || node.requestedReviewer.slug) === name).map((node) => node.createdAt))
const lastReviewOf = (extra) => latest(extra.latestReviews.nodes.filter((review) => review.author && review.author.login !== me).map((review) => review.submittedAt))
const conflictOf = (extra) => extra.mergeable === 'CONFLICTING' || extra.mergeStateStatus === 'DIRTY'

const plural = (count, word) => `${count} ${word}${count === 1 ? '' : 's'}`

const mine = myPulls.map((pull) => {
  const extra = extras[`valinor#${pull.number}`]
  const threads = threadsOf(extra, threadToAnswer)
  const conflict = conflictOf(extra)
  const approvals = Object.values(pull.reviews).filter((review) => review.status === 'approved').map((review) => review.reviewedAt)
  const waits = []
  if (pull.column === 'blocked') for (const number of pull.waitsOn) waits.push(`waits for #${number}`)
  if (pull.doNotMerge) waits.push('do not merge label')
  if (conflict) waits.push('has a conflict')
  if (pull.checks === 'pending') waits.push('checks running')
  if (pull.checks === 'fail') waits.push('checks failing')
  let stateSince = pull.lastPush
  if (pull.accepted) stateSince = latest(approvals)
  else if (threads.person || threads.bot) stateSince = threads.since
  else if (pull.column === 'needs-me') stateSince = latest([pull.lastPush, lastReviewOf(extra)])
  return {
    repository: 'valinor',
    number: pull.number,
    url: pull.url,
    title: pull.title,
    author: me,
    draft: pull.draft,
    base: extra.baseRefName,
    head: extra.headRefName,
    headSha: extra.headRefOid,
    stackedOn: pull.stack ? pull.stack.below : null,
    stack: pull.stack ? { position: pull.stack.position, size: pull.stack.size, bottom: pull.stack.id } : null,
    createdAt: pull.createdAt,
    additions: pull.additions,
    deletions: pull.deletions,
    lines: pull.size,
    area: pull.area,
    tickets: pull.tickets,
    checks: pull.checks,
    reviewCount: extra.latestReviews.nodes.filter((review) => review.author && review.author.login !== me && !isBotAuthor(review.author)).length,
    reviewDecision: pull.reviewDecision,
    reviewedBy: reviewedByOf(extra, me),
    labels: pull.labels,
    reviewers: pull.needs.map((login) => ({ login, ...pull.reviews[login], requestedAt: requestedAt(extra, login) })),
    teamsPending: pull.requestedTeams,
    threads,
    column: pull.column,
    depth: pull.depth,
    waitsOn: pull.waitsOn,
    notes: pull.notes,
    mergeable: extra.mergeable,
    mergeState: extra.mergeStateStatus,
    conflict,
    canMerge: pull.column === 'accepted' && !waits.length,
    waits: waits.length ? waits.join(', ') : null,
    lastPush: pull.lastPush,
    lastReview: lastReviewOf(extra),
    stateSince
  }
})

const queueByUrl = new Map(queue.map((entry) => [entry.url, entry]))
const headsByRepository = new Map()
for (const entry of reviewDetails) {
  const extra = extras[`${entry.repository}#${entry.number}`]
  headsByRepository.set(`${entry.repository}:${extra.headRefName}`, entry.number)
}
for (const pull of mine) headsByRepository.set(`valinor:${pull.head}`, pull.number)

const teammates = reviewDetails.map((entry) => {
  const extra = extras[`${entry.repository}#${entry.number}`]
  const queued = queueByUrl.get(entry.url) || {}
  const lastPush = extra.commits.nodes.length ? extra.commits.nodes[0].commit.committedDate : null
  const myReview = extra.latestReviews.nodes.find((review) => review.author && review.author.login === me)
  const asked = latest([requestedAt(extra, me), requestedAt(extra, team)])
  const authorReplies = extra.reviewThreads.nodes.flatMap((thread) => thread.comments.nodes.filter((comment) => comment.author && comment.author.login === entry.author).map((comment) => comment.createdAt))
  const authorActivity = latest([lastPush, ...authorReplies, requestedAt(extra, me)])
  return {
    repository: entry.repository,
    number: entry.number,
    url: entry.url,
    title: entry.title,
    author: entry.author,
    draft: entry.draft,
    base: extra.baseRefName,
    head: extra.headRefName,
    headSha: extra.headRefOid,
    stackedOn: headsByRepository.get(`${entry.repository}:${extra.baseRefName}`) || null,
    createdAt: entry.createdAt,
    additions: entry.additions,
    deletions: entry.deletions,
    lines: entry.additions + entry.deletions,
    area: entry.area,
    checks: entry.checks,
    reviewCount: entry.reviewCount,
    reviewDecision: entry.reviewDecision,
    reviews: extra.latestReviews.nodes.filter((review) => review.author).map((review) => ({ login: review.author.login, state: review.state, submittedAt: review.submittedAt })),
    threads: threadsOf(extra, openThread),
    reviewedBy: reviewedByOf(extra, entry.author),
    section: entry.section,
    needsMe: Boolean(entry.needsMe),
    why: entry.why || queued.why || null,
    reason: entry.reason,
    requestedMe: Boolean(entry.requestedMe),
    teamsPending: entry.teamsPending || [],
    othersPending: entry.othersPending || [],
    labels: entry.labels || [],
    myReview: myReview ? { state: myReview.state, at: myReview.submittedAt } : entry.myReview || null,
    authorActivity,
    respondedSinceReview: Boolean(myReview) && Boolean(authorActivity) && authorActivity > myReview.submittedAt,
    pendingReview: Boolean(entry.pendingReview),
    watched: Boolean(entry.watched),
    askedAt: asked,
    mergeable: extra.mergeable,
    mergeState: extra.mergeStateStatus,
    conflict: conflictOf(extra),
    lastPush,
    lastReview: lastReviewOf(extra),
    stateSince: entry.section === 're-review' ? lastPush : myReview ? myReview.submittedAt : asked || entry.createdAt
  }
})

const meetingOf = (line) => {
  const [start, end, attendance, calendar, ...title] = line.split(' | ')
  return { start, end, declined: attendance === 'declined', calendar, title: title.join(' | ').trim() }
}
let meetings = []
try {
  meetings = childProcess.execFileSync('swift', [path.join(__dirname, 'calendar-day.swift')], { encoding: 'utf8' }).split('\n').filter(Boolean).map(meetingOf).filter((meeting) => meeting.start !== 'all-day' && !meeting.declined)
} catch (error) {
  console.error(`calendar failed: ${error.message}`)
}

const result = { updated: new Date().toISOString(), reviewers, mine, teammates, meetings }
fs.mkdirSync(workDirectory, { recursive: true })
writeJson(githubPath, result)

const fetchedAt = new Date(startedAt).toISOString()
const pulls = fullScan ? {} : Object.fromEntries(Object.entries(cache.pulls).filter(([url, cached]) => !cached.node && !watched.has(url)))
for (const light of lightByUrl.values()) {
  const url = light.url
  const cached = cache.pulls[url]
  if (fetched.has(url) && members.has(url)) pulls[url] = { fingerprint: fingerprintOf(light), fetchedAt, member: true, node: fetched.get(url), source: sources.get(url) || null }
  else if (nodes.has(url) && members.has(url)) pulls[url] = cached
  else pulls[url] = { fingerprint: fingerprintOf(light), member: false }
}
writeJson(cachePath, { fullScanAt: fullScan ? fetchedAt : cache.fullScanAt, teams: teamsStale ? { at: fetchedAt, slugs: myTeams } : cache.teams, pulls })

console.log(`github: ${plural(usage.calls, 'call')}, cost ${usage.cost}, remaining ${usage.remaining}; ${fetched.size} fetched, ${nodes.size - fetched.size} reused${fullScan ? ', full scan' : ''}`)
console.log(`wrote github.json: ${plural(mine.length, 'pull request')} of yours, ${plural(teammates.length, 'teammate pull request')}, ${plural(meetings.length, 'meeting')}`)
