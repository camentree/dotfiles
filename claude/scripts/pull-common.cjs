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
const graphql = (text, variables = []) => JSON.parse(childProcess.execFileSync('gh', ['api', 'graphql', '-f', `query=${text}`, ...variables], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, env: ghEnvironment })).data

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

const pad = (number) => String(number).padStart(2, '0')
const stamp = (moment) => `${moment.getFullYear()}-${pad(moment.getMonth() + 1)}-${pad(moment.getDate())} ${pad(moment.getHours())}:${pad(moment.getMinutes())}`

module.exports = { reviewers, doNotMergeLabel, checksFields, directory, graphql, plainTitle, areaOf, checksOf, readMarks, stamp }
