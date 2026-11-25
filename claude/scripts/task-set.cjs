const childProcess = require('node:child_process')
const fs = require('node:fs')
const path = require('node:path')

const tasksDirectory = path.join(process.env.HOME, '.claude/tasks')
const states = ['working', 'blocked', 'ready', 'reviewing', 'done']
const readies = ['review', 'fixes', 'work', 'none']
const kinds = ['mine', 'teammate']
const materialKinds = ['pr', 'difit', 'context', 'proof', 'linear', 'other']
const videoExtensions = ['.mp4', '.mov', '.webm', '.m4v']
const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg']
const usage = `usage: node task-set.cjs [--task <repo>/<branch>] [--title "..."] [--kind ${kinds.join('|')}] [--project "..."] [--pull <url>] [--ticket <url>] [--base <branch>]
  [--state ${states.join('|')}] [--doing "..."] [--session "<name>"] [--session-id <uuid>] [--agent-kind fix|address|review|start] [--ready ${readies.join('|')}]
  [--explanation "..."] [--description-file <path>] [--label <label>]...
  [--decision "<title>" --why "..." [--alternative "..."]] [--finding "<title>" --detail "..." [--reproduced]]
  [--proof <file> --caption "..."] [--proof-clear] [--findings-clear] [--decisions-clear]
  [--context <file> --caption "..."] [--context-clear]
  [--question "<text>" --explanation-q "..." --why-q "..." --option "<label>|<cost>"... [--picture <file>]...] [--question-clear]
  [--material "<${materialKinds.join('|')}>|<label>|<url>"]... [--material-clear] [--tab-group "<name>"]
  [--review-file <path to json>] [--json]`

const fail = (message) => {
  console.error(message ? `${message}\n${usage}` : usage)
  process.exit(1)
}

