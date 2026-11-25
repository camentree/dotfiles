const childProcess = require('node:child_process')
const crypto = require('node:crypto')
const fs = require('node:fs')
const http = require('node:http')
const os = require('node:os')
const path = require('node:path')

const home = process.env.HOME
const port = Number(process.env.WORK_PORT || 4990)
const dryRun = process.env.WORK_DRY_RUN === '1'
const pageDirectory = path.join(home, '.claude/skills/assistant/page')
const tasksDirectory = path.join(home, '.claude/tasks')
const notesDirectory = path.join(home, 'Documents/notes')
const workDirectory = path.join(notesDirectory, 'work')
const backlogPath = path.join(notesDirectory, 'today/backlog.js')
const githubPath = path.join(workDirectory, 'github.json')
const minePath = path.join(workDirectory, 'mine.json')
const projectsPath = path.join(workDirectory, 'projects.json')
const logPath = path.join(workDirectory, 'log.jsonl')
const logImagesDirectory = path.join(workDirectory, 'log-images')
const outboxPath = path.join(workDirectory, 'outbox.jsonl')
const assistantLockPath = path.join(workDirectory, 'assistant.lock')
const answersPath = path.join(workDirectory, 'answers.jsonl')
const configPath = path.join(workDirectory, 'config.json')
const syncsPath = path.join(workDirectory, 'syncs.jsonl')
const placementPath = path.join(workDirectory, 'placement.json')
const departedPath = path.join(workDirectory, 'departed.json')
const movesPath = path.join(workDirectory, 'moves.jsonl')
const taskSetScript = path.join(__dirname, 'task-set.cjs')
const workStateScript = path.join(__dirname, 'work-state.cjs')
const nixProfile = path.join('/etc/profiles/per-user', os.userInfo().username, 'bin')
const childEnvironment = { ...process.env, PATH: `${nixProfile}:${process.env.PATH || ''}` }

const me = 'camentree'
const owner = 'augusthealth'
const names = { camentree: 'you', jessebutterfield: 'Jesse', jkjustjoshing: 'Josh', naomigelfand: 'Naomi', ytolstyk: 'Yuri' }
const sizeWords = { 'x-small': 'under an hour', small: 'about an hour', medium: 'a couple of hours', large: 'a day', 'x-large': 'several days' }
const sectionNames = ['Questions', 'Merge', 'Review', 'PRs', 'Ask']
const renamedSections = { Answer: 'Questions', Respond: 'PRs', Address: 'PRs', Solicit: 'Ask' }
const materialKinds = ['pr', 'difit', 'context', 'proof', 'linear', 'other']
const safariScript = path.join(__dirname, 'safari-tab-group.applescript')
const renamedGroups = { 'Waiting for me': 'Waiting for Me' }
const assistantTaskId = 'notes/assistant'
const buttonOrder = ['merge', 'queue', 'review', 'block', 'requeue', 'dismiss']
const skippedStreams = ['Reviews', 'Tooling']
const firstHour = 8
const lastHour = 18
const refreshMilliseconds = 2 * 60 * 1000
const idleRefreshMilliseconds = 10 * 60 * 1000
const watchedMilliseconds = 10 * 60 * 1000
const firstPauseMinutes = 10
const longestPauseMinutes = 60
const syncTimeoutMilliseconds = 5 * 60 * 1000
const outboxMilliseconds = 30 * 1000
const staleMilliseconds = 20 * 60 * 1000
const hourMilliseconds = 60 * 60 * 1000
const contentTypes = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8', '.md': 'text/plain; charset=utf-8', '.txt': 'text/plain; charset=utf-8', '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.webp': 'image/webp', '.ico': 'image/x-icon', '.mp4': 'video/mp4', '.m4v': 'video/mp4', '.mov': 'video/quicktime', '.webm': 'video/webm', '.pdf': 'application/pdf' }

const readJson = (file, fallback) => {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'))
  } catch (error) {
    return fallback
  }
}
const writeJson = (file, value) => {
  fs.mkdirSync(path.dirname(file), { recursive: true })
  fs.writeFileSync(`${file}.tmp`, `${JSON.stringify(value, null, 2)}\n`)
  fs.renameSync(`${file}.tmp`, file)
}
const readLines = (file) => {
  try {
    return fs.readFileSync(file, 'utf8').split('\n').filter(Boolean).map((line) => JSON.parse(line))
  } catch (error) {
    return []
  }
}
const writeLines = (file, values) => {
  fs.mkdirSync(path.dirname(file), { recursive: true })
  fs.writeFileSync(`${file}.tmp`, values.map((value) => `${JSON.stringify(value)}\n`).join(''))
  fs.renameSync(`${file}.tmp`, file)
}
const appendLine = (file, value) => {
  fs.mkdirSync(path.dirname(file), { recursive: true })
  fs.appendFileSync(file, `${JSON.stringify(value)}\n`)
}

const pad = (number) => String(number).padStart(2, '0')
const today = () => {
  const now = new Date()
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`
}
const isToday = (moment) => {
  const date = new Date(moment)
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` === today()
}
const ago = (moment) => {
  const minutes = Math.max(1, Math.round((Date.now() - Date.parse(moment)) / 60000))
  if (minutes < 60) return `${minutes} min`
  if (minutes < 24 * 60) return `${Math.round(minutes / 60)}h`
  return `${Math.round(minutes / (24 * 60))}d`
}
const daysSince = (moment) => (Date.now() - Date.parse(moment)) / (24 * hourMilliseconds)
const plural = (count, word) => `${count} ${word}${count === 1 ? '' : 's'}`
const nameOf = (login) => names[login] || login
const loginOf = (name) => Object.keys(names).find((login) => names[login] === name) || name
const ticketIdOf = (url) => ((url || '').match(/\b(?:MOV|INT|BILL)-\d+\b/i) || [''])[0].toUpperCase() || null
const clockOf = (time) => {
  const [hours, minutes] = time.split(':').map(Number)
  return `${hours % 12 || 12}:${pad(minutes)} ${hours < 12 ? 'am' : 'pm'}`
}

const readConfig = () => ({ autostart: false, maxAutoAgents: 3, assistant: true, ...readJson(configPath, {}) })
const emptyMine = () => ({ ticks: {}, unticked: {}, completed: {}, comments: {}, flow: {}, blocks: {}, checkFailed: {}, day: { date: today(), hours: {} }, asked: {}, snoozed: {}, dismissed: {}, order: {}, trackers: { water: [], stood: [] }, assistant: null, autostarted: {} })
const readMine = () => ({ ...emptyMine(), ...readJson(minePath, {}) })
const updateMine = (change) => {
  const mine = readMine()
  const result = change(mine)
  writeJson(minePath, mine)
  return result
}

const seedProjects = () => {
  global.window = {}
  delete require.cache[backlogPath]
  require(backlogPath)
  const now = new Date().toISOString()
  const projects = []
  const tasks = {}
  let nextTask = 1
  for (const stream of global.window.BACKLOG.streams.filter((candidate) => !skippedStreams.includes(candidate.name))) {
    const project = { name: stream.name, done: stream.done || 0, total: stream.total || 0, due: stream.target || null, pulls: [], tickets: [], tasks: [] }
    for (const item of stream.groups.flatMap((group) => group.items)) {
      const links = item.links || []
      const pullLink = links.find((link) => /github\.com\/[^/]+\/[^/]+\/pull\/\d+/.test(link.url))
      const ticketLink = links.find((link) => ticketIdOf(link.url))
      const tickets = links.map((link) => ticketIdOf(link.url)).filter(Boolean)
      project.tickets.push(...tickets.filter((ticket) => !project.tickets.includes(ticket)))
      if (pullLink) {
        project.pulls.push(pullLink.url)
        continue
      }
      const id = `task:${nextTask}`
      nextTask += 1
      tasks[id] = { id, title: item.text, project: stream.name, size: item.size || null, ticket: ticketLink ? ticketLink.url : null, done: false, added: now, agent: null }
      project.tasks.push(id)
    }
    projects.push(project)
  }
  projects.push({ name: 'Misc', done: 0, total: 0, due: null, pulls: [], tickets: [], tasks: [] })
  return { seeded: now, nextTask, projects, tasks }
}
const readProjects = () => {
  if (!fs.existsSync(projectsPath)) writeJson(projectsPath, seedProjects())
  return readJson(projectsPath, { nextTask: 1, projects: [], tasks: {} })
}
const updateProjects = (change) => {
  const projects = readProjects()
  const result = change(projects)
  writeJson(projectsPath, projects)
  return result
}

const readTasks = () => {
  const found = []
  const walk = (directory, depth) => {
    let entries
    try {
      entries = fs.readdirSync(directory, { withFileTypes: true })
    } catch (error) {
      return
    }
    for (const entry of entries) {
      const full = path.join(directory, entry.name)
      if (entry.isDirectory() && depth < 6) walk(full, depth + 1)
      else if (entry.name === 'task.json') {
        const task = readJson(full, null)
        if (task && task.repo && task.branch) found.push(task)
      }
    }
  }
  walk(tasksDirectory, 0)
  return found
}
const taskPathOf = (task) => path.join(tasksDirectory, task.repo, task.branch, 'task.json')

let agentsList = []
let agentsKnown = false
const runClaude = (args, cwd) => {
  if (dryRun && args[0] !== 'agents') {
    if (!fs.existsSync(cwd)) return Promise.resolve({ code: -1, output: 'spawn /bin/zsh ENOENT' })
    console.log(`dry run in ${cwd}: claude ${JSON.stringify(args)}`)
    const shortId = Math.random().toString(16).slice(2, 10)
    return Promise.resolve({ code: 0, output: `backgrounded · ${shortId} · dry run` })
  }
  return new Promise((resolve) => {
    const child = childProcess.spawn('/bin/zsh', ['-lic', 'claude "$@"', 'claude', ...args], { cwd, env: childEnvironment, stdio: ['ignore', 'pipe', 'pipe'] })
    let output = ''
    child.stdout.on('data', (chunk) => (output += chunk))
    child.stderr.on('data', (chunk) => (output += chunk))
    child.on('error', (error) => resolve({ code: -1, output: error.message }))
    child.on('close', (code) => resolve({ code, output }))
  })
}
const dryRunAgentsPath = path.join(workDirectory, 'dry-run-agents.json')
const listAgents = async () => {
  const { code, output } = dryRun && fs.existsSync(dryRunAgentsPath) ? { code: 0, output: fs.readFileSync(dryRunAgentsPath, 'utf8') } : await runClaude(['agents', '--json'], home)
  const start = output.indexOf('[')
  const end = output.lastIndexOf(']')
  if (code !== 0 || start < 0 || end < start) return null
  try {
    agentsList = JSON.parse(output.slice(start, end + 1))
    agentsKnown = true
    return agentsList
  } catch (error) {
    return null
  }
}
const wait = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds))

const assistantCompaction = ['--autocompact', '300000', '--settings', '{"autoCompactEnabled":true}']
const startSession = async ({ cwd, model, name, prompt, addDirectories, flags }) => {
  const extraDirectories = (addDirectories || []).flatMap((directory) => ['--add-dir', directory])
  const extraFlags = flags || []
  const withDirectories = await runClaude(['--bg', '--permission-mode', 'auto', '--model', model, ...extraFlags, ...extraDirectories, '-n', name, prompt], cwd)
  const untrusted = extraDirectories.length > 0 && /Added folder not trusted/.test(withDirectories.output)
  const { output } = untrusted ? await runClaude(['--bg', '--permission-mode', 'auto', '--model', model, ...extraFlags, '-n', name, prompt], cwd) : withDirectories
  const match = /backgrounded · ([0-9a-f]+)/.exec(output)
  if (!match) throw new Error(`session did not start: ${output.trim().slice(-300)}`)
  if (dryRun) return { shortId: match[1], sessionId: `dry-${match[1]}` }
  const list = (await listAgents()) || []
  const listed = list.find((agent) => agent.id === match[1])
  return { shortId: match[1], sessionId: listed ? listed.sessionId : match[1] }
}

const recordedDirectoryOf = (sessionId) => {
  const projects = path.join(home, '.claude/projects')
  for (const project of fs.existsSync(projects) ? fs.readdirSync(projects) : []) {
    const transcript = path.join(projects, project, `${sessionId}.jsonl`)
    if (!fs.existsSync(transcript)) continue
    const handle = fs.openSync(transcript, 'r')
    const buffer = Buffer.alloc(65536)
    const length = fs.readSync(handle, buffer, 0, buffer.length, 0)
    fs.closeSync(handle)
    const match = /"cwd":"([^"]+)"/.exec(buffer.toString('utf8', 0, length))
    if (match && fs.existsSync(match[1])) return match[1]
  }
  return null
}
const deliveryDirectoryOf = (sessionId, running, cwd) => {
  if (running && fs.existsSync(running.cwd)) return running.cwd
  if (cwd && fs.existsSync(cwd)) return cwd
  const directory = recordedDirectoryOf(sessionId) || home
  console.log(`deliver: ${cwd} does not exist, resuming ${sessionId} in ${directory}`)
  return directory
}

