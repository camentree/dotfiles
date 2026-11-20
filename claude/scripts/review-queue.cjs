const childProcess = require('node:child_process')

const owner = 'augusthealth'
const repositories = ['valinor', 'august-backend', 'august-frontend', 'Experimental-Tools']
const migratedFromPattern = /Migrated from (https:\/\/github\.com\/augusthealth\/august-(?:backend|frontend)\/pull\/\d+)/
const me = 'camentree'
const team = 'move-ins'
const teammates = ['jessebutterfield', 'jkjustjoshing']
const stateWords = { APPROVED: 'approved', CHANGES_REQUESTED: 'requested changes', COMMENTED: 'commented', DISMISSED: 'approved, since dismissed by a push' }

const fields = `number title url isDraft body
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

const graphql = (text, variables) => JSON.parse(childProcess.execFileSync('gh', ['api', 'graphql', '-f', `query=${text}`, ...variables], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 })).data.repository

const reviewerName = (reviewer) => (reviewer ? reviewer.login || reviewer.slug : null)
const asked = (pullRequest) => [...pullRequest.reviewRequests.nodes, ...pullRequest.timelineItems.nodes].map((node) => reviewerName(node.requestedReviewer)).filter(Boolean)

const open = repositories.map((name) => ({ name, pullRequests: graphql(query, ['-f', `owner=${owner}`, '-f', `name=${name}`]).pullRequests.nodes }))
const openByUrl = new Map(open.flatMap(({ pullRequests }) => pullRequests.map((pullRequest) => [pullRequest.url, pullRequest])))

const movedFrom = (url) => {
  if (!url) return null
  if (openByUrl.has(url)) return openByUrl.get(url)
  const [, name, number] = /augusthealth\/([^/]+)\/pull\/(\d+)/.exec(url)
  return graphql(oneQuery, ['-f', `owner=${owner}`, '-f', `name=${name}`, '-F', `number=${number}`]).pullRequest
}

const queue = []
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
    let needsMe
    let why
    if (mine) {
      const pushedSince = lastCommit && lastCommit > mine.submittedAt
      needsMe = mine.state !== 'APPROVED' && Boolean(pushedSince)
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
  }
}

const moved = new Set(queue.map((entry) => entry.migratedFrom).filter(Boolean))

console.log(JSON.stringify(queue.filter((entry) => !moved.has(entry.url)).sort((first, second) => Number(second.needsMe) - Number(first.needsMe)), null, 2))
