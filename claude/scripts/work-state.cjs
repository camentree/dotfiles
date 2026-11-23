const childProcess = require('node:child_process')
const fs = require('node:fs')
const path = require('node:path')
const { reviewers, directory, graphql } = require('./pull-common.cjs')

const owner = 'augusthealth'
const me = 'camentree'
const team = 'move-ins'
const workDirectory = path.join(process.env.HOME, 'Documents/notes/work')
const githubPath = path.join(workDirectory, 'github.json')

const runScript = (name, args) => childProcess.execFileSync(process.execPath, [path.join(__dirname, name), ...args], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 })

const myPulls = JSON.parse(runScript('my-prs.cjs', ['--json'])).pulls
const queue = JSON.parse(runScript('review-queue.cjs', []))
global.window = {}
delete require.cache[path.join(directory, 'reviews.js')]
require(path.join(directory, 'reviews.js'))
const reviewDetails = global.window.REVIEWS.pulls

const extraFields = `author { login } baseRefName headRefName headRefOid mergeable mergeStateStatus isDraft
  commits(last: 1) { nodes { commit { committedDate } } }
  latestReviews(first: 20) { nodes { author { login } state submittedAt } }
  reviewThreads(first: 100) { nodes { isResolved comments(first: 20) { nodes { author { __typename login } createdAt } } } }
  timelineItems(last: 50, itemTypes: [REVIEW_REQUESTED_EVENT]) { nodes { ... on ReviewRequestedEvent { createdAt requestedReviewer { ... on User { login } ... on Team { slug } } } } }`

const wanted = [...myPulls.map((pull) => ({ repository: 'valinor', number: pull.number })), ...reviewDetails.map((entry) => ({ repository: entry.repository, number: entry.number }))]
const extras = {}
for (const repository of [...new Set(wanted.map((entry) => entry.repository))]) {
  const numbers = wanted.filter((entry) => entry.repository === repository).map((entry) => entry.number)
  const result = graphql(`query { repository(owner: "${owner}", name: "${repository}") { ${numbers.map((number) => `pull${number}: pullRequest(number: ${number}) { ${extraFields} }`).join('\n')} } }`).repository
  for (const number of numbers) extras[`${repository}#${number}`] = result[`pull${number}`]
}

const latest = (moments) => moments.filter(Boolean).sort().pop() || null
const earliest = (moments) => moments.filter(Boolean).sort()[0] || null

const threadsOf = (extra) => {
  const open = extra.reviewThreads.nodes.filter((thread) => !thread.isResolved && thread.comments.nodes.length)
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
    lastComment: latest(open.flatMap((thread) => thread.comments.nodes.map((comment) => comment.createdAt)))
  }
}

const requestedAt = (extra, name) => latest(extra.timelineItems.nodes.filter((node) => node.requestedReviewer && (node.requestedReviewer.login || node.requestedReviewer.slug) === name).map((node) => node.createdAt))
const lastReviewOf = (extra) => latest(extra.latestReviews.nodes.filter((review) => review.author && review.author.login !== me).map((review) => review.submittedAt))
const conflictOf = (extra) => extra.mergeable === 'CONFLICTING' || extra.mergeStateStatus === 'DIRTY'

const plural = (count, word) => `${count} ${word}${count === 1 ? '' : 's'}`

const mine = myPulls.map((pull) => {
  const extra = extras[`valinor#${pull.number}`]
  const threads = threadsOf(extra)
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
    reviewCount: extra.latestReviews.nodes.filter((review) => review.author && review.author.login !== me && !review.author.login.endsWith('[bot]')).length,
    reviewDecision: pull.reviewDecision,
    reviewers: pull.needs.map((login) => ({ login, ...pull.reviews[login], requestedAt: requestedAt(extra, login) })),
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
    threads: threadsOf(extra),
    section: entry.section,
    needsMe: Boolean(queued.needsMe),
    why: queued.why || null,
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
const temporaryPath = `${githubPath}.${process.pid}.tmp`
fs.writeFileSync(temporaryPath, `${JSON.stringify(result, null, 2)}\n`)
fs.renameSync(temporaryPath, githubPath)
console.log(`wrote github.json: ${plural(mine.length, 'pull request')} of yours, ${plural(teammates.length, 'teammate pull request')}, ${plural(meetings.length, 'meeting')}`)