const git = (args) => childProcess.execFileSync('git', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim()

const valueFlags = ['--task', '--title', '--kind', '--project', '--pull', '--ticket', '--base', '--state', '--doing', '--session', '--session-id', '--agent-kind', '--ready', '--explanation', '--description-file', '--label', '--decision', '--why', '--alternative', '--finding', '--detail', '--proof', '--context', '--caption', '--question', '--explanation-q', '--why-q', '--option', '--picture', '--review-file', '--material', '--tab-group']
const switchFlags = ['--reproduced', '--proof-clear', '--context-clear', '--findings-clear', '--decisions-clear', '--question-clear', '--material-clear', '--json']

const flags = process.argv.slice(2)
const options = { labels: [], decisions: [], findings: [], proofs: [], contexts: [], materials: [], question: null }
let lastDecision = null
let lastFinding = null
let lastMedia = null
for (let index = 0; index < flags.length; index += 1) {
  const flag = flags[index]
  if (switchFlags.includes(flag)) {
    if (flag === '--reproduced') {
      if (!lastFinding) fail('--reproduced needs a --finding before it')
      lastFinding.reproduced = true
    } else options[flag.slice(2)] = true
    continue
  }
  if (!valueFlags.includes(flag) || flags[index + 1] === undefined) fail(`unknown or incomplete flag ${flag}`)
  const value = flags[index + 1]
  index += 1
  if (flag === '--label') options.labels.push(value)
  else if (flag === '--material') {
    const [kind, label, ...url] = value.split('|')
    if (!materialKinds.includes(kind.trim()) || !(label || '').trim() || !/^https?:\/\//.test(url.join('|').trim())) fail(`--material must be "<${materialKinds.join('|')}>|<label>|<http url>", got "${value}"`)
    options.materials.push({ kind: kind.trim(), label: label.trim(), url: url.join('|').trim() })
  } else if (flag === '--decision') {
    lastDecision = { title: value, why: null, alternative: null }
    options.decisions.push(lastDecision)
  } else if (flag === '--why' || flag === '--alternative') {
    if (!lastDecision) fail(`${flag} needs a --decision before it`)
    lastDecision[flag.slice(2)] = value
  } else if (flag === '--finding') {
    lastFinding = { title: value, detail: null, reproduced: false }
    options.findings.push(lastFinding)
  } else if (flag === '--detail') {
    if (!lastFinding) fail('--detail needs a --finding before it')
    lastFinding.detail = value
  } else if (flag === '--proof' || flag === '--context') {
    const extension = path.extname(value).toLowerCase()
    lastMedia = { caption: null, file: value, kind: videoExtensions.includes(extension) ? 'video' : imageExtensions.includes(extension) ? 'image' : 'file' }
    options[flag === '--proof' ? 'proofs' : 'contexts'].push(lastMedia)
  } else if (flag === '--caption') {
    if (!lastMedia) fail('--caption needs a --proof or --context before it')
    lastMedia.caption = value
  } else if (flag === '--question') {
    options.question = { text: value, explanation: null, why: null, options: [], pictures: [], asked: null, answer: null }
  } else if (['--explanation-q', '--why-q', '--option', '--picture'].includes(flag)) {
    if (!options.question) fail(`${flag} needs a --question before it`)
    if (flag === '--explanation-q') options.question.explanation = value
    else if (flag === '--why-q') options.question.why = value
    else if (flag === '--picture') options.question.pictures.push(value)
    else {
      const [label, ...cost] = value.split('|')
      options.question.options.push({ label: label.trim(), cost: cost.join('|').trim() || null })
    }
  } else options[flag.slice(2)] = value
}

if (options.kind && !kinds.includes(options.kind)) fail(`--kind must be one of ${kinds.join(', ')}`)
if (options.state && !states.includes(options.state)) fail(`--state must be one of ${states.join(', ')}`)
if (options.ready && !readies.includes(options.ready)) fail(`--ready must be one of ${readies.join(', ')}`)

let repo
let branch
let worktree = null
if (options.task) {
  const slash = options.task.indexOf('/')
  if (slash < 1 || slash === options.task.length - 1) fail('--task must be <repo>/<branch>')
  repo = options.task.slice(0, slash)
  branch = options.task.slice(slash + 1)
} else {
  try {
    repo = path.basename(git(['remote', 'get-url', 'origin'])).replace(/\.git$/, '')
    branch = git(['branch', '--show-current'])
    worktree = git(['rev-parse', '--show-toplevel'])
  } catch (error) {
    fail('not in a git worktree; pass --task <repo>/<branch>')
  }
  if (!branch) fail('no current branch; pass --task <repo>/<branch>')
}

const taskDirectory = path.join(tasksDirectory, repo, branch)
const taskPath = path.join(taskDirectory, 'task.json')
if (!path.resolve(taskPath).startsWith(tasksDirectory + path.sep)) fail('--task leaves the tasks directory')

const now = new Date().toISOString()
let task
try {
  task = JSON.parse(fs.readFileSync(taskPath, 'utf8'))
} catch (error) {
  task = {
    id: `${repo}/${branch}`,
    title: null,
    kind: 'mine',
    project: null,
    repo,
    branch,
    base: 'master',
    worktree,
    pull: null,
    ticket: null,
    agent: null,
    ready: null,
    explanation: null,
    decisions: [],
    findings: [],
    proof: [],
    context: [],
    question: null,
    description: null,
    labels: [],
    review: null,
    updated: now
  }
}

for (const field of ['title', 'kind', 'project', 'pull', 'ticket', 'base', 'explanation']) if (options[field] !== undefined) task[field] = options[field]
if (worktree && !task.worktree) task.worktree = worktree
if (options.ready) task.ready = options.ready === 'none' ? null : options.ready
if (options['description-file']) task.description = fs.readFileSync(options['description-file'], 'utf8')
for (const label of options.labels) if (!task.labels.includes(label)) task.labels.push(label)
if (options['decisions-clear']) task.decisions = []
if (options['findings-clear']) task.findings = []
if (options['proof-clear']) task.proof = []
task.decisions.push(...options.decisions)
task.findings.push(...options.findings)
task.proof.push(...options.proofs)
if (options['context-clear']) task.context = []
task.context = [...(task.context || []), ...options.contexts]
if (options['review-file']) task.review = JSON.parse(fs.readFileSync(options['review-file'], 'utf8'))
if (options['question-clear']) task.question = null
if (options['material-clear']) task.materials = []
if (options.materials.length) task.materials = [...(task.materials || []).filter((kept) => !options.materials.some((material) => material.url === kept.url)), ...options.materials]
if (options['tab-group'] !== undefined) task.tabGroup = options['tab-group']

const agentFlags = ['state', 'doing', 'ready', 'session', 'session-id', 'agent-kind', 'description-file', 'proof-clear', 'findings-clear', 'decisions-clear', 'question-clear', 'review-file', 'material-clear']
const agentActivity = agentFlags.some((name) => options[name] !== undefined) || options.decisions.length > 0 || options.findings.length > 0 || options.proofs.length > 0 || options.materials.length > 0 || Boolean(options.question)
if (agentActivity) {
  const agent = task.agent || { session: null, sessionId: null, state: null, doing: null, since: null, heartbeat: null }
  if (options.session) agent.session = options.session
  if (options['session-id'] && options['session-id'] !== agent.sessionId) delete agent.kind
  if (options['session-id']) agent.sessionId = options['session-id']
  if (options['agent-kind']) agent.kind = options['agent-kind']
  if (options.doing) agent.doing = options.doing
  if (options.question) {
    task.question = { ...options.question, asked: now }
    options.state = 'blocked'
  }
  if (options.state && options.state !== agent.state) {
    agent.state = options.state
    agent.since = now
  }
  agent.heartbeat = now
  task.agent = agent
  task.updated = now
} else {
  if (task.agent && !task.agent.state && !task.agent.session && !task.agent.sessionId) task.agent = null
  task.described = now
}

fs.mkdirSync(taskDirectory, { recursive: true })
const temporaryPath = `${taskPath}.${process.pid}.tmp`
fs.writeFileSync(temporaryPath, `${JSON.stringify(task, null, 2)}\n`)
fs.renameSync(temporaryPath, taskPath)

if (options.json) console.log(JSON.stringify(task, null, 2))
else console.log(`wrote ${taskPath}`)
