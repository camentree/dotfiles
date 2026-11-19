const childProcess = require('node:child_process')

const owner = 'augusthealth'
const repositories = ['august-backend', 'august-frontend', 'Experimental-Tools']
const me = 'camentree'
const team = 'move-ins'
const teammates = ['jessebutterfield', 'jkjustjoshing']
const stateWords = { APPROVED: 'approved', CHANGES_REQUESTED: 'requested changes', COMMENTED: 'commented', DISMISSED: 'approved, since dismissed by a push' }

const query = `query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    pullRequests(states: OPEN, first: 100, orderBy: { field: UPDATED_AT, direction: DESC }) {
      nodes {
        number title url isDraft
        author { login }
        reviewRequests(first: 15) { nodes { requestedReviewer { __typename ... on User { login } ... on Team { slug } } } }
        latestReviews(first: 20) { nodes { author { login } state submittedAt } }
        commits(last: 1) { nodes { commit { committedDate } } }
        timelineItems(first: 50, itemTypes: [REVIEW_REQUESTED_EVENT]) {
          nodes { ... on ReviewRequestedEvent { requestedReviewer { __typename ... on User { login } ... on Team { slug } } } }
        }
      }
    }
  }
}`

const reviewerName = (reviewer) => (reviewer ? reviewer.login || reviewer.slug : null)

const queue = []
for (const name of repositories) {
  const output = childProcess.execFileSync('gh', ['api', 'graphql', '-f', `query=${query}`, '-f', `owner=${owner}`, '-f', `name=${name}`], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 })
  for (const pullRequest of JSON.parse(output).data.repository.pullRequests.nodes) {
    const author = pullRequest.author ? pullRequest.author.login : ''
    if (pullRequest.isDraft || author === me || author.startsWith('app/') || author.endsWith('[bot]')) continue
    const pending = pullRequest.reviewRequests.nodes.map((node) => reviewerName(node.requestedReviewer)).filter(Boolean)
    const everAsked = new Set([...pending, ...pullRequest.timelineItems.nodes.map((node) => reviewerName(node.requestedReviewer)).filter(Boolean)])
    const reviews = pullRequest.latestReviews.nodes.filter((review) => review.author && review.author.login !== author)
    const mine = reviews.find((review) => review.author.login === me)
    const askedMe = everAsked.has(me)
    const askedTeam = everAsked.has(team)
    if (!askedMe && !askedTeam && !mine) continue
    const lastCommit = pullRequest.commits.nodes.length ? pullRequest.commits.nodes[0].commit.committedDate : null
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
      author,
      asked: [askedMe ? 'you' : null, askedTeam ? team : null].filter(Boolean),
      reviews: reviews.map((review) => `${review.author.login} ${stateWords[review.state] || review.state.toLowerCase()}`),
      needsMe,
      why
    })
  }
}

console.log(JSON.stringify(queue.sort((first, second) => Number(second.needsMe) - Number(first.needsMe)), null, 2))