const attachedTo = (running) => {
  try {
    const commands = childProcess.execFileSync('/bin/ps', ['-axo', 'command'], { encoding: 'utf8' }).split('\n')
    const targets = commands.map((command) => /(?:^|\/)claude attach (.+)$/.exec(command.trim())).filter(Boolean).map((match) => match[1].replace(/^["']|["']$/g, ''))
    return targets.some((target) => target === running.id || target === running.sessionId || (Boolean(running.name) && running.name.includes(target)))
  } catch (error) {
    return false
  }
}

const acknowledged = new Map()
const queueMessage = ({ sessionId, text, cwd, id, at }) => {
  if (acknowledged.has(id)) return
  appendLine(outboxPath, { id: id || crypto.randomUUID(), sessionId, text, cwd, at: at || new Date().toISOString() })
}
const deliveryReply = (delivery, messageId) => ({ status: 200, delivery, ...(/queued/.test(delivery) ? { queued: messageId } : {}) })

const deliver = async ({ sessionId, text, cwd, id, at }) => {
  const queued = readLines(outboxPath).some((entry) => entry.sessionId === sessionId)
  const list = (await listAgents()) || []
  const running = list.find((agent) => agent.sessionId === sessionId)
  const assistant = readMine().assistant
  const isAssistant = Boolean(assistant) && assistant.sessionId === sessionId
  if (running && running.kind === 'background' && running.status === 'busy' && !isAssistant && readConfig().assistant) {
    const relayed = await tellAssistant(`[relay ${running.name}] ${text}`, id)
    return /^queued/.test(relayed) ? `relayed through the assistant, ${relayed}` : 'relayed through the assistant'
  }
  if (queued || (running && (running.status === 'busy' || running.kind !== 'background'))) {
    queueMessage({ sessionId, text, cwd, id, at })
    if (running && running.kind !== 'background') return 'queued for its terminal session'
    return running && attachedTo(running) ? 'queued until its terminal tab closes' : 'queued'
  }
  if (running && attachedTo(running)) {
    if (!isAssistant && readConfig().assistant) {
      const relayed = await tellAssistant(`[relay ${running.name}] ${text}`, id)
      return /^queued/.test(relayed) ? `relayed through the assistant, ${relayed}` : 'relayed through the assistant'
    }
    queueMessage({ sessionId, text, cwd, id, at })
    return 'queued until its terminal tab closes'
  }
  const directory = deliveryDirectoryOf(sessionId, running, cwd)
  if (isAssistant) lockAssistant('resuming it with a message')
  try {
    if (running) {
      await runClaude(['stop', running.id], directory)
      await wait(1500)
    }
    const { code, output } = await runClaude(['--bg', '--resume', sessionId, ...(isAssistant ? assistantCompaction : []), text], directory)
    if (code !== 0 || !/backgrounded/.test(output) || /started a copy/.test(output)) throw new Error(`delivery to ${sessionId} in ${directory} failed: ${output.trim().slice(-300)}`)
  } finally {
    if (isAssistant) unlockAssistant()
  }
  return 'delivered'
}

let draining = false
const drainOutbox = async () => {
  if (draining || !readLines(outboxPath).length) return
  draining = true
  try {
    const entries = readLines(outboxPath)
    fs.writeFileSync(outboxPath, '')
    for (const entry of entries) {
      if (acknowledged.has(entry.id)) continue
      try {
        const assistant = readMine().assistant
        await (assistant && assistant.sessionId === entry.sessionId ? withAssistant(() => deliver(entry)) : deliver(entry))
      } catch (error) {
        console.log(`outbox: ${error.message}`)
        appendLine(outboxPath, entry)
      }
    }
  } finally {
    draining = false
  }
}

const listedAgentOf = (agent) => {
  if (!agent) return null
  const byId = agent.sessionId && agentsList.find((candidate) => candidate.sessionId === agent.sessionId)
  if (byId) return byId
  const byName = agentsList.filter((candidate) => agent.session && candidate.name === agent.session).sort((first, second) => second.startedAt - first.startedAt)
  return byName[0] || null
}
const sessionIdOf = (agent) => {
  const listed = listedAgentOf(agent)
  return listed ? listed.sessionId : (agent && agent.sessionId) || null
}

const proofUrl = (task, file) => `/files/${[task.repo, ...task.branch.split('/'), ...file.split('/')].map(encodeURIComponent).join('/')}`
const agentOf = (task) => {
  if (!task || !task.agent || !(task.agent.state || task.agent.sessionId || task.agent.session)) return null
  const listedAgent = listedAgentOf(task.agent)
  const listed = Boolean(listedAgent)
  const stale = !task.agent.heartbeat || Date.now() - Date.parse(task.agent.heartbeat) > staleMilliseconds
  const waitingForApproval = Boolean(listedAgent) && listedAgent.status === 'waiting'
  const quietAndIdle = stale && !(listedAgent && listedAgent.status === 'busy')
  const state = waitingForApproval || (task.agent.state === 'working' && (quietAndIdle || (agentsKnown && !listed))) ? 'stopped' : task.agent.state
  return { state, doing: waitingForApproval ? 'needs an approval in its terminal' : task.agent.doing, kind: task.agent.kind || null, since: task.agent.since, heartbeat: task.agent.heartbeat, session: task.agent.session, sessionId: task.agent.sessionId }
}
const taskFields = (task, id, pullUrl) => ({
  explanation: task ? task.explanation : null,
  decisions: task ? task.decisions || [] : [],
  findings: task ? task.findings || [] : [],
  proof: task ? (task.proof || []).map((item) => ({ caption: item.caption, url: proofUrl(task, item.file), kind: item.kind })) : [],
  context: task ? (task.context || []).map((item) => ({ caption: item.caption, url: proofUrl(task, item.file), kind: item.kind })) : [],
  question: task && task.question ? { ...task.question, pictures: (task.question.pictures || []).map((file) => proofUrl(task, file)), received: Boolean(task.question.answer) && Boolean(task.agent && task.agent.heartbeat) && Date.parse(task.agent.heartbeat) > Date.parse(task.question.answer.at) } : null,
  description: task ? task.description : null,
  links: task && task.review ? (task.review.tabs || []).filter((tab) => /^https?:/.test(tab.url)).map((tab) => ({ label: tab.label.replace(/[()]/g, ''), url: tab.url })) : [],
  difitLabels: task && task.review && task.review.difit ? [].concat(task.review.difit).map((entry) => entry.label || null) : [],
  materials: materialsOf(task, id, pullUrl),
  tabGroup: (task && task.tabGroup) || null
})
const tabKinds = { pr: 'pr', difit: 'difit', context: 'context', proof: 'proof', linear: 'linear' }
const materialsOf = (task, id, pullUrl) => {
  if (!task) return []
  if (task.materials) return task.materials
  const stillPrepared = Boolean(task.ready) || Boolean(task.agent && ['ready', 'reviewing'].includes(task.agent.state))
  return stillPrepared ? derivedMaterials(task, id, pullUrl) : []
}
const derivedMaterials = (task, id, pullUrl) => {
  const wrapperUrl = (difitPort) => `http://localhost:${port}/review.html?id=${encodeURIComponent(id)}&port=${difitPort}`
  const fromTabs = ((task.review && task.review.tabs) || []).filter((tab) => /^https?:/.test(tab.url)).map((tab) => {
    const word = ((tab.label || '').match(/\(([^)]+)\)/) || ['', ''])[1].toLowerCase()
    const kind = tabKinds[word.split(' ')[0]] || 'other'
    return { kind, label: (tab.label || '').replace(/[()]/g, '') || tab.url, url: kind === 'difit' ? wrapperUrl(new URL(tab.url).port) : tab.url }
  })
  const fromDifit = [].concat((task.review && task.review.difit) || []).filter((entry) => entry.port || entry.url).map((entry) => ({ kind: 'difit', label: entry.label ? `difit ${entry.label}` : 'difit', url: wrapperUrl(entry.port || new URL(entry.url).port) }))
  const pull = task.pull || (pullUrl && /\/pull\/\d+/.test(pullUrl) ? pullUrl : null)
  const fromPull = pull ? [{ kind: 'pr', label: 'pr', url: pull }] : []
  const proofPages = (task.proof || []).filter((item) => item.kind === 'page').map((item) => item.file)
  const proofIndex = task.repo && task.branch && fs.existsSync(path.join(tasksDirectory, task.repo, task.branch, 'proof/index.html')) ? ['proof/index.html'] : []
  const fromProof = [...new Set([...proofPages, ...proofIndex])].map((file) => ({ kind: 'proof', label: 'proof', url: `http://localhost:${port}${proofUrl(task, file)}` }))
  const seen = new Set()
  return [...fromTabs, ...fromDifit, ...fromPull, ...fromProof].filter((material) => {
    if (seen.has(material.url)) return false
    seen.add(material.url)
    return true
  })
}
const blankCard = { tags: [], who: 'you', lines: null, checks: 'none', standing: null, waits: null, checked: false, agent: null, primary: null, buttons: [], possible: [], reviewer: null, asked: null, size: null, project: null, stackOrder: null, greptileReviews: null, teammateReviews: null, materials: [], tabGroup: null }
const botReviewer = (pull) => pull.reviewedBy && pull.reviewedBy.bots.length && pull.reviewedBy.bots.every((login) => login.startsWith('greptile')) ? 'greptile' : 'bots'
const pullCard = (pull, task) => ({
  ...blankCard,
  id: `${pull.repository}#${pull.number}`,
  title: pull.title,
  url: pull.url,
  tags: pull.draft ? ['draft'] : [],
  ref: `#${pull.number} → ${pull.stackedOn ? `#${pull.stackedOn}` : pull.base}`,
  who: nameOf(pull.author),
  opened: pull.createdAt,
  lines: pull.lines,
  checks: pull.checks,
  greptileReviews: pull.reviewedBy ? pull.reviewedBy.bots.filter((login) => login.startsWith('greptile')).length : 0,
  teammateReviews: pull.reviewedBy ? pull.reviewedBy.people.filter((login) => login !== me && login !== pull.author).length : 0,
  stackOrder: pull.stack ? `${pull.stack.position}/${pull.stack.size}` : null,
  agent: agentOf(task),
  ...taskFields(task, `${pull.repository}#${pull.number}`, pull.url),
  project: (task && task.project) || null
})
const taskCard = (task) => ({
  ...blankCard,
  id: task.id || `${task.repo}/${task.branch}`,
  title: task.title || task.branch,
  url: task.pull || task.ticket || null,
  ref: `${ticketIdOf(task.ticket) || task.branch} → ${task.base || 'master'}`,
  opened: (task.agent && task.agent.since) || task.updated,
  agent: agentOf(task),
  project: task.project || null,
  ...taskFields(task, task.id || `${task.repo}/${task.branch}`, task.pull)
})
const byHandCard = (item) => {
  const listed = listedAgentOf(item.agent)
  return {
    ...blankCard,
    id: item.id,
    title: item.title,
    url: item.ticket,
    ref: ticketIdOf(item.ticket) || '',
    opened: item.added,
    agent: listed ? { state: 'working', doing: 'started', kind: item.agent.kind || null, since: item.agent.since, session: item.agent.session, sessionId: item.agent.sessionId } : null,
    size: sizeWords[item.size] || item.size,
    project: item.project,
    ...taskFields(null),
    explanation: item.explanation || null,
    context: (item.context || []).map((entry) => ({ caption: entry.caption, url: proofUrl({ repo: 'by-hand', branch: item.id.replace(':', '-') }, entry.file), kind: entry.kind }))
  }
}

const answerStanding = (card, fallback) => {
  if (card.question && !card.question.answer) return `asked you ${ago(card.question.asked)} ago`
  if (card.question && !card.question.received) return `you answered ${ago(card.question.answer.at)} ago, not picked up yet`
  return `stopped ${ago(card.agent.since || fallback)} ago`
}
const needsAnswer = (card) => Boolean(card.question && !(card.question.answer && card.question.received)) || Boolean(card.agent && card.agent.state === 'stopped')
const withoutAgent = (card) => !card.agent || card.agent.state === 'done'
const summoningLabels = ['design-system']
const askReviewerOf = (pull, marks) => {
  if ((pull.labels || []).some((label) => summoningLabels.includes(label))) return null
  const waiting = pull.reviewers.filter((reviewer) => reviewer.status === 'ask').map((reviewer) => ({ login: reviewer.login, asked: marks[reviewer.login] || reviewer.asked || null }))
  return waiting.find((reviewer) => !reviewer.asked) || waiting[0] || null
}
const respondStanding = (pull) => {
  const others = pull.threads.people.filter((login) => login !== me).map(nameOf)
  if (pull.threads.person) return `${plural(pull.threads.person, 'thread')}${others.length ? ` from ${others.join(' and ')}` : ''}, ${ago(pull.threads.since)}`
  if (pull.threads.bot) return `${plural(pull.threads.bot, 'thread')} from ${botReviewer(pull) === 'greptile' ? 'greptile' : 'the bot'}, ${ago(pull.threads.since)}`
  if (pull.checks === 'fail') return `checks failing, ${ago(pull.lastPush)}`
  return `${pull.notes[0] || 'needs you'}, ${ago(pull.stateSince || pull.lastPush)}`
}

const groupNames = {
  Questions: [''],
  Merge: ['', 'Blocked', 'Complete'],
  Review: ['', 'Queued', 'Backlog', 'Blocked', 'Complete'],
  PRs: ['', 'Queued', 'Waiting for Me', 'Waiting for Review', 'Blocked', 'Complete'],
  Ask: ['']
}
const mergeKeys = ['Merge:', 'Merge:Blocked', 'PRs:', 'PRs:Queued', 'PRs:Waiting for Me', 'PRs:Waiting for Review', 'Ask:']
const unreviewedLimit = 3
const solicitedOf = (pulls, askedOf) => {
  const open = pulls.filter((pull) => !pull.draft)
  const stacks = new Map()
  for (const pull of open) {
    const key = pull.stack ? `stack:${pull.stack.bottom}` : `pull:${pull.number}`
    stacks.set(key, [...(stacks.get(key) || []), pull])
  }
  const chosen = new Set()
  for (const members of stacks.values()) {
    const unreviewed = members
      .filter((pull) => !pull.reviewedBy || !pull.reviewedBy.people.some((login) => login !== me))
      .sort((first, second) => ((first.stack && first.stack.position) || 0) - ((second.stack && second.stack.position) || 0))
    const take = Math.max(1, unreviewed.length - unreviewedLimit)
    for (const pull of unreviewed.slice(0, take)) if (!askedOf(pull)) chosen.add(`${pull.repository}#${pull.number}`)
  }
  return chosen
}
const renameSectionKeys = (lists) => Object.fromEntries(Object.entries(lists || {}).map(([key, value]) => {
  const [name, group, ...rest] = key.split(':')
  return [[renamedSections[name] || name, ...(group === undefined ? [] : [renamedGroups[group] || group]), ...rest].join(':'), value]
}))
const renameSectionWords = (text) => Object.entries({ ...renamedSections, ...renamedGroups }).reduce((words, [before, after]) => words.replace(new RegExp(`^(moved to )?${before}$`), `$1${after}`), text || '')
const migrateSectionNames = () => {
  const placement = readJson(placementPath, null)
  if (placement) {
    const before = JSON.stringify(placement)
    for (const field of ['lists', 'traces', 'manual', 'computed']) if (placement[field]) placement[field] = renameSectionKeys(placement[field])
    for (const key of Object.keys(placement.traces || {})) placement.traces[key] = placement.traces[key].map((trace) => ({ ...trace, text: renameSectionWords(trace.text), to: trace.to ? Object.keys(renameSectionKeys({ [trace.to]: true }))[0] : trace.to }))
    if (JSON.stringify(placement) !== before) writeJson(placementPath, placement)
  }
  const mine = readJson(minePath, null)
  if (mine) {
    const before = JSON.stringify(mine)
    for (const tick of Object.values(mine.ticks || {})) tick.section = renamedSections[tick.section] || tick.section
    mine.order = renameSectionKeys(mine.order)
    if (JSON.stringify(mine) !== before) writeJson(minePath, mine)
  }
  const moves = readLines(movesPath)
  const renamedMoves = moves.map((move) => ({ ...move, from: renameSectionWords(move.from), text: renameSectionWords(move.text) }))
  if (JSON.stringify(renamedMoves) !== JSON.stringify(moves)) writeLines(movesPath, renamedMoves)
}
const mergeOrder = (pulls) => {
  const numbers = new Set(pulls.map((pull) => pull.number))
  const byNumber = new Map(pulls.map((pull) => [pull.number, pull]))
  const dependsOn = new Map(pulls.map((pull) => [pull.number, [...(pull.waitsOn || []), ...(pull.stackedOn ? [pull.stackedOn] : [])].filter((number) => numbers.has(number) && number !== pull.number)]))
  const soonest = (pull) => [pull.reviewDecision === 'APPROVED' && pull.checks === 'pass' ? 0 : 1, pull.threads.person + pull.threads.bot, pull.createdAt]
  const unitOf = (pull) => (pull.stack && byNumber.get(pull.stack.bottom)) || pull
  const compare = (first, second) => {
    const [one, two] = [soonest(unitOf(first)), soonest(unitOf(second))]
    for (const index of [0, 1, 2]) if (one[index] !== two[index]) return one[index] < two[index] ? -1 : 1
    return ((first.stack && first.stack.position) || 0) - ((second.stack && second.stack.position) || 0)
  }
  const placed = []
  const done = new Set()
  let lastStack = null
  while (placed.length < pulls.length) {
    const remaining = pulls.filter((pull) => !done.has(pull.number))
    const free = remaining.filter((pull) => dependsOn.get(pull.number).every((number) => done.has(number)))
    const reaches = (from, target, seen = new Set()) => from === target || (!seen.has(from) && !done.has(from) && (seen.add(from), dependsOn.get(from).some((next) => reaches(next, target, seen))))
    const inCycle = remaining.filter((pull) => (!pull.stackedOn || done.has(pull.stackedOn) || !numbers.has(pull.stackedOn)) && dependsOn.get(pull.number).filter((number) => !done.has(number)).every((number) => reaches(number, pull.number)))
    const ready = free.length ? free : inCycle.length ? inCycle : remaining
    ready.sort((first, second) => Number(!(first.stack && first.stack.bottom === lastStack)) - Number(!(second.stack && second.stack.bottom === lastStack)) || compare(first, second))
    placed.push(ready[0])
    done.add(ready[0].number)
    lastStack = ready[0].stack ? ready[0].stack.bottom : null
  }
  return placed.map((pull) => `${pull.repository}#${pull.number}`)
}
const shortDoing = (doing) => (doing || 'done').replace(/https?:\S+/g, '').split(/:|;|\(| - |,/)[0].trim() || 'done'
const liveAgent = (card) => Boolean(card.agent) && ['working', 'blocked', 'ready', 'reviewing', 'stopped'].includes(card.agent.state)
const flowGroups = { 'in-progress': '', queued: 'Queued', blocked: 'Blocked' }
const reviewGroupOf = (card, pull, flow) => {
  const reviewed = Boolean(pull.myReview) && !pull.respondedSinceReview && !pull.pendingReview
  const reviewingSince = card.state === 'in-progress' && flow && Date.parse(flow.at) > Date.parse(pull.myReview ? pull.myReview.at : 0)
  if (reviewed && !reviewingSince) return 'Complete'
  return flowGroups[card.state] ?? 'Backlog'
}
const taskStateOf = (card, task, marks) => {
  const flow = marks.flow[card.id]
  if (marks.blocks[card.id]) return 'blocked'
  if (flow && flow.state === 'in-progress') return 'in-progress'
  if (card.agent && card.agent.state === 'working') return 'preparing'
  if ((flow && flow.state === 'queued') || card.materials.length || (task && task.ready)) return 'queued'
  return 'not-started'
}
const tabGroupOf = (card, pull) => `${pull && pull.author !== me ? nameOf(pull.author) : card.project || (pull ? `pr ${pull.number}` : 'task')} - ${featureOf(card.title)}`.toLowerCase()

const yourTurnSince = (card, source, tick) => {
  if (!source || source.byHand) return null
  const after = (moment) => Boolean(moment) && Date.parse(moment) > Date.parse(tick.at)
  const task = source.task
  const pull = source.pull
  const now = new Date().toISOString()
  if (card.question && !card.question.answer && after(card.question.asked)) return { at: card.question.asked, why: 'the agent asked you a question' }
  if (card.agent && card.agent.state === 'stopped' && tick.agentState !== 'stopped') return { at: now, why: /approval/.test(card.agent.doing || '') ? 'the agent needs an approval' : 'the agent stopped' }
  if (!pull) return task && task.ready === 'work' && after(task.updated) ? { at: task.updated, why: "the agent's work is ready" } : null
  if (pull.author !== me) {
    if (pull.respondedSinceReview && after(pull.authorActivity)) return { at: pull.authorActivity, why: `${nameOf(pull.author)} responded` }
    if (task && task.ready === 'review' && after(task.updated)) return { at: task.updated, why: 'a prepared review is ready' }
    return null
  }
  if (after(pull.lastReview)) return { at: pull.lastReview, why: 'a new review' }
  if (pull.threads && after(pull.threads.lastOther)) return { at: pull.threads.lastOther, why: 'a new comment' }
  if (task && task.ready === 'fixes' && after(task.updated)) return { at: task.updated, why: 'fixes are ready for your look' }
  if (tick.checks === 'pass' && pull.checks === 'fail') return { at: now, why: 'checks started failing' }
  if (card.primary === 'merge' && !card.waits && (tick.waits || tick.section !== 'Merge')) return { at: now, why: 'approved, ready to merge' }
  return null
}

let lastBuiltCards = {}
const buildState = () => {
  const github = readJson(githubPath, { updated: null, mine: [], teammates: [], meetings: [] })
  const tasks = readTasks()
  const mine = readMine()
  const projectsData = readProjects()
  const date = today()
  const hidden = (id) => mine.snoozed[id] === date || Boolean(mine.dismissed[id])
  const hiddenCards = []
  const noteHidden = (card, section) => hiddenCards.push({ id: card.id, title: card.title, url: card.url, section, why: mine.dismissed[card.id] ? 'dismissed' : 'snoozed until tomorrow' })
  const tasksByPull = new Map(tasks.filter((task) => task.pull).map((task) => [task.pull, task]))
  const tasksByBranch = new Map(tasks.map((task) => [`${task.repo}/${task.branch}`, task]))
  const taskOfPull = (pull) => tasksByPull.get(pull.url) || tasksByBranch.get(`${pull.repository}/${pull.head}`) || null
  const cards = {}
  const sources = {}
  const sectionOf = {}
  const groupOf = {}
  const lists = Object.fromEntries(sectionNames.map((name) => [name, []]))
  const workReady = []
  const place = (card, section) => {
    if (hidden(card.id)) {
      noteHidden(card, section)
      return
    }
    sectionOf[card.id] = section
    lists[section].push(card.id)
  }

  const openUrls = new Set(github.mine.map((pull) => pull.url))
  const reviewerNames = (pull) => pull.reviewers.filter((reviewer) => reviewer.status !== 'approved').map((reviewer) => nameOf(reviewer.login)).join(' and ')
  const anotherReview = (pull) => (pull.teamsPending || []).length ? pull.teamsPending.map((slug) => `needs ${slug.length <= 3 ? slug.toUpperCase() : slug} review`).join(', ') : 'waiting for another review'
  const waitingStanding = (pull) => pull.waits || (reviewerNames(pull) ? `waiting on ${reviewerNames(pull)}` : anotherReview(pull))
  const askedOf = (pull) => {
    if ((pull.labels || []).some((label) => summoningLabels.includes(label))) return 'label'
    const marks = mine.asked[`${pull.repository}#${pull.number}`] || {}
    return Object.values(marks)[0] || (pull.reviewers.find((reviewer) => reviewer.asked) || {}).asked || null
  }
  const solicited = solicitedOf(github.mine, askedOf)
  for (const pull of github.mine) {
    const task = taskOfPull(pull)
    const card = pullCard(pull, task)
    cards[card.id] = card
    sources[card.id] = { pull, task, repository: pull.repository }
    card.state = taskStateOf(card, task, mine)
    card.tabGroup = card.tabGroup || tabGroupOf(card, pull)
    const threadCount = pull.threads.person + pull.threads.bot
    const lastActivity = Date.parse(pull.threads.lastOther || 0) || 0
    const settledByAgent = Boolean(task && task.agent && task.agent.state === 'done' && !task.ready) && Date.parse(task.updated) > lastActivity && pull.checks !== 'fail'
    const approvals = pull.reviewers.filter((reviewer) => reviewer.status === 'approved').length
    const approved = pull.reviewDecision === 'APPROVED'
    const leftForMe = Boolean(pull.threads.person) || pull.checks === 'fail' || pull.conflict || pull.reviewers.some((reviewer) => reviewer.review === 'changes requested')
    const openBase = github.mine.find((other) => other.head === pull.base)
    const waitFor = (number) => {
      const other = github.mine.find((candidate) => candidate.number === number)
      return { text: `waits for #${number}${other ? ` (${other.title})` : ''}`, card: `${pull.repository}#${number}` }
    }
    const holds = [
      pull.checks === 'pending' && { text: 'checks pending', url: `${pull.url}/checks` },
      openBase && waitFor(openBase.number),
      ...pull.waitsOn.filter((number) => !openBase || number !== openBase.number).map(waitFor),
      (pull.waits || '').includes('do not merge') && { text: 'do not merge label', url: pull.url }
    ].filter(Boolean)
    const githubHold = !['CLEAN', 'HAS_HOOKS', 'UNSTABLE'].includes(pull.mergeState) && pull.checks === 'pass' && { text: 'GitHub does not allow merging yet', url: pull.url }
    const changesRequested = pull.reviewers.some((reviewer) => reviewer.review === 'changes requested')
    const waitingForMe = pull.draft || Boolean(threadCount) || changesRequested
    if (approved) card.reviewState = 'approved'
    else if (approvals) card.reviewState = plural(approvals, 'approval')
    if (approved && !leftForMe) {
      const blockers = [...holds, githubHold, card.state === 'blocked' && { text: mine.blocks[card.id].reason }].filter(Boolean)
      place(card, 'Merge')
      groupOf[card.id] = blockers.length ? 'Blocked' : ''
      card.standing = `approved ${ago(pull.stateSince)} ago`
      card.blockers = blockers.length ? blockers : null
      card.waits = blockers.length ? blockers.map((blocker) => blocker.text).join(' · ') : null
      card.buttons = blockers.length ? [] : ['merge']
      card.primary = 'merge'
    } else if (needsAnswer(card)) {
      place(card, 'Questions')
      card.standing = answerStanding(card, pull.stateSince)
    } else if (solicited.has(card.id) && ['not-started', 'preparing'].includes(card.state)) {
      place(card, 'Ask')
      const reviewer = askReviewerOf(pull, mine.asked[card.id] || {})
      card.reviewer = reviewer ? nameOf(reviewer.login) : 'a reviewer'
      card.standing = `${card.reviewer}, not asked`
    } else {
      place(card, 'PRs')
      const fixesReady = task && task.ready === 'fixes'
      card.standing = fixesReady ? `fixes ready ${ago(task.updated)} ago` : waitingForMe ? (pull.draft ? 'draft' : respondStanding(pull)) : waitingStanding(pull)
      if (settledByAgent && card.state === 'not-started') {
        card.standing = `${shortDoing(task.agent.doing)} ${ago(task.agent.since || task.updated)} ago`
        groupOf[card.id] = isToday(task.agent.since || task.updated) ? 'Complete' : 'Waiting for Review'
      } else {
        groupOf[card.id] = flowGroups[card.state] ?? (waitingForMe ? 'Waiting for Me' : 'Waiting for Review')
      }
    }
    if (approvals && !pull.draft && sectionOf[card.id] !== 'Merge' && !hidden(card.id)) {
      const reasons = [
        pull.threads.person && { text: `${plural(pull.threads.person, 'thread')} to answer`, card: card.id },
        pull.checks === 'fail' && { text: 'checks failing', url: `${pull.url}/checks` },
        pull.conflict && { text: 'has a conflict', url: pull.url },
        ...pull.reviewers.filter((reviewer) => reviewer.review === 'changes requested').map((reviewer) => ({ text: `${nameOf(reviewer.login)} requested changes`, url: pull.url })),
        !approved && { text: (pull.teamsPending || []).length ? anotherReview(pull) : 'needs another approval', url: pull.url },
        ...holds
      ].filter(Boolean)
      card.mergeBlockers = reasons.length ? reasons : [githubHold || { text: 'GitHub does not allow merging yet', url: pull.url }]
      lists.Merge.push(card.id)
    }
    if (['Ask', 'Questions', 'Merge'].includes(sectionOf[card.id])) {
      const answeredQuestion = Boolean(card.question && card.question.answer) && !(card.agent && card.agent.state === 'stopped')
      card.prsCopy = flowGroups[card.state] ?? ((sectionOf[card.id] === 'Questions' && !answeredQuestion) || (sectionOf[card.id] === 'Merge' && groupOf[card.id] === '') || pull.draft ? 'Waiting for Me' : 'Waiting for Review')
      lists.PRs.push(card.id)
    }
  }

  for (const pull of github.teammates) {
    const task = taskOfPull(pull)
    const card = pullCard(pull, task)
    sources[card.id] = { pull, task, repository: pull.repository }
    card.state = taskStateOf(card, task, mine)
    card.tabGroup = card.tabGroup || tabGroupOf(card, pull)
    if (needsAnswer(card)) {
      cards[card.id] = card
      place(card, 'Questions')
      card.standing = answerStanding(card, pull.stateSince)
      continue
    }
    if (hidden(card.id)) {
      noteHidden(card, 'Review')
      continue
    }
    cards[card.id] = card
    place(card, 'Review')
    groupOf[card.id] = reviewGroupOf(card, pull, mine.flow[card.id])
    card.reviewState = { APPROVED: 'approved', CHANGES_REQUESTED: 'changes requested', REVIEW_REQUIRED: 'review required' }[pull.reviewDecision] || null
    card.standing = pull.myReview && groupOf[card.id] === 'Complete' ? `you ${pull.myReview.state === 'APPROVED' ? 'approved' : pull.myReview.state === 'CHANGES_REQUESTED' ? 'requested changes' : 'commented'} ${ago(pull.myReview.at)} ago` : pull.respondedSinceReview ? `${nameOf(pull.author)} responded ${ago(pull.authorActivity)} ago` : pull.section === 're-review' ? `pushed since your review, ${ago(pull.stateSince)}` : `${pull.reason || 'waiting on you'}, ${ago(pull.stateSince)}`
  }

  for (const task of tasks) {
    if (task.pull && !openUrls.has(task.pull)) continue
    if (task.pull || task.kind !== 'mine') continue
    const card = taskCard(task)
    cards[card.id] = card
    sources[card.id] = { task, repository: task.repo }
    card.state = taskStateOf(card, task, mine)
    card.tabGroup = card.tabGroup || tabGroupOf(card, null)
    if (needsAnswer(card)) {
      place(card, 'Questions')
      card.standing = answerStanding(card, task.updated)
    } else if (flowGroups[card.state] !== undefined) {
      place(card, 'PRs')
      groupOf[card.id] = flowGroups[card.state]
      if (task.ready === 'work') workReady.push(card.id)
      card.standing = task.ready === 'work' ? `ready ${ago(card.agent && card.agent.since ? card.agent.since : task.updated)} ago, no pull request` : card.state
    } else if (task.agent && task.agent.state === 'done') {
      card.standing = `${shortDoing(task.agent.doing)} ${ago(task.agent.since || task.updated)} ago`
    } else {
      card.standing = card.agent ? `${card.agent.doing || card.agent.state}, ${ago(card.agent.since || task.updated)}` : 'not started'
    }
  }

  const mergedToday = new Set()
  const departedToday = readJson(departedPath, { date, pulls: {} })
  for (const [id, gone] of Object.entries(departedToday.date === date ? departedToday.pulls : {})) {
    if (gone.state !== 'MERGED' || !gone.pull || gone.pull.author !== me || cards[id]) continue
    const card = pullCard(gone.pull, taskOfPull(gone.pull))
    card.agent = null
    card.standing = `merged ${new Date(gone.at).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }).toLowerCase()}`
    cards[id] = card
    sources[id] = { pull: gone.pull, task: taskOfPull(gone.pull), repository: gone.pull.repository }
    place(card, 'Merge')
    groupOf[id] = 'Complete'
    mergedToday.add(id)
  }

  const projects = projectsData.projects.map((project) => {
    const pullIds = github.mine
      .filter((pull) => project.pulls.includes(pull.url) || pull.tickets.some((ticket) => project.tickets.includes(ticket)) || (taskOfPull(pull) || {}).project === project.name)
      .map((pull) => `${pull.repository}#${pull.number}`)
    const pullTickets = new Set(github.mine.filter((pull) => pullIds.includes(`${pull.repository}#${pull.number}`)).flatMap((pull) => pull.tickets))
    const taskIds = Object.values(cards).filter((card) => sources[card.id].task && !sources[card.id].pull && card.project === project.name).map((card) => card.id)
    const byHandIds = project.tasks
      .map((id) => projectsData.tasks[id])
      .filter((item) => item && !item.done && !pullTickets.has(ticketIdOf(item.ticket)))
      .map((item) => {
        const card = byHandCard(item)
        cards[card.id] = card
        sources[card.id] = { byHand: item, repository: 'valinor' }
        card.standing = card.agent ? `started ${ago(card.agent.since)} ago` : 'not started'
        card.state = taskStateOf(card, null, mine)
        card.tabGroup = tabGroupOf(card, null)
        if (!hidden(card.id)) return card.id
        noteHidden(card, 'Projects')
        return null
      })
      .filter(Boolean)
    const doneByHandIds = project.tasks
      .map((id) => projectsData.tasks[id])
      .filter((item) => item && item.done)
      .map((item) => {
        const card = byHandCard(item)
        cards[card.id] = card
        sources[card.id] = { byHand: item, repository: 'valinor' }
        card.done = item.doneAt || null
        card.state = 'complete'
        card.agent = null
        card.standing = item.doneAt ? `done ${isToday(item.doneAt) ? '' : `${new Date(item.doneAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}, `}${new Date(item.doneAt).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }).toLowerCase()}` : 'done'
        card.buttons = []
        card.possible = []
        card.primary = null
        return card.id
      })
    for (const id of pullIds) cards[id].project = cards[id].project || project.name
    const openCards = [...pullIds, ...taskIds, ...byHandIds]
    const done = project.done + (project.finished || []).length + doneByHandIds.length
    return { name: project.name, done, total: done + openCards.length, due: project.due, cards: [...openCards, ...doneByHandIds] }
  })

  for (const card of Object.values(cards)) {
    card.state = card.state || 'not-started'
    card.block = mine.blocks[card.id] || null
    card.checkFailed = mine.checkFailed[card.id] || null
    if (card.state === 'queued' && !card.materials.length && sources[card.id] && sources[card.id].task) card.materials = derivedMaterials(sources[card.id].task, card.id, card.url)
    const ownPull = sources[card.id] && sources[card.id].pull && sources[card.id].pull.author === me
    card.waitsOnTeammate = Boolean(ownPull) && (sectionOf[card.id] === 'Ask' || (sectionOf[card.id] === 'PRs' && groupOf[card.id] === 'Waiting for Review'))
    if (!mergedToday.has(card.id) && !card.done) {
      card.possible = [card.primary === 'merge' && 'merge', 'queue', 'review', 'block', 'requeue', 'dismiss'].filter(Boolean)
      card.buttons = [
        ...card.buttons.filter((button) => button === 'merge'),
        !['queued', 'preparing', 'in-progress'].includes(card.state) && !card.materials.length && !card.waitsOnTeammate && 'queue',
        (card.materials.length > 0 || card.state === 'queued') && 'review',
        card.state !== 'blocked' && 'block',
        ['in-progress', 'blocked'].includes(card.state) && 'requeue',
        'dismiss'
      ].filter(Boolean)
    }
    card.buttons = buttonOrder.filter((button) => card.buttons.includes(button))
    const tick = mine.ticks[card.id]
    card.checked = Boolean(tick && tick.checked && tick.section === (sectionOf[card.id] || null))
    if (card.checked && !tick.at) {
      const baseline = { ...tick, at: new Date().toISOString(), checks: card.checks || null, waits: card.waits || null, agentState: card.agent ? card.agent.state : null }
      updateMine((mineData) => {
        mineData.ticks[card.id] = baseline
      })
      mine.ticks[card.id] = baseline
    }
    const turn = tick && tick.checked && mine.ticks[card.id].at && !card.reviewer ? yourTurnSince(card, sources[card.id], mine.ticks[card.id]) : null
    if (turn) {
      card.checked = false
      const note = { why: turn.why, at: turn.at, cleared: new Date().toISOString() }
      updateMine((mineData) => {
        delete mineData.ticks[card.id]
        mineData.unticked[card.id] = note
      })
      mine.unticked[card.id] = note
      appendLine(movesPath, { at: note.cleared, id: card.id, title: card.title, from: sectionOf[card.id] || '', text: `unticked: ${turn.why}` })
    }
    const unticked = mine.unticked[card.id]
    card.unticked = unticked && Date.now() - Date.parse(unticked.cleared) < 15 * 60 * 1000 && !card.checked ? unticked : null
    const completed = mine.completed[card.id]
    if (completed && sectionOf[card.id]) {
      if (yourTurnSince(card, sources[card.id], completed)) {
        updateMine((mineData) => {
          delete mineData.completed[card.id]
        })
      } else if (sectionOf[card.id] === 'PRs' && sources[card.id].pull && !isToday(completed.at)) {
        const pull = sources[card.id].pull
        const waitingForMe = pull.draft || Boolean(pull.threads.person + pull.threads.bot)
        groupOf[card.id] = waitingForMe ? 'Waiting for Me' : 'Waiting for Review'
        card.standing = waitingForMe ? respondStanding(pull) : waitingStanding(pull)
      } else {
        groupOf[card.id] = 'Complete'
        card.standing = `completed by you ${new Date(completed.at).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }).toLowerCase()}`
        card.completed = completed.at
      }
    }
    if (groupOf[card.id] === 'Complete') {
      card.state = 'complete'
      if (card.completed || (mine.ticks[card.id] && mine.ticks[card.id].checked)) card.checked = true
      if (mine.flow[card.id] || mine.blocks[card.id]) {
        updateMine((mineData) => {
          delete mineData.flow[card.id]
          delete mineData.blocks[card.id]
        })
        delete mine.flow[card.id]
      }
    }
  }
  Object.values(cards).forEach((card) => {
    card.comments = mine.comments[card.id] || []
  })
  const waitedOn = new Set(github.mine.flatMap((pull) => pull.reviewers.filter((reviewer) => reviewer.status !== 'approved').map((reviewer) => reviewer.login)))
  const attention = (id) => {
    const card = cards[id]
    const pull = sources[id] && sources[id].pull
    const agentState = card.agent ? card.agent.state : null
    const readyFirst = card.primary === 'open' || card.primary === 'send' ? 0 : agentState === 'working' ? 3 : 1
    if (!pull) return readyFirst * 1000
    const fromPeople = pull.threads && pull.threads.person ? 0 : 1
    const owedAReview = pull.author !== me && waitedOn.has(pull.author) ? 0 : 1
    const stackPlace = pull.stack ? pull.stack.position : 0
    return readyFirst * 1000 + (pull.author === me ? fromPeople : owedAReview) * 100 + stackPlace
  }
  const ordered = (list, ids) => {
    const order = mine.order[list] || []
    const rank = (id) => (order.includes(id) ? order.indexOf(id) : order.length)
    return [...ids].sort((first, second) => rank(first) - rank(second))
  }

  const dayHours = mine.day && mine.day.date === date ? mine.day.hours : {}
  const day = []
  for (let hour = firstHour; hour <= lastHour; hour += 1) {
    const entry = dayHours[hour] || {}
    day.push({
      hour,
      title: entry.title || '',
      cards: (entry.cards || []).filter((id) => cards[id]),
      meetings: github.meetings.filter((meeting) => Number(meeting.start.split(':')[0]) === hour).map((meeting) => `${clockOf(meeting.start)} ${meeting.title}`)
    })
  }

  const waitingOf = (pull) => {
    const hiddenEntry = hiddenCards.find((entry) => entry.id === `${pull.repository}#${pull.number}`)
    if (hiddenEntry) return hiddenEntry.why === 'dismissed' ? 'dismissed' : 'snoozed'
    if (pull.draft) return 'draft'
    if (pull.checks === 'pending') return 'checks running'
    if (pull.waits) return pull.waits
    if (reviewerNames(pull)) return `waiting on ${reviewerNames(pull)}`
    if (pull.reviewDecision === 'REVIEW_REQUIRED') return anotherReview(pull)
    return pull.notes[0] || pull.column.replace(/-/g, ' ')
  }
  const pullRow = (pull, note) => ({ id: `${pull.repository}#${pull.number}`, number: pull.number, title: pull.title, note, waiting: waitingOf(pull), state: (cards[`${pull.repository}#${pull.number}`] || {}).state || null, stack: pull.stack ? `${pull.stack.position}/${pull.stack.size}` : '', age: ago(pull.stateSince || pull.createdAt), old: daysSince(pull.stateSince || pull.createdAt) >= 4, url: pull.url })
  const inColumn = (column) => github.mine.filter((pull) => pull.column === column && !(column !== 'drafted' && pull.draft))
  const needsMeNote = (pull) => {
    const task = taskOfPull(pull)
    if (task && task.ready === 'fixes') return 'fixes ready'
    const threadCount = pull.threads.person + pull.threads.bot
    if (threadCount && !pull.threads.person) return `${plural(threadCount, 'thread')} from ${botReviewer(pull) === 'greptile' ? 'greptile' : 'the bot'}`
    return threadCount ? plural(threadCount, 'thread') : pull.checks === 'fail' ? 'checks failing' : pull.notes[0] || ''
  }
  const agentWorkRows = workReady.filter((id) => sectionOf[id]).map((id) => ({ id, number: '', title: cards[id].title, note: 'work ready, no pull request', stack: '', age: ago(cards[id].opened), old: false, url: cards[id].url }))
  const draftRows = inColumn('drafted').map((pull) => pullRow(pull, (cards[`${pull.repository}#${pull.number}`].question ? 'question' : 'draft')))
  const pulls = {
    you: [
      { heading: 'Needs me', rows: inColumn('needs-me').map((pull) => pullRow(pull, needsMeNote(pull))) },
      { heading: 'Accepted', rows: inColumn('accepted').map((pull) => pullRow(pull, 'merge')) },
      { heading: 'Not published', rows: [...draftRows, ...agentWorkRows] }
    ],
    others: [
      { heading: 'Needs review', rows: inColumn('needs-review').map((pull) => pullRow(pull, cards[`${pull.repository}#${pull.number}`].reviewer ? cards[`${pull.repository}#${pull.number}`].standing : reviewerNames(pull))) },
      { heading: 'Can be reviewed', rows: inColumn('can-review').map((pull) => pullRow(pull, reviewerNames(pull))) },
      { heading: 'Wait to review', rows: inColumn('wait-to-review').map((pull) => pullRow(pull, reviewerNames(pull))) },
      { heading: 'Blocked', rows: inColumn('blocked').map((pull) => pullRow(pull, pull.waits || '')) }
    ]
  }

  const placement = readJson(placementPath, { date, lists: {}, traces: {} })
  const placementBefore = JSON.stringify(placement)
  placement.date = date
  const keyOf = {}
  const current = {}
  for (const name of sectionNames) {
    const byAttention = ordered(name, [...lists[name]].sort((first, second) => attention(first) - attention(second)))
    for (const group of groupNames[name] || ['']) {
      const key = `${name}:${group}`
      const alsoMerge = (id) => name === 'Merge' && Boolean(cards[id].mergeBlockers)
      const alsoPrs = (id) => name === 'PRs' && Boolean(cards[id].prsCopy)
      current[key] = byAttention.filter((id) => (alsoMerge(id) ? 'Blocked' : alsoPrs(id) ? cards[id].prsCopy : groupOf[id] || '') === group)
      for (const id of current[key]) if ((!alsoMerge(id) && !alsoPrs(id)) || !sectionOf[id]) keyOf[id] = key
    }
  }
  const departed = readJson(departedPath, { date, pulls: {} })
  const goneText = (id) => {
    if (hiddenCards.some((hiddenCard) => hiddenCard.id === id)) return null
    if (cards[id]) return sources[id] && sources[id].pull && lastBuiltCards[id] && lastBuiltCards[id].primary === 'merge' && sources[id].pull.reviewDecision !== 'APPROVED' ? 'approval withdrawn' : 'nothing for you here now'
    const gone = departed.pulls[id]
    if (!gone) return 'no longer listed'
    if (gone.state === 'MERGED') return `merged${gone.by ? ` by ${nameOf(gone.by)}` : ''}`
    if (gone.state === 'CLOSED') return 'closed'
    return 'review no longer requested'
  }
  const labelOf = (key) => key.endsWith(':') ? key.slice(0, -1) : key.split(':')[1]
  const merging = mergeOrder(github.mine)
  placement.manual = placement.manual || {}
  placement.computed = placement.computed || {}
  for (const key of mergeKeys) {
    const computed = (current[key] || []).filter((id) => merging.includes(id)).sort((first, second) => merging.indexOf(first) - merging.indexOf(second))
    placement.computed[key] = computed
    const manual = placement.manual[key]
    if (manual && manual.signature !== computed.join(',')) delete placement.manual[key]
  }
  for (const key of Object.keys(placement.lists)) {
    const [name, group] = key.split(':')
    if ((groupNames[name] || ['']).includes(group)) continue
    delete placement.lists[key]
  }
  delete placement.traces
  for (const key of new Set([...Object.keys(placement.lists), ...Object.keys(current)])) {
    const previous = placement.lists[key] || []
    const now = current[key] || []
    for (const id of previous.filter((id) => !now.includes(id))) {
      const text = keyOf[id] ? `moved to ${labelOf(keyOf[id])}` : goneText(id)
      if (!text) continue
      const card = cards[id] || {}
      appendLine(movesPath, { at: new Date().toISOString(), id, title: card.title || (departed.pulls[id] && departed.pulls[id].title) || id, from: labelOf(key), text })
    }
    const stable = [...previous.filter((id) => now.includes(id)), ...now.filter((id) => !previous.includes(id))]
    const computed = placement.computed[key] ? [...placement.computed[key], ...now.filter((id) => !placement.computed[key].includes(id))] : null
    const manual = placement.manual[key] ? [...placement.manual[key].ids.filter((id) => now.includes(id)), ...now.filter((id) => !placement.manual[key].ids.includes(id))] : null
    placement.lists[key] = manual || computed || stable
    if (!placement.lists[key].length) delete placement.lists[key]
  }
  if (JSON.stringify(placement) !== placementBefore) writeJson(placementPath, placement)
  lastBuiltCards = JSON.parse(JSON.stringify(cards))
  const moves = readLines(movesPath)
  if (moves.length > 300) writeLines(movesPath, moves.slice(-200))
  const sectionsOut = sectionNames.map((name) => {
    const groups = (groupNames[name] || ['']).map((group) => ({ name: group, cards: placement.lists[`${name}:${group}`] || [] }))
    return { name, cards: groups.flatMap((group) => group.cards), groups }
  })

  const syncs = readLines(syncsPath)
  const lastOk = [...syncs].reverse().find((entry) => entry.ok)
  const state = {
    updated: github.updated,
    sync: { running: Boolean(refreshing), lastOk: lastOk ? lastOk.at : github.updated, pausedUntil: pausedUntil > Date.now() ? new Date(pausedUntil).toISOString() : null, history: syncs.slice(-50).reverse(), moves: readLines(movesPath).slice(-50).reverse() },
    date,
    agentsWorking: agentsList.filter((agent) => agent.kind === 'background' && agent.status === 'busy').length,
    agents: agentsList.filter((agent) => agent.kind === 'background').map((agent) => {
      const card = Object.values(cards).find((candidate) => candidate.agent && (candidate.agent.sessionId === agent.sessionId || candidate.agent.session === agent.name))
      return { name: agent.name, status: agent.status === 'waiting' ? 'needs an approval' : agent.status || null, state: agent.state || null, card: card ? card.id : null, section: card ? sectionOf[card.id] || null : null }
    }),
    sections: sectionsOut,
    cards,
    day,
    projects: projects.map((project) => ({ ...project, cards: ordered(`project:${project.name}`, project.cards) })),
    pulls,
    log: readLines(logPath).slice(-200),
    acked: [...acknowledged.keys()].filter((key) => Date.now() - acknowledged.get(key) < 2 * 60 * 60 * 1000),
    hidden: hiddenCards,
    answered: readLines(answersPath).slice(-20).reverse(),
    trackers: { water: (mine.trackers.water || []).filter(isToday), stood: (mine.trackers.stood || []).filter(isToday) }
  }
  return { state, sources, sectionOf, github }
}

const worktreeOf = (checkout, branch) => {
  if (dryRun) return checkout
  try {
    const printed = childProcess.execFileSync('/bin/zsh', ['-lic', 'wk "$1"', 'wk', branch], { cwd: checkout, env: childEnvironment, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })
    const directory = printed.trim().split('\n').pop()
    return directory && fs.existsSync(directory) ? directory : checkout
  } catch (error) {
    return checkout
  }
}
const featureOf = (title) => (title || '').toLowerCase().replace(/[^a-z0-9 ]/g, '').split(/\s+/).filter(Boolean).slice(0, 3).join(' ')
const startAgent = async (id, kind, note) => {
  const { state, sources } = buildState()
  const card = state.cards[id]
  const source = sources[id]
  if (!card || !source) return { status: 404, error: `no card ${id}` }
  const sessionId = source.task && sessionIdOf(source.task.agent)
  if (card.agent && !['done', 'stopped'].includes(card.agent.state) && sessionId) {
    if (!note) return { status: 409, error: 'an agent is already on this card' }
    const messageId = crypto.randomUUID()
    return deliveryReply(await deliver({ sessionId, text: `[note] ${note}`, cwd: source.task.worktree || path.join(home, 'Projects', source.repository), id: messageId }), messageId)
  }
  const pull = source.pull
  const target = pull ? pull.url : source.byHand ? source.byHand.ticket || source.byHand.title : source.task.pull || source.task.ticket || source.task.title || source.task.branch
  const prompts = { review: `/review ${target} --prepare`, address: `/address-comments ${target} --unattended`, fix: `/fix-ci ${target}`, start: `/manage ${target}` }
  if (!prompts[kind]) return { status: 400, error: `kind must be one of ${Object.keys(prompts).join(', ')}` }
  const botsOnly = Boolean(pull) && pull.threads.person === 0 && pull.threads.bot > 0
  const models = { review: 'opus', address: 'opus', fix: 'opus', start: 'opus' }
  const group = pull && pull.author !== me ? nameOf(pull.author) : card.project || (pull ? `pr ${pull.number}` : source.repository)
  const name = `${group} - ${featureOf(card.title)}`.toLowerCase()
  const prompt = note ? `${prompts[kind]}\n\nNote from Camen: ${note}` : prompts[kind]
  const checkout = path.join(home, 'Projects', source.repository)
  const worktrees = path.join(home, 'Projects', `.${source.repository}-worktrees`)
  const headBranch = pull ? pull.head : source.task ? source.task.branch : null
  const cwd = headBranch ? worktreeOf(checkout, headBranch) : checkout
  const started = await startSession({ cwd, model: models[kind], name, prompt, addDirectories: [worktrees] })
  if (source.byHand) {
    updateProjects((projects) => {
      projects.tasks[id].agent = { session: name, sessionId: started.sessionId, since: new Date().toISOString(), kind }
    })
  } else {
    const repository = pull ? pull.repository : source.task.repo
    const branch = pull ? pull.head : source.task.branch
    const extra = source.task ? [] : ['--kind', pull.author === me ? 'mine' : 'teammate', '--pull', pull.url, '--title', pull.title, '--base', pull.base]
    childProcess.execFileSync(process.execPath, [taskSetScript, '--task', `${repository}/${branch}`, '--session', name, '--session-id', started.sessionId, '--agent-kind', kind, '--state', 'working', '--doing', 'starting', ...extra], { encoding: 'utf8' })
  }
  console.log(`started ${kind} on ${id}: ${name} (${started.sessionId})`)
  return { status: 200, session: name, sessionId: started.sessionId }
}

let assistantTurn = Promise.resolve()
const withAssistant = (work) => {
  const run = assistantTurn.then(work, work)
  assistantTurn = run.catch(() => {})
  return run
}
const lockAssistant = (why) => writeJson(assistantLockPath, { at: new Date().toISOString(), pid: process.pid, why })
const unlockAssistant = () => fs.rmSync(assistantLockPath, { force: true })
const assistantLockedElsewhere = () => {
  const lock = readJson(assistantLockPath, null)
  return Boolean(lock) && lock.pid !== process.pid && Date.now() - Date.parse(lock.at) < 2 * 60 * 1000
}
const listAgentsSurely = async () => {
  for (let attempt = 0; attempt < 3; attempt += 1) {
    const list = await listAgents()
    if (list) return list
    await wait(3000)
  }
  return null
}
const startAssistant = async (reason) => {
  lockAssistant(`starting one: ${reason}`)
  try {
    const list = await listAgentsSurely()
    if (!list) throw new Error('claude agents gave no listing, so it is unknown which assistants run; not starting one')
    for (const other of list.filter((agent) => agent.name === 'assistant' && agent.kind === 'background')) {
      await runClaude(['stop', other.id], notesDirectory)
      console.log(`assistant: stopped ${other.sessionId} (before starting a new one: ${reason})`)
    }
    const started = await startSession({ cwd: notesDirectory, model: 'fable', name: 'assistant', prompt: '/assistant', flags: assistantCompaction })
    updateMine((mine) => {
      mine.assistant = { sessionId: started.sessionId, date: today(), hourly: new Date().toISOString(), started: new Date().toISOString() }
    })
    console.log(`assistant: started ${started.sessionId} (${reason})`)
    return started.sessionId
  } finally {
    unlockAssistant()
  }
}
const assistantRunning = () => {
  const assistant = readMine().assistant
  return Boolean(assistant && assistant.sessionId) && agentsList.some((agent) => agent.sessionId === assistant.sessionId)
}
const tellAssistant = (text, id) => withAssistant(async () => {
  if (!readConfig().assistant) return 'assistant off'
  const assistant = readMine().assistant
  const list = await listAgentsSurely()
  const listed = Boolean(list) && Boolean(assistant && assistant.sessionId) && list.some((agent) => agent.sessionId === assistant.sessionId)
  const justStarted = Boolean(assistant && assistant.started) && Date.now() - Date.parse(assistant.started) < 2 * 60 * 1000
  if (!listed && assistant && assistant.sessionId && (!list || justStarted || assistantLockedElsewhere())) {
    queueMessage({ sessionId: assistant.sessionId, text, cwd: notesDirectory, id })
    return 'queued'
  }
  if (!list) {
    console.log('assistant: none started (claude agents gave no listing and no assistant is recorded)')
    return 'not delivered: the list of running agents could not be read'
  }
  if (!listed) {
    const sessionId = await startAssistant(assistant && assistant.sessionId ? `its session ${assistant.sessionId} is not in claude agents` : 'none recorded')
    queueMessage({ sessionId, text, cwd: notesDirectory, id })
    return 'queued for a new assistant'
  }
  return deliver({ sessionId: assistant.sessionId, text, cwd: notesDirectory, id })
})
const tendAssistant = () => withAssistant(async () => {
  if (!readConfig().assistant) return
  const assistant = readMine().assistant
  if (!assistant || !assistant.sessionId) return
  if (assistant.date !== today()) {
    await startAssistant(`a new day: the last one started ${assistant.date}`)
    return
  }
  const hour = new Date().getHours()
  if (assistantRunning() && hour >= firstHour && hour <= lastHour && Date.now() - Date.parse(assistant.hourly || 0) >= hourMilliseconds) {
    updateMine((mine) => {
      mine.assistant.hourly = new Date().toISOString()
    })
    await deliver({ sessionId: assistant.sessionId, text: '[hourly]', cwd: notesDirectory })
  }
})

const autostart = async () => {
  const config = readConfig()
  if (!config.autostart) return
  const { state, github } = buildState()
  const running = Object.values(readMine().autostarted).filter((entry) => agentsList.some((agent) => agent.sessionId === entry.sessionId && agent.state !== 'done')).length
  let room = (config.maxAutoAgents || 3) - running
  const marks = readMine()
  for (const pull of github.mine) {
    if (room <= 0) return
    const id = `${pull.repository}#${pull.number}`
    const card = state.cards[id]
    const threadCount = pull.threads.person + pull.threads.bot
    if (!card || !withoutAgent(card) || !(threadCount || pull.checks === 'fail' || pull.conflict)) continue
    if (marks.ticks[id] || marks.completed[id]) continue
    const key = `${id}@${pull.headSha}:${threadCount}`
    if (readMine().autostarted[key]) continue
    const result = await startAgent(id, pull.checks === 'fail' || pull.conflict ? 'fix' : 'address', '')
    if (result.status !== 200) continue
    updateMine((mine) => {
      mine.autostarted[key] = { sessionId: result.sessionId, at: new Date().toISOString() }
    })
    room -= 1
  }
}

let refreshing = null
let lastRefreshStarted = 0
let lastPolled = 0
let pausedUntil = 0
let pauseMinutes = 0
const pullStateOf = (url) => {
  const [, repository, number] = /github\.com\/[^/]+\/([^/]+)\/pull\/(\d+)/.exec(url)
  return JSON.parse(run('gh', ['api', `repos/${owner}/${repository}/pulls/${number}`, '--jq', '{ state: (if .merged then "MERGED" else (.state | ascii_upcase) end), mergedBy: (if .merged_by then { login: .merged_by.login } else null end) }'], home))
}
const settleProjects = async () => {
  const github = readJson(githubPath, { mine: [] })
  const openUrls = new Set(github.mine.map((pull) => pull.url))
  const settled = (project, url) => (project.finished || []).includes(url) || (project.closed || []).includes(url)
  const gone = readProjects().projects.flatMap((project) => project.pulls.filter((url) => !openUrls.has(url) && !settled(project, url)))
  const states = {}
  for (const url of new Set(gone)) {
    try {
      states[url] = pullStateOf(url).state
    } catch (error) {
      console.log(`could not read the state of ${url}`)
    }
  }
  updateProjects((data) => {
    for (const project of data.projects) {
      project.finished = project.finished || []
      project.closed = project.closed || []
      for (const pull of github.mine) {
        if (!project.pulls.includes(pull.url) && pull.tickets.some((ticket) => project.tickets.includes(ticket))) project.pulls.push(pull.url)
      }
      for (const url of project.pulls) {
        if (settled(project, url)) continue
        if (states[url] === 'MERGED') project.finished.push(url)
        if (states[url] === 'CLOSED') project.closed.push(url)
      }
    }
  })
}

const syncChange = (before, after) => {
  const byId = (github) => new Map([...(github.mine || []), ...(github.teammates || [])].map((pull) => [`${pull.repository}#${pull.number}`, pull]))
  const old = byId(before)
  const now = byId(after)
  const parts = []
  const requests = (after.teammates || []).filter((pull) => !old.has(`${pull.repository}#${pull.number}`)).length
  if (requests) parts.push(plural(requests, 'new review request'))
  for (const [id, pull] of now) {
    const previous = old.get(id)
    const number = `#${pull.number}`
    if (!previous) {
      if (pull.author === me) parts.push(`${number} opened`)
      continue
    }
    if (previous.checks !== pull.checks && ['pass', 'fail'].includes(pull.checks)) parts.push(`${number} checks ${pull.checks === 'pass' ? 'passed' : 'failing'}`)
    if (previous.reviewDecision !== pull.reviewDecision && pull.reviewDecision === 'APPROVED') parts.push(`${number} approved`)
    const threads = (entry) => (entry.threads ? entry.threads.person + entry.threads.bot : 0)
    if (threads(pull) > threads(previous)) parts.push(`${number} new comments`)
    if (previous.lastPush !== pull.lastPush && pull.author !== me) parts.push(`${number} pushed`)
  }
  for (const [id, pull] of old) if (!now.has(id)) parts.push(`#${pull.number} left`)
  return parts.length ? parts.join(', ') : 'no change'
}

const noteDeparted = async (before, after) => {
  const present = new Set([...(after.mine || []), ...(after.teammates || [])].map((pull) => pull.url))
  const gone = [...(before.mine || []), ...(before.teammates || [])].filter((pull) => !present.has(pull.url))
  const departed = readJson(departedPath, { date: today(), pulls: {} })
  if (departed.date !== today()) {
    departed.date = today()
    departed.pulls = {}
  }
  if (!gone.length && departed.date === today()) return
  for (const pull of gone) {
    let view = { state: 'UNKNOWN', mergedBy: null }
    try {
      view = pullStateOf(pull.url)
    } catch (error) {
      console.log(`could not read the state of ${pull.url}`)
    }
    departed.pulls[`${pull.repository}#${pull.number}`] = { title: pull.title, state: view.state, by: view.mergedBy ? view.mergedBy.login : null, at: new Date().toISOString(), pull }
  }
  writeJson(departedPath, departed)
}

const refresh = () => {
  if (refreshing) return refreshing
  const started = new Date()
  lastRefreshStarted = started.getTime()
  const before = readJson(githubPath, { mine: [], teammates: [] })
  refreshing = new Promise((resolve) => {
    const child = childProcess.spawn(process.execPath, [workStateScript], { env: childEnvironment, stdio: ['ignore', 'pipe', 'pipe'], timeout: syncTimeoutMilliseconds })
    let output = ''
    child.stdout.on('data', (chunk) => (output += chunk))
    child.stderr.on('data', (chunk) => (output += chunk))
    child.on('error', (error) => resolve({ code: -1, output: error.message }))
    child.on('close', (code, signal) => resolve({ code: signal ? -1 : code, output: signal ? `${output}\ntimed out after ${syncTimeoutMilliseconds / 60000} minutes, stopped` : output }))
  })
    .then(async (result) => {
      console.log(`refresh ${new Date().toISOString()}: ${result.output.trim().split('\n').slice(-3).join(' | ')}`)
      const lines = result.output.trim().split('\n').filter((line) => line.trim() && !/\bat \S|node:internal|^\s*'|^Node\.js|^\s*[}{^\]]\s*,?$/.test(line))
      const reason = (lines.find((line) => /timed out after|^gh:|gh auth|HTTP \d|ETIMEDOUT|ENOTFOUND|EAI_AGAIN|ECONNRESET|rate limit|could not/i.test(line)) || lines.find((line) => /error/i.test(line) && !/Command failed/.test(line)) || lines.find((line) => /error|failed/i.test(line)) || lines.pop() || 'no output').trim().replace(/^Error:\s*/, '').slice(0, 200)
      const rateLimited = result.code !== 0 && /rate limit/i.test(result.output)
      if (rateLimited) {
        pauseMinutes = pauseMinutes ? Math.min(pauseMinutes * 2, longestPauseMinutes) : firstPauseMinutes
        const retryAfter = (/retry after (\S+Z)/.exec(result.output) || [])[1]
        pausedUntil = Math.max(Date.now() + pauseMinutes * 60 * 1000, retryAfter ? Date.parse(retryAfter) : 0)
      } else if (result.code === 0) {
        pauseMinutes = 0
        pausedUntil = 0
      }
      const pauseText = `paused until ${new Date(pausedUntil).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }).toLowerCase()} (GitHub rate limit)`
      const usage = /github: (\d+) calls?, cost (\d+)/.exec(result.output)
      const entry = { at: started.toISOString(), seconds: Math.round((Date.now() - started) / 1000), ok: result.code === 0, error: result.code === 0 ? null : rateLimited ? pauseText : reason, change: result.code === 0 ? syncChange(before, readJson(githubPath, before)) : null, ...(rateLimited ? { paused: new Date(pausedUntil).toISOString(), pauseMinutes } : {}), ...(usage ? { calls: Number(usage[1]), cost: Number(usage[2]) } : {}) }
      writeLines(syncsPath, [...readLines(syncsPath), entry].slice(-50))
      if (entry.ok) await noteDeparted(before, readJson(githubPath, before))
      await listAgents()
      if (entry.ok) await settleProjects()
      await drainOutbox()
      await tendAssistant()
      await autostart()
      return result
    })
    .catch((error) => {
      console.log(`refresh failed: ${error.stack}`)
      return { code: -1, output: error.message }
    })
    .finally(() => {
      refreshing = null
    })
  return refreshing
}

const agentWorking = () => agentsList.some((agent) => agent.kind === 'background' && agent.status === 'busy')
const syncTick = () => {
  if (Date.now() < pausedUntil) return
  const watchedNow = Date.now() - lastPolled < watchedMilliseconds || agentWorking()
  if (!watchedNow && Date.now() - lastRefreshStarted < idleRefreshMilliseconds - 30 * 1000) return
  refresh()
}

const run = (command, args, cwd) => {
  if (dryRun) {
    console.log(`dry run in ${cwd}: ${command} ${JSON.stringify(args)}`)
    return ''
  }
  return childProcess.execFileSync(command, args, { cwd, env: childEnvironment, encoding: 'utf8' })
}
const ghosttyTabScript = `on run arguments
  set {workingDirectory, shellCommand, tabTitle} to arguments
  if application "Ghostty" is not running then return "not running"
  tell application "Ghostty"
    set surface to new surface configuration
    set initial working directory of surface to workingDirectory
    set command of surface to shellCommand
    set wait after command of surface to true
    if (count of windows) > 0 then
      set openedTab to new tab in front window with configuration surface
    else
      set openedTab to selected tab of (new window with configuration surface)
    end if
    set name override of openedTab to tabTitle
    activate
  end tell
  return "opened"
end run`
const openTerminal = (directory, command, title) => {
  const quoted = `'${command.replace(/'/g, `'\\''`)}'`
  try {
    if (run('osascript', ['-e', ghosttyTabScript, directory, `/bin/zsh -lic ${quoted}`, title], directory).trim() === 'opened') return
  } catch (error) {
    console.log(`ghostty tab not opened, opening a window: ${error.message.split('\n')[0]}`)
  }
  run('open', ['-na', 'Ghostty.app', '--args', `--working-directory=${directory}`, '--wait-after-command=true', '-e', '/bin/zsh', '-lic', command], directory)
}

const safariLock = '/tmp/safari-tab-group.lock'
const openTabGroup = (name, urls) => {
  if (dryRun) {
    console.log(`dry run: safari tab group "${name}": ${urls.join(' ')}`)
    return { ok: true, how: 'dry run, not opened' }
  }
  for (let attempt = 0; attempt < 40; attempt += 1) {
    try {
      fs.mkdirSync(safariLock)
      try {
        return { ok: true, how: run('osascript', [safariScript, name, ...urls], home).trim() }
      } catch (error) {
        return { ok: false, error: `Safari did not open the tab group: ${error.message.split('\n')[0]}` }
      } finally {
        fs.rmdirSync(safariLock)
      }
    } catch (error) {
      if (error.code !== 'EEXIST') throw error
      childProcess.execFileSync('/bin/sleep', ['0.5'])
    }
  }
  return { ok: false, error: `another session holds ${safariLock}` }
}

const deliverToCard = async (id, text) => {
  const { sources } = buildState()
  const source = sources[id]
  const task = source && source.task
  const messageId = crypto.randomUUID()
  if (id === assistantTaskId) return deliveryReply(await tellAssistant(text, messageId), messageId)
  await listAgents()
  const sessionId = task && sessionIdOf(task.agent)
  if (!sessionId) return { status: 409, error: 'no agent session on this card' }
  return deliveryReply(await deliver({ sessionId, text, cwd: task.worktree || path.join(home, 'Projects', task.repo), id: messageId }), messageId)
}

const handlers = {
  '/api/tick': async ({ id, checked }) => {
    const { sectionOf, state } = buildState()
    const card = state.cards[id] || {}
    updateMine((mine) => {
      mine.ticks[id] = { checked: Boolean(checked), section: sectionOf[id] || null, at: new Date().toISOString(), checks: card.checks || null, waits: card.waits || null, agentState: card.agent ? card.agent.state : null }
      delete mine.unticked[id]
      delete mine.checkFailed[id]
    })
    if (!checked || !card.id) return { status: 200 }
    const urls = [card.url, ...(card.materials || []).map((material) => material.url)].filter(Boolean)
    const messageId = crypto.randomUUID()
    return deliveryReply(await tellAssistant(`[checked] ${id} ${card.title} ${[...new Set(urls)].join(' ')}`.trim(), messageId), messageId)
  },
  '/api/check-result': async ({ key, complete, reason }) => {
    const { state } = buildState()
    if (!state.cards[key]) return { status: 404, error: `no card ${key}` }
    if (complete) return handlers['/api/complete']({ id: key, complete: true })
    if (!(reason || '').trim()) return { status: 400, error: 'reason missing: say what is not done' }
    updateMine((mine) => {
      delete mine.ticks[key]
      mine.checkFailed[key] = { reason: reason.trim(), at: new Date().toISOString() }
    })
    return { status: 200 }
  },
  '/api/queue': async ({ id }) => {
    const { state, sources } = buildState()
    const card = state.cards[id]
    const source = sources[id]
    if (!card) return { status: 404, error: `no card ${id}` }
    if (card.waitsOnTeammate) return { status: 409, error: "nothing for you to review: it waits on a teammate's review" }
    const prepared = card.materials.length > 0 || card.state === 'in-progress'
    const working = Boolean(card.agent) && card.agent.state === 'working'
    updateMine((mine) => {
      mine.flow[id] = { state: 'queued', at: new Date().toISOString() }
      delete mine.blocks[id]
      delete mine.checkFailed[id]
    })
    if (prepared || working) return { status: 200, moved: 'queued' }
    const pull = source.pull
    const kind = !pull && !source.task ? 'start' : !pull ? (source.task.ready ? 'review' : 'start') : pull.author !== me ? 'review' : pull.threads.person + pull.threads.bot > 0 ? 'address' : pull.checks === 'fail' || pull.conflict ? 'fix' : 'review'
    const note = 'Camen queued this to review. Do what it needs first, then record what he should open with task-set.cjs --material "kind|label|url" (one per page) so the card lands in his Queued list.'
    const started = await startAgent(id, kind, note)
    if (started.status !== 200) {
      updateMine((mine) => {
        delete mine.flow[id]
      })
      return started
    }
    return { ...started, moved: 'preparing', kind }
  },
  '/api/review': async ({ id }) => {
    const { sources, state } = buildState()
    const card = state.cards[id]
    if (!card) return { status: 404, error: `no card ${id}` }
    if (!card.materials.length && card.state !== 'queued') return { status: 409, error: 'nothing to review yet: no review materials on this card. Press queue to have them prepared' }
    if (!card.materials.length) {
      const asked = await deliverToCard(id, '[open review]')
      if (asked.status && asked.status !== 200) return asked
      updateMine((mine) => {
        mine.flow[id] = { state: 'in-progress', at: new Date().toISOString() }
        delete mine.blocks[id]
      })
      return { ...asked, askedAgent: true }
    }
    const urls = card.materials.map((material) => material.url)
    const opened = openTabGroup(card.tabGroup, urls)
    if (!opened.ok) return { status: 500, error: opened.error }
    updateMine((mine) => {
      mine.flow[id] = { state: 'in-progress', at: new Date().toISOString() }
      delete mine.blocks[id]
    })
    const live = Boolean(card.agent) && ['working', 'blocked', 'ready', 'reviewing'].includes(card.agent.state)
    if (!live) return { status: 200, tabGroup: card.tabGroup, urls, opened: opened.how }
    try {
      const task = sources[id] && sources[id].task
      const taskDirectory = task ? path.dirname(taskPathOf(task)) : '<task directory>'
      const told = await deliverToCard(id, [
        '[reviewing]',
        `Opened in Safari tab group "${card.tabGroup}": ${urls.join(' ')}`,
        'He is reviewing now. In this turn:',
        '1. task-set.cjs --state reviewing --doing "reviewing in difit".',
        "2. Start what is not up: the app for this branch and every difit server this review runs (the difit skill's Start).",
        '3. Update summary.html\'s steps: "Run the app" done with its urls, "Your review" in progress.',
        `4. Record each new url with --material, and open only the new tabs into the group "${card.tabGroup}", never the whole set again.`,
        `5. Arm the difit comment monitor: Monitor with timeout_ms 1800000 and command node ~/.claude/scripts/difit-comments-watch.cjs '${taskDirectory}'. Re-arm it on expiry while the state is reviewing; stop it when the review closes.`,
        '6. On each comment it reports, reply in that difit thread at once with one line on what you will do ("Making the change in a new commit", "Pushing <sha> and posting the hash on <reviewer>\'s thread", "Answering below"), act on it by ~/.claude/skills/review/push-and-post.md\'s markers, then reply again with the result (the commit hash, what was posted, or the answer). No comment of his is left without a reply. There is no send comments button any more.'
      ].join('\n'))
      return { status: 200, tabGroup: card.tabGroup, urls, opened: opened.how, delivery: told.delivery || null, ...(told.error ? { agentError: told.error } : {}) }
    } catch (error) {
      return { status: 200, tabGroup: card.tabGroup, urls, opened: opened.how, agentError: error.message }
    }
  },
  '/api/requeue': async ({ id }) => {
    const { state } = buildState()
    const card = state.cards[id]
    if (!card) return { status: 404, error: `no card ${id}` }
    if (!['in-progress', 'blocked'].includes(card.state)) return { status: 409, error: `it is ${card.state}, not in progress or blocked` }
    updateMine((mine) => {
      mine.flow[id] = { state: 'queued', at: new Date().toISOString() }
      delete mine.blocks[id]
      delete mine.checkFailed[id]
    })
    const live = Boolean(card.agent) && ['working', 'blocked', 'ready', 'reviewing'].includes(card.agent.state)
    if (!live) return { status: 200, moved: 'queued' }
    try {
      const told = await deliverToCard(id, [
        '[paused]',
        'He moved this card back to Queued: he is not reviewing it now. In this turn:',
        '1. Stop the difit comment monitor (TaskStop).',
        "2. Save every difit server's threads as the difit skill's Keeping threads alive says, then stop those servers and the app (august-app stop --worktree=<worktree>), so the next review press restores them.",
        '3. task-set.cjs --state ready --doing "paused, review again to resume". Leave the materials as they are, so his review press still opens them.',
        'His next review press arrives as [reviewing] and starts everything again.'
      ].join('\n'))
      return { status: 200, moved: 'queued', delivery: told.delivery || null, ...(told.error ? { agentError: told.error } : {}) }
    } catch (error) {
      return { status: 200, moved: 'queued', agentError: error.message }
    }
  },
  '/api/block': async ({ id, reason }) => {
    const { state } = buildState()
    const card = state.cards[id]
    if (!card) return { status: 404, error: `no card ${id}` }
    const why = (reason || '').trim().split('\n')[0]
    if (!why) return { status: 400, error: 'reason missing: say in a line what it is blocked on' }
    const at = new Date().toISOString()
    updateMine((mine) => {
      mine.blocks[id] = { reason: why, at }
      delete mine.flow[id]
      mine.comments[id] = [...(mine.comments[id] || []), { at, text: `Blocked: ${why}` }]
    })
    const messageId = crypto.randomUUID()
    return deliveryReply(await tellAssistant(`[blocked] ${id} ${why}`, messageId), messageId)
  },
  '/api/unblock': async ({ key, why }) => {
    if (!readMine().blocks[key]) return { status: 404, error: `${key} is not blocked` }
    if (!(why || '').trim()) return { status: 400, error: 'why missing: say why the block no longer holds' }
    const at = new Date().toISOString()
    updateMine((mine) => {
      delete mine.blocks[key]
      mine.comments[key] = [...(mine.comments[key] || []), { at, text: `Unblocked: ${why.trim()}` }]
    })
    return { status: 200 }
  },
  '/api/day': async ({ action, hour, id, title }) => {
    if (!['add', 'remove', 'title'].includes(action) || !Number.isInteger(hour) || hour < 0 || hour > 23) return { status: 400, error: 'action or hour wrong' }
    updateMine((mine) => {
      if (!mine.day || mine.day.date !== today()) mine.day = { date: today(), hours: {} }
      const entry = mine.day.hours[hour] || { title: '', cards: [] }
      if (action === 'add' && id && !entry.cards.includes(id)) entry.cards.push(id)
      if (action === 'remove') entry.cards = entry.cards.filter((candidate) => candidate !== id)
      if (action === 'title') entry.title = title || ''
      mine.day.hours[hour] = entry
    })
  },
  '/api/asked': async ({ id, reviewer, asked }) => {
    if (!id || !reviewer) return { status: 400, error: 'id or reviewer missing' }
    updateMine((mine) => {
      const marks = mine.asked[id] || {}
      if (asked) marks[loginOf(reviewer)] = typeof asked === 'string' ? asked : new Date().toISOString()
      else delete marks[loginOf(reviewer)]
      mine.asked[id] = marks
    })
  },
  '/api/snooze': async ({ id, undo }) => {
    updateMine((mine) => {
      if (undo) delete mine.snoozed[id]
      else mine.snoozed[id] = today()
    })
  },
  '/api/dismiss': async ({ id, undo }) => {
    updateMine((mine) => {
      if (undo) delete mine.dismissed[id]
      else mine.dismissed[id] = new Date().toISOString()
    })
  },
  '/api/order': async ({ list, ids }) => {
    if (!list || !Array.isArray(ids)) return { status: 400, error: 'list or ids missing' }
    const placement = readJson(placementPath, { date: today(), lists: {}, traces: {} })
    if (placement.lists[list]) {
      const known = placement.lists[list]
      placement.lists[list] = [...ids.filter((id) => known.includes(id)), ...known.filter((id) => !ids.includes(id))]
      if (mergeKeys.includes(list)) placement.manual = { ...(placement.manual || {}), [list]: { ids: placement.lists[list], signature: ((placement.computed || {})[list] || []).join(',') } }
      writeJson(placementPath, placement)
      return
    }
    updateMine((mine) => {
      mine.order[list] = ids
    })
  },
  '/api/complete': async ({ id, complete }) => {
    const { state } = buildState()
    const card = state.cards[id]
    if (!card) return { status: 404, error: `no card ${id}` }
    if (/^task:\d+$/.test(id)) {
      updateProjects((projects) => {
        projects.tasks[id].done = complete !== false
        if (complete === false) delete projects.tasks[id].doneAt
        else projects.tasks[id].doneAt = new Date().toISOString()
      })
      return
    }
    updateMine((mine) => {
      mine.completed = mine.completed || {}
      if (complete === false) delete mine.completed[id]
      else mine.completed[id] = { at: new Date().toISOString(), checks: card.checks || null, waits: card.waits || null, agentState: card.agent ? card.agent.state : null }
    })
  },
  '/api/task-explanation': async ({ id, explanation }) => {
    if (!readProjects().tasks[id]) return { status: 404, error: 'no by-hand task with this id' }
    updateProjects((projects) => {
      projects.tasks[id].explanation = explanation || null
    })
  },
  '/api/task-context': async ({ id, caption, file, kind, clear }) => {
    if (!readProjects().tasks[id]) return { status: 404, error: 'no by-hand task with this id' }
    if (!clear && !file) return { status: 400, error: 'file missing' }
    const directory = path.join(tasksDirectory, 'by-hand', id.replace(':', '-'))
    if (file && !insideOf(directory, file)) return { status: 400, error: `put the file in ${directory} first; file is the path relative to it` }
    const shown = kind || (/\.(mp4|mov|webm|m4v)$/i.test(file || '') ? 'video' : 'image')
    updateProjects((projects) => {
      const kept = clear ? [] : projects.tasks[id].context || []
      projects.tasks[id].context = file ? [...kept, { caption: caption || null, file, kind: shown }] : kept
    })
    return { status: 200, directory }
  },
  '/api/task': async ({ project, title, explanation }) => {
    if (!title) return { status: 400, error: 'title missing' }
    const id = updateProjects((projects) => {
      const name = project || 'Misc'
      let target = projects.projects.find((candidate) => candidate.name === name)
      if (!target) {
        target = { name, done: 0, total: 0, due: null, pulls: [], tickets: [], tasks: [] }
        projects.projects.push(target)
      }
      const taskId = `task:${projects.nextTask}`
      projects.nextTask += 1
      projects.tasks[taskId] = { id: taskId, title, project: name, size: null, ticket: null, done: false, added: new Date().toISOString(), agent: null, explanation: explanation || null }
      target.tasks.push(taskId)
      target.total += 1
      return taskId
    })
    return { status: 200, id }
  },
  '/api/comment': async ({ id, at, text, remove }) => {
    if (!id) return { status: 400, error: 'id missing' }
    if (!remove && !(text || '').trim()) return { status: 400, error: 'text missing' }
    const found = updateMine((mine) => {
      const kept = mine.comments[id] || []
      if (at && !kept.some((comment) => comment.at === at)) return false
      const changed = remove ? kept.filter((comment) => comment.at !== at) : at ? kept.map((comment) => comment.at === at ? { at, text: text.trim() } : comment) : [...kept, { at: new Date().toISOString(), text: text.trim() }]
      if (changed.length) mine.comments[id] = changed
      else delete mine.comments[id]
      return true
    })
    if (!found) return { status: 404, error: 'no comment written at that time on this card' }
  },
  '/api/tracker': async ({ name, undo }) => {
    if (!['water', 'stood'].includes(name)) return { status: 400, error: 'name must be water or stood' }
    updateMine((mine) => {
      const marks = (mine.trackers[name] || []).filter(isToday)
      mine.trackers[name] = undo ? marks.slice(0, -1) : [...marks, new Date().toISOString()]
    })
  },
  '/api/log': async ({ text, from, card, images }) => {
    const pictures = [].concat(images || []).map((image) => /^data:image\/(png|jpeg|gif|webp);base64,(.+)$/.exec(String(image)))
    if (pictures.some((picture) => !picture)) return { status: 400, error: 'images must be png, jpeg, gif or webp data urls' }
    const decoded = pictures.map((picture) => ({ extension: picture[1] === 'jpeg' ? 'jpg' : picture[1], bytes: Buffer.from(picture[2], 'base64') }))
    if (decoded.some((picture) => picture.bytes.length > 10 * 1024 * 1024)) return { status: 413, error: 'an image is over 10 MB' }
    if (!text && !decoded.length) return { status: 400, error: 'text missing' }
    const ids = [].concat(card || [])
    const titles = ids.length ? buildState().state.cards : {}
    const references = ids.map((id) => `re: ${(titles[id] && titles[id].title) || id} (${id})`)
    const at = new Date().toISOString()
    fs.mkdirSync(logImagesDirectory, { recursive: true })
    const names = decoded.map((picture, index) => {
      const name = `${at.replace(/[:.]/g, '-')}-${index + 1}.${picture.extension}`
      fs.writeFileSync(path.join(logImagesDirectory, name), picture.bytes)
      return name
    })
    const entry = { at, from: from || 'me', text: [text || '', ...references].join('\n').trim(), ...(ids.length ? { card: ids } : {}), ...(names.length ? { images: names } : {}) }
    appendLine(logPath, entry)
    if (entry.from !== 'me') return { status: 200 }
    const messageId = crypto.randomUUID()
    const imageLine = names.length ? `\nimages: ${names.map((name) => path.join(logImagesDirectory, name)).join(' ')}` : ''
    return deliveryReply(await tellAssistant(`[log] ${entry.text}${imageLine}`, messageId), messageId)
  },
  '/api/outbox-ack': async ({ sessionId, id, at, text }) => {
    if (!sessionId || !(id || at || text)) return { status: 400, error: 'sessionId and one of id, at or text needed' }
    const matches = (entry) => entry.sessionId === sessionId && ((Boolean(id) && entry.id === id) || (Boolean(at) && entry.at === at) || (Boolean(text) && entry.text === text))
    const entries = readLines(outboxPath)
    const removed = entries.filter(matches)
    const now = Date.now()
    if (id) acknowledged.set(id, now)
    removed.forEach((entry) => { if (entry.id) acknowledged.set(entry.id, now) })
    if (!removed.length) return { status: 404, error: 'nothing queued for that session matches' }
    writeLines(outboxPath, entries.filter((entry) => !matches(entry)))
    return { status: 200, removed: removed.length }
  },
  '/api/answer': async ({ id, text, options }) => {
    const { state, sources } = buildState()
    const task = sources[id] && sources[id].task
    if (!task || !task.question) return { status: 404, error: 'no question on this card' }
    const chosen = Array.isArray(options) ? options : []
    const fresh = readJson(taskPathOf(task), task)
    const recorded = fresh.question && fresh.question.answer
    if (recorded && recorded.text === (text || '') && JSON.stringify(recorded.options || []) === JSON.stringify(chosen)) return { delivery: 'delivered', duplicate: true }
    fresh.question = { ...fresh.question, answer: { text: text || '', options: chosen, at: new Date().toISOString() } }
    writeJson(taskPathOf(task), fresh)
    appendLine(answersPath, { at: fresh.question.answer.at, id, title: state.cards[id].title, question: fresh.question.text, text: text || '', options: chosen })
    return deliverToCard(id, `[answer] ${text || ''}${chosen.length ? `\nOptions: ${chosen.join(', ')}` : ''}`)
  },
  '/api/agent': async ({ id, kind, note }) => startAgent(id, kind, note || ''),
  '/api/open': async ({ id }) => deliverToCard(id, '[open review]'),
  '/api/send': async ({ id }) => deliverToCard(id, '[comments sent]'),
  '/api/publish': async ({ id, description }) => {
    const { sources } = buildState()
    const source = sources[id]
    if (source && source.pull && source.pull.author !== me) return { status: 409, error: 'a review is published from difit: write accept:, changes: or comment: in difit and press send comments' }
    return deliverToCard(id, `[publish]\n${description || ''}`)
  },
  '/api/merge': async ({ id }) => {
    const { sources } = buildState()
    const pull = sources[id] && sources[id].pull
    if (!pull || pull.author !== me) return { status: 404, error: 'not one of your open pull requests' }
    const checkout = path.join(home, 'Projects', pull.repository)
    run('gh', ['pr', 'merge', String(pull.number), '--merge', '--repo', `${owner}/${pull.repository}`], checkout)
    run('git', ['push', 'origin', '--delete', pull.head], checkout)
    refresh()
    return { status: 200 }
  },
  '/api/terminal': async ({ id, session, assistant }) => {
    if (assistant || id === assistantTaskId) {
      const recorded = readMine().assistant
      if (!recorded || !recorded.sessionId) return { status: 409, error: 'no assistant session is recorded' }
      await listAgents()
      const listed = agentsList.find((agent) => agent.sessionId === recorded.sessionId)
      const command = listed ? `claude attach ${listed.id || listed.sessionId}` : `claude --resume ${recorded.sessionId} --autocompact 300000 --settings '{"autoCompactEnabled":true}'`
      openTerminal(notesDirectory, command, 'assistant')
      return { status: 200, command }
    }
    if (session) {
      await listAgents()
      const named = agentsList.find((agent) => agent.kind === 'background' && agent.name === session)
      if (!named) return { status: 409, error: `no session named ${session}` }
      const attach = `claude attach ${named.id || named.sessionId}`
      openTerminal(named.cwd, attach, named.name)
      return { status: 200, command: attach }
    }
    const { state, sources } = buildState()
    const source = sources[id]
    const agent = source && ((source.task && source.task.agent) || (source.byHand && source.byHand.agent))
    await listAgents()
    const listed = listedAgentOf(agent)
    if (!listed && !(agent && agent.sessionId)) return { status: 409, error: 'no agent session on this card' }
    const directory = (source.task && source.task.worktree) || (listed && listed.cwd) || path.join(home, 'Projects', source.repository)
    const command = listed ? `claude attach ${listed.id || listed.sessionId}` : `claude --resume ${agent.sessionId}`
    openTerminal(directory, command, (listed && listed.name) || agent.session || state.cards[id].title)
    return { status: 200, command }
  },
  '/api/refresh': async () => {
    const result = await refresh()
    return { status: result.code === 0 ? 200 : 500, output: result.output.trim().split('\n').slice(-3).join('\n') }
  }
}

const readBody = (request) =>
  new Promise((resolve, reject) => {
    let body = ''
    request.on('data', (chunk) => {
      body += chunk
      if (body.length > 60000000) request.destroy()
    })
    request.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {})
      } catch (error) {
        reject(error)
      }
    })
    request.on('error', reject)
  })

const sendJson = (response, status, value) => response.writeHead(status, { 'content-type': contentTypes['.json'], 'cache-control': 'no-store' }).end(JSON.stringify(value))

const sendFile = (request, response, file) => {
  const size = fs.statSync(file).size
  const type = contentTypes[path.extname(file).toLowerCase()] || 'application/octet-stream'
  const range = /^bytes=(\d*)-(\d*)$/.exec(request.headers.range || '')
  if (range && (range[1] || range[2])) {
    const start = range[1] ? Number(range[1]) : Math.max(0, size - Number(range[2]))
    const end = range[1] && range[2] ? Math.min(Number(range[2]), size - 1) : size - 1
    if (start > end || start >= size) {
      response.writeHead(416, { 'content-range': `bytes */${size}` }).end()
      return
    }
    response.writeHead(206, { 'content-type': type, 'content-length': end - start + 1, 'content-range': `bytes ${start}-${end}/${size}`, 'accept-ranges': 'bytes', 'cache-control': 'no-store' })
    fs.createReadStream(file, { start, end }).pipe(response)
    return
  }
  response.writeHead(200, { 'content-type': type, 'content-length': size, 'accept-ranges': 'bytes', 'cache-control': 'no-store' })
  fs.createReadStream(file).pipe(response)
}

const insideOf = (directory, relative) => {
  const file = path.resolve(directory, relative)
  if (!file.startsWith(directory + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) return null
  const real = fs.realpathSync(file)
  return real.startsWith(fs.realpathSync(directory) + path.sep) ? real : null
}

const server = http.createServer(async (request, response) => {
  const url = new URL(request.url, 'http://localhost')
  try {
    if (request.method === 'POST' && url.pathname.startsWith('/api/')) {
      const origin = request.headers.origin
      if (origin && new URL(origin).host !== request.headers.host) {
        response.writeHead(403).end('other origin')
        return
      }
      const handler = handlers[url.pathname]
      if (!handler) {
        sendJson(response, 404, { error: 'no such call' })
        return
      }
      let body
      try {
        body = await readBody(request)
      } catch (error) {
        sendJson(response, 400, { error: 'not JSON' })
        return
      }
      const result = (await handler(body)) || { status: 200 }
      const { status, ...rest } = result
      sendJson(response, status || 200, { ok: (status || 200) < 400, ...rest })
      return
    }
    if (request.method !== 'GET') {
      response.writeHead(405).end()
      return
    }
    if (url.pathname === '/api/state') {
      const returning = Date.now() - lastPolled >= watchedMilliseconds
      lastPolled = Date.now()
      if (returning && Date.now() - lastRefreshStarted >= refreshMilliseconds) syncTick()
      sendJson(response, 200, buildState().state)
      return
    }
    if (url.pathname.startsWith('/log-images/')) {
      const file = insideOf(logImagesDirectory, decodeURIComponent(url.pathname.slice('/log-images/'.length)))
      if (!file) {
        response.writeHead(404).end('not found')
        return
      }
      sendFile(request, response, file)
      return
    }
    if (url.pathname.startsWith('/files/')) {
      const file = insideOf(tasksDirectory, decodeURIComponent(url.pathname.slice('/files/'.length)))
      if (!file) {
        response.writeHead(404).end('not found')
        return
      }
      sendFile(request, response, file)
      return
    }
    const file = insideOf(pageDirectory, url.pathname === '/' ? 'index.html' : decodeURIComponent(url.pathname.slice(1)))
    if (!file) {
      response.writeHead(404).end('not found')
      return
    }
    sendFile(request, response, file)
  } catch (error) {
    console.log(`${request.method} ${url.pathname} failed: ${error.stack}`)
    if (!response.headersSent) sendJson(response, 500, { error: error.message })
  }
})

fs.mkdirSync(workDirectory, { recursive: true })
if (!fs.existsSync(configPath)) writeJson(configPath, { autostart: false, maxAutoAgents: 3, assistant: true })
readProjects()
migrateSectionNames()
server.listen(port, '127.0.0.1', () => {
  console.log(`work page on http://localhost:${port}${dryRun ? ' (dry run)' : ''}`)
  listAgents()
  setInterval(listAgents, 20000)
  const lastSync = readLines(syncsPath).slice(-1)[0]
  if (lastSync && lastSync.paused) {
    pausedUntil = Date.parse(lastSync.paused)
    pauseMinutes = lastSync.pauseMinutes || firstPauseMinutes
  }
  syncTick()
  setInterval(syncTick, refreshMilliseconds)
  setInterval(() => drainOutbox().catch((error) => console.log(`outbox: ${error.message}`)), outboxMilliseconds)
})
process.on('SIGTERM', () => {
  console.log('stopping: finishing open requests')
  server.close(() => process.exit(0))
  server.closeIdleConnections()
  setTimeout(() => process.exit(0), 60000).unref()
})
