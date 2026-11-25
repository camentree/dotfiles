const childProcess = require('node:child_process')
const fs = require('node:fs')
const os = require('node:os')
const path = require('node:path')

const reviewers = {
  backend: { login: 'jessebutterfield', name: 'Jesse' },
  frontend: { login: 'jkjustjoshing', name: 'Josh' }
}
const generatedPaths = ['backend/protos/typescript/', 'backend/loquat/modules/slick/src/main/scala-tables/']
const doNotMergeLabel = 'DO NOT MERGE'
const doNotMergeCheck = /do not merge/i
const failedConclusions = ['FAILURE', 'TIMED_OUT', 'ACTION_REQUIRED', 'STARTUP_FAILURE']
const checksFields = 'statusCheckRollup { contexts(first: 100) { nodes { __typename ... on CheckRun { name status conclusion } ... on StatusContext { context state } } } }'

const directory = path.join(process.env.HOME, 'Documents/notes/today')
const nixProfile = path.join('/etc/profiles/per-user', os.userInfo().username, 'bin')
const ghEnvironment = { ...process.env, PATH: `${nixProfile}:${process.env.PATH || ''}` }
const usage = { calls: 0, cost: 0, remaining: null }
const splitResponse = (output) => {
  const [head, ...body] = output.split(/\r?\n\r?\n/)
  const headers = Object.fromEntries(head.split(/\r?\n/).slice(1).map((line) => [line.slice(0, line.indexOf(':')).toLowerCase(), line.slice(line.indexOf(':') + 1).trim()]))
  return { headers, body: body.join('\n\n') }
}
const retryMomentOf = (headers) => {
  if (headers['retry-after']) return new Date(Date.now() + Number(headers['retry-after']) * 1000).toISOString()
  if (headers['x-ratelimit-remaining'] === '0' && headers['x-ratelimit-reset']) return new Date(Number(headers['x-ratelimit-reset']) * 1000).toISOString()
  return null
}
const rateLimited = (error) => /rate limit/i.test(`${error.stderr || ''} ${error.stdout || ''}`)
const graphql = (text, variables = []) => {
  usage.calls += 1
  const counted = text.replace(/}\s*$/, ' rateLimit { cost remaining } }')
  let output
  try {
    output = childProcess.execFileSync('gh', ['api', '-i', 'graphql', '-f', `query=${counted}`, ...variables], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, env: ghEnvironment, stdio: ['ignore', 'pipe', 'pipe'] })
  } catch (error) {
    if (!rateLimited(error)) throw new Error((error.stderr || error.message).trim())
    const retryAt = error.stdout ? retryMomentOf(splitResponse(error.stdout).headers) : null
    throw new Error(`gh: GitHub rate limit: ${(error.stderr || '').replace(/^gh:\s*/, '').trim()}${retryAt ? ` retry after ${retryAt}` : ''}`)
  }
  const { data } = JSON.parse(splitResponse(output).body)
  usage.cost += data.rateLimit.cost
  usage.remaining = data.rateLimit.remaining
  return data
}

const plainTitle = (title) => title.replace(/^(\s*\([^)]*\))+\s*/, '').trim()

const topAreas = (paths) => {
  const areas = new Set(paths.map((filePath) => filePath.split('/')[0]).filter((top) => reviewers[top]))
  return areas.size === 2 ? 'both' : [...areas][0]
}
const areaOf = (paths) => topAreas(paths.filter((filePath) => !generatedPaths.some((prefix) => filePath.startsWith(prefix)))) || topAreas(paths) || 'backend'

const checksOf = (rollup, doNotMerge) => {
  const results = ((rollup && rollup.contexts.nodes) || [])
    .filter((check) => !(doNotMerge && doNotMergeCheck.test(check.name || check.context || '')))
    .map((check) => {
      if (check.__typename === 'StatusContext') return check.state === 'SUCCESS' ? 'pass' : ['FAILURE', 'ERROR'].includes(check.state) ? 'fail' : 'pending'
      if (check.status !== 'COMPLETED') return 'pending'
      return failedConclusions.includes(check.conclusion) ? 'fail' : 'pass'
    })
  return results.includes('fail') ? 'fail' : results.includes('pending') ? 'pending' : 'pass'
}

const readMarks = () => {
  try {
    const state = JSON.parse(fs.readFileSync(path.join(directory, 'state.json'), 'utf8'))
    return { asked: {}, snoozed: {}, dismissed: {}, ...(state.marks || {}), ...(state.asked && !(state.marks && state.marks.asked) ? { asked: state.asked } : {}) }
  } catch (error) {
    return { asked: {}, snoozed: {}, dismissed: {} }
  }
}

const migratedCommentPattern = /^\*\*([\w-]+)\*\* wrote on \[?the old pull request/
const lastSpeakerOf = (comment) => {
  if (!comment || !comment.author) return null
  const migrated = migratedCommentPattern.exec(comment.body || '')
  return migrated ? migrated[1] : comment.author.login
}
const threadWaitsOn = (thread, me) => !thread.isResolved && thread.lastComment.nodes.length > 0 && lastSpeakerOf(thread.lastComment.nodes[0]) !== me
const lastCommentField = 'lastComment: comments(last: 1) { nodes { author { login } body } }'

const pad = (number) => String(number).padStart(2, '0')
const stamp = (moment) => `${moment.getFullYear()}-${pad(moment.getMonth() + 1)}-${pad(moment.getDate())} ${pad(moment.getHours())}:${pad(moment.getMinutes())}`

module.exports = { reviewers, doNotMergeLabel, checksFields, directory, graphql, usage, plainTitle, areaOf, checksOf, readMarks, stamp, threadWaitsOn, lastCommentField, lastSpeakerOf }
