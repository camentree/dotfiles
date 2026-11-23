const childProcess = require('node:child_process')
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
const outboxPath = path.join(workDirectory, 'outbox.jsonl')
const configPath = path.join(workDirectory, 'config.json')
const taskSetScript = path.join(__dirname, 'task-set.cjs')
const workStateScript = path.join(__dirname, 'work-state.cjs')
const nixProfile = path.join('/etc/profiles/per-user', os.userInfo().username, 'bin')
const childEnvironment = { ...process.env, PATH: `${nixProfile}:${process.env.PATH || ''}` }

const me = 'camentree'
const owner = 'augusthealth'
const names = { camentree: 'you', jessebutterfield: 'Jesse', jkjustjoshing: 'Josh', naomigelfand: 'Naomi', ytolstyk: 'Yuri' }
const sizeWords = { 'x-small': 'under an hour', small: 'about an hour', medium: 'a couple of hours', large: 'a day', 'x-large': 'several days' }
const sectionNames = ['Answer', 'Merge', 'Review', 'Respond', 'Ask', 'Agent work']
const buttonOrder = ['merge', 'agent', 'open', 'send', 'publish', 'start', 'snooze', 'dismiss']
const skippedStreams = ['Reviews', 'Tooling']
const firstHour = 8
const lastHour = 18
const refreshMilliseconds = 2 * 60 * 1000
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
const emptyMine = () => ({ ticks: {}, day: { date: today(), hours: {} }, asked: {}, snoozed: {}, dismissed: {}, order: {}, trackers: { water: [], stood: [] }, assistant: null, autostarted: {} })
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
const listAgents = async () => {
  const { code, output } = await runClaude(['agents', '--json'], home)
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

const startSession = async ({ cwd, model, name, prompt, addDirectories }) => {
  const extraDirectories = (addDirectories || []).flatMap((directory) => ['--add-dir', directory])
  const withDirectories = await runClaude(['--bg', '--permission-mode', 'auto', '--model', model, ...extraDirectories, '-n', name, prompt], cwd)
  const untrusted = extraDirectories.length > 0 && /Added folder not trusted/.test(withDirectories.output)
  const { output } = untrusted ? await runClaude(['--bg', '--permission-mode', 'auto', '--model', model, '-n', name, prompt], cwd) : withDirectories
  const match = /backgrounded · ([0-9a-f]+)/.exec(output)
  if (!match) throw new Error(`session did not start: ${output.trim().slice(-300)}`)
  if (dryRun) return { shortId: match[1], sessionId: `dry-${match[1]}` }
  const list = (await listAgents()) || []
  const listed = list.find((agent) => agent.id === match[1])
  return { shortId: match[1], sessionId: listed ? listed.sessionId : match[1] }
}

const deliver = async ({ sessionId, text, cwd }) => {
  const queued = readLines(outboxPath).some((entry) => entry.sessionId === sessionId)
  const list = (await listAgents()) || []
  const running = list.find((agent) => agent.sessionId === sessionId)
  const assistant = readMine().assistant
  const isAssistant = Boolean(assistant) && assistant.sessionId === sessionId
  if (running && running.kind === 'background' && running.status === 'busy' && !isAssistant && readConfig().assistant) {
    await tellAssistant(`[relay ${running.name}] ${text}`)
    return 'relayed through the assistant'
  }
  if (queued || (running && (running.status === 'busy' || running.kind !== 'background'))) {
    appendLine(outboxPath, { sessionId, text, cwd, at: new Date().toISOString() })
    return 'queued'
  }
  const directory = running ? running.cwd : cwd
  if (running) {
    await runClaude(['stop', running.id], directory)
    await wait(1500)
  }
  const { code, output } = await runClaude(['--bg', '--resume', sessionId, text], directory)
  if (code !== 0 || !/backgrounded/.test(output) || /started a copy/.test(output)) throw new Error(`delivery failed: ${output.trim().slice(-300)}`)
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
      try {
        await deliver(entry)
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
  return { state, doing: waitingForApproval ? 'needs an approval in its terminal' : task.agent.doing, since: task.agent.since, session: task.agent.session, sessionId: task.agent.sessionId }
}
const taskFields = (task) => ({
  explanation: task ? task.explanation : null,
  decisions: task ? task.decisions || [] : [],
  findings: task ? task.findings || [] : [],
  proof: task ? (task.proof || []).map((item) => ({ caption: item.caption, url: proofUrl(task, item.file), kind: item.kind })) : [],
  question: task && task.question ? { ...task.question, pictures: (task.question.pictures || []).map((file) => proofUrl(task, file)) } : null,
  description: task ? task.description : null,
  links: task && task.review ? (task.review.tabs || []).filter((tab) => /^https?:/.test(tab.url)).map((tab) => ({ label: tab.label.replace(/[()]/g, ''), url: tab.url })) : []
})
const blankCard = { tags: [], who: 'you', lines: null, checks: 'none', reviews: null, standing: null, waits: null, checked: false, agent: null, primary: null, buttons: [], reviewer: null, asked: null, size: null, project: null }
const pullCard = (pull, task) => ({
  ...blankCard,
  id: `${pull.repository}#${pull.number}`,
  title: pull.title,
  url: pull.url,
  tags: pull.area === 'both' ? ['backend', 'frontend'] : [pull.area],
  ref: `#${pull.number} → ${pull.stackedOn ? `#${pull.stackedOn}` : pull.base}`,
  who: nameOf(pull.author),
  opened: pull.createdAt,
  lines: pull.lines,
  checks: pull.checks,
  reviews: pull.reviewCount,
  agent: agentOf(task),
  ...taskFields(task)
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
  ...taskFields(task)
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
    agent: listed ? { state: 'working', doing: 'started', since: item.agent.since, session: item.agent.session, sessionId: item.agent.sessionId } : null,
    size: sizeWords[item.size] || item.size,
    project: item.project,
    ...taskFields(null)
  }
}

const needsAnswer = (card) => Boolean(card.question && !card.question.answer) || Boolean(card.agent && card.agent.state === 'stopped')
const withoutAgent = (card) => !card.agent || card.agent.state === 'done'
const askReviewerOf = (pull, marks) => {
  const waiting = pull.reviewers.filter((reviewer) => reviewer.status === 'ask').map((reviewer) => ({ login: reviewer.login, asked: marks[reviewer.login] || reviewer.asked || null }))
  return waiting.find((reviewer) => !reviewer.asked) || waiting[0] || null
}
const respondStanding = (pull) => {
  const others = pull.threads.people.filter((login) => login !== me).map(nameOf)
  if (pull.threads.person) return `${plural(pull.threads.person, 'thread')}${others.length ? ` from ${others.join(' and ')}` : ''}, ${ago(pull.threads.since)}`
  if (pull.threads.bot) return `${plural(pull.threads.bot, 'thread')} from the bot, ${ago(pull.threads.since)}`
  if (pull.checks === 'fail') return `checks failing, ${ago(pull.lastPush)}`
  return `${pull.notes[0] || 'needs you'}, ${ago(pull.stateSince || pull.lastPush)}`
}

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
  const lists = Object.fromEntries(sectionNames.map((name) => [name, []]))
  const place = (card, section) => {
    sectionOf[card.id] = section
    lists[section].push(card.id)
  }

  const openUrls = new Set(github.mine.map((pull) => pull.url))
  for (const pull of github.mine) {
    const task = taskOfPull(pull)
    const card = pullCard(pull, task)
    cards[card.id] = card
    sources[card.id] = { pull, task, repository: pull.repository }
    const threadCount = pull.threads.person + pull.threads.bot
    const lastActivity = Math.max(Date.parse(pull.threads.lastComment || 0) || 0, Date.parse(pull.lastPush || 0) || 0)
    const settledByAgent = Boolean(task && task.agent && task.agent.state === 'done' && !task.ready) && Date.parse(task.updated) > lastActivity && pull.checks !== 'fail'
    if (needsAnswer(card)) {
      place(card, 'Answer')
      card.standing = card.question && !card.question.answer ? `asked you ${ago(card.question.asked)} ago` : `stopped ${ago(card.agent.since || pull.stateSince)} ago`
    } else if (['accepted', 'blocked'].includes(pull.column)) {
      place(card, 'Merge')
      card.standing = `approved ${ago(pull.stateSince)} ago`
      card.waits = pull.waits
      card.buttons = ['merge']
      card.primary = 'merge'
    } else if ((pull.column === 'needs-me' || threadCount) && hidden(card.id)) {
      noteHidden(card, 'Respond')
      card.standing = 'hidden'
    } else if ((pull.column === 'needs-me' || threadCount) && settledByAgent) {
      card.standing = `an agent looked: ${task.agent.doing || 'nothing to do'}`
    } else if (pull.column === 'needs-me' || threadCount) {
      place(card, 'Respond')
      const fixesReady = task && task.ready === 'fixes'
      card.standing = fixesReady ? `fixes ready ${ago(card.agent ? card.agent.since : task.updated)} ago` : respondStanding(pull)
      const reviewingFixes = Boolean(card.agent) && card.agent.state === 'reviewing'
      card.buttons = [withoutAgent(card) && 'agent', fixesReady && !reviewingFixes && 'open', reviewingFixes && 'send', (fixesReady || reviewingFixes) && 'publish', 'snooze'].filter(Boolean)
      card.primary = reviewingFixes ? 'send' : fixesReady ? 'open' : null
    } else if (pull.column === 'needs-review' && !pull.draft && askReviewerOf(pull, mine.asked[card.id] || {})) {
      place(card, 'Ask')
      const reviewer = askReviewerOf(pull, mine.asked[card.id] || {})
      card.reviewer = nameOf(reviewer.login)
      card.asked = reviewer.asked
      card.standing = reviewer.asked ? `${card.reviewer}, asked ${ago(reviewer.asked)} ago` : `${card.reviewer}, not asked`
    } else {
      card.standing = pull.notes[0] || pull.column.replace(/-/g, ' ')
    }
  }

  for (const pull of github.teammates) {
    const task = taskOfPull(pull)
    const card = pullCard(pull, task)
    sources[card.id] = { pull, task, repository: pull.repository }
    if (needsAnswer(card)) {
      cards[card.id] = card
      place(card, 'Answer')
      card.standing = card.question && !card.question.answer ? `asked you ${ago(card.question.asked)} ago` : `stopped ${ago(card.agent.since || pull.stateSince)} ago`
      continue
    }
    if (!pull.needsMe) continue
    if (hidden(card.id)) {
      noteHidden(card, 'Review')
      continue
    }
    cards[card.id] = card
    place(card, 'Review')
    const reviewReady = task && task.ready === 'review'
    card.standing = `waiting on you ${ago(pull.stateSince)}`
    const reviewing = Boolean(card.agent) && card.agent.state === 'reviewing'
    card.buttons = [withoutAgent(card) && 'agent', reviewReady && !reviewing && 'open', reviewing && 'send', reviewing && 'publish', 'snooze', 'dismiss'].filter(Boolean)
    card.primary = reviewing ? 'send' : reviewReady ? 'open' : null
  }

  for (const task of tasks) {
    if (task.pull && !openUrls.has(task.pull)) continue
    if (task.pull || task.kind !== 'mine' || (task.agent && task.agent.state === 'done' && !task.ready)) continue
    const card = taskCard(task)
    cards[card.id] = card
    sources[card.id] = { task, repository: task.repo }
    if (needsAnswer(card)) {
      place(card, 'Answer')
      card.standing = card.question && !card.question.answer ? `asked you ${ago(card.question.asked)} ago` : `stopped ${ago(card.agent.since || task.updated)} ago`
    } else if (task.ready === 'work') {
      place(card, 'Agent work')
      card.standing = `ready ${ago(card.agent && card.agent.since ? card.agent.since : task.updated)} ago`
      card.buttons = ['open', 'publish', card.agent && card.agent.state === 'reviewing' && 'send'].filter(Boolean)
      card.primary = 'open'
    } else {
      card.standing = card.agent ? `${card.agent.doing || card.agent.state}, ${ago(card.agent.since || task.updated)}` : 'not started'
    }
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
        card.buttons = card.agent ? [] : ['start']
        card.primary = card.agent ? null : 'start'
        return card.id
      })
    for (const id of pullIds) cards[id].project = cards[id].project || project.name
    const openCards = [...pullIds, ...taskIds, ...byHandIds]
    const done = project.done + (project.finished || []).length
    return { name: project.name, done, total: done + openCards.length, due: project.due, cards: openCards }
  })

  for (const card of Object.values(cards)) {
    card.buttons = buttonOrder.filter((button) => card.buttons.includes(button))
    const tick = mine.ticks[card.id]
    card.checked = Boolean(tick && tick.checked && tick.section === (sectionOf[card.id] || null))
  }
  Object.values(cards).forEach((card) => {
    if (card.agent && !['done', 'stopped'].includes(card.agent.state) && !card.buttons.includes('agent')) card.buttons = [...card.buttons, 'note']
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

  const pullRow = (pull, note) => ({ id: `${pull.repository}#${pull.number}`, number: pull.number, title: pull.title, note, stack: pull.stack ? `${pull.stack.position}/${pull.stack.size}` : '', age: ago(pull.stateSince || pull.createdAt), old: daysSince(pull.stateSince || pull.createdAt) >= 4, url: pull.url })
  const inColumn = (column) => github.mine.filter((pull) => pull.column === column && !(column !== 'drafted' && pull.draft))
  const needsMeNote = (pull) => {
    const task = taskOfPull(pull)
    if (task && task.ready === 'fixes') return 'fixes ready'
    const threadCount = pull.threads.person + pull.threads.bot
    return threadCount ? plural(threadCount, 'thread') : pull.checks === 'fail' ? 'checks failing' : pull.notes[0] || ''
  }
  const reviewerNames = (pull) => pull.reviewers.filter((reviewer) => reviewer.status !== 'approved').map((reviewer) => nameOf(reviewer.login)).join(' and ')
  const agentWorkRows = lists['Agent work'].map((id) => ({ id, number: '', title: cards[id].title, note: 'agent work ready', stack: '', age: ago(cards[id].opened), old: false, url: cards[id].url }))
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

  const state = {
    updated: github.updated,
    date,
    agentsWorking: agentsList.filter((agent) => agent.kind === 'background' && agent.status === 'busy').length,
    agents: agentsList.filter((agent) => agent.kind === 'background').map((agent) => ({ name: agent.name, status: agent.status === 'waiting' ? 'needs an approval' : agent.status })),
    sections: sectionNames.map((name) => ({ name, cards: ordered(name, [...lists[name]].sort((first, second) => attention(first) - attention(second))) })),
    cards,
    day,
    projects: projects.map((project) => ({ ...project, cards: ordered(project.name, project.cards) })),
    pulls,
    log: readLines(logPath).slice(-200),
    hidden: hiddenCards,
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
    return { status: 200, delivery: await deliver({ sessionId, text: `[note] ${note}`, cwd: source.task.worktree || path.join(home, 'Projects', source.repository) }) }
  }
  const pull = source.pull
  const target = pull ? pull.url : source.byHand ? source.byHand.ticket || source.byHand.title : source.task.pull || source.task.ticket || source.task.title || source.task.branch
  const prompts = { review: `/review ${target} --prepare`, address: `/address-comments ${target} --unattended`, fix: `/fix-ci ${target}`, start: `/manage ${target}` }
  if (!prompts[kind]) return { status: 400, error: `kind must be one of ${Object.keys(prompts).join(', ')}` }
  const botsOnly = Boolean(pull) && pull.threads.person === 0 && pull.threads.bot > 0
  const models = { review: 'opus', address: botsOnly ? 'sonnet' : 'opus', fix: 'sonnet', start: 'opus' }
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
      projects.tasks[id].agent = { session: name, sessionId: started.sessionId, since: new Date().toISOString() }
    })
  } else {
    const repository = pull ? pull.repository : source.task.repo
    const branch = pull ? pull.head : source.task.branch
    const extra = source.task ? [] : ['--kind', pull.author === me ? 'mine' : 'teammate', '--pull', pull.url, '--title', pull.title, '--base', pull.base]
    childProcess.execFileSync(process.execPath, [taskSetScript, '--task', `${repository}/${branch}`, '--session', name, '--session-id', started.sessionId, '--state', 'working', '--doing', `${kind} starting`, ...extra], { encoding: 'utf8' })
  }
  console.log(`started ${kind} on ${id}: ${name} (${started.sessionId})`)
  return { status: 200, session: name, sessionId: started.sessionId }
}

const startAssistant = async () => {
  const started = await startSession({ cwd: notesDirectory, model: 'opus', name: 'assistant', prompt: '/assistant' })
  updateMine((mine) => {
    mine.assistant = { sessionId: started.sessionId, date: today(), hourly: new Date().toISOString() }
  })
  return started.sessionId
}
const assistantRunning = () => {
  const assistant = readMine().assistant
  return Boolean(assistant && assistant.sessionId) && agentsList.some((agent) => agent.sessionId === assistant.sessionId)
}
const tellAssistant = async (text) => {
  if (!readConfig().assistant) return 'assistant off'
  await listAgents()
  if (!assistantRunning()) {
    const sessionId = await startAssistant()
    appendLine(outboxPath, { sessionId, text, cwd: notesDirectory, at: new Date().toISOString() })
    return 'queued for a new assistant'
  }
  return deliver({ sessionId: readMine().assistant.sessionId, text, cwd: notesDirectory })
}
const tendAssistant = async () => {
  if (!readConfig().assistant) return
  const assistant = readMine().assistant
  if (!assistant || !assistant.sessionId) return
  if (assistant.date !== today()) {
    const listed = agentsList.find((agent) => agent.sessionId === assistant.sessionId)
    if (listed) await runClaude(['stop', listed.id], notesDirectory)
    await startAssistant()
    return
  }
  const hour = new Date().getHours()
  if (assistantRunning() && hour >= firstHour && hour <= lastHour && Date.now() - Date.parse(assistant.hourly || 0) >= hourMilliseconds) {
    updateMine((mine) => {
      mine.assistant.hourly = new Date().toISOString()
    })
    await deliver({ sessionId: assistant.sessionId, text: '[hourly]', cwd: notesDirectory })
  }
}

const autostart = async () => {
  const config = readConfig()
  if (!config.autostart) return
  const { state, github } = buildState()
  const running = Object.values(readMine().autostarted).filter((entry) => agentsList.some((agent) => agent.sessionId === entry.sessionId && agent.state !== 'done')).length
  let room = (config.maxAutoAgents || 3) - running
  for (const pull of github.mine) {
    if (room <= 0) return
    const id = `${pull.repository}#${pull.number}`
    const card = state.cards[id]
    const threadCount = pull.threads.person + pull.threads.bot
    if (!card || !withoutAgent(card) || !(threadCount || pull.checks === 'fail' || pull.conflict)) continue
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
const settleProjects = async () => {
  const github = readJson(githubPath, { mine: [] })
  const openUrls = new Set(github.mine.map((pull) => pull.url))
  const settled = (project, url) => (project.finished || []).includes(url) || (project.closed || []).includes(url)
  const gone = readProjects().projects.flatMap((project) => project.pulls.filter((url) => !openUrls.has(url) && !settled(project, url)))
  const states = {}
  for (const url of new Set(gone)) {
    try {
      states[url] = JSON.parse(run('gh', ['pr', 'view', url, '--json', 'state'], home)).state
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

const refresh = () => {
  if (refreshing) return refreshing
  refreshing = new Promise((resolve) => {
    const child = childProcess.spawn(process.execPath, [workStateScript], { env: childEnvironment, stdio: ['ignore', 'pipe', 'pipe'] })
    let output = ''
    child.stdout.on('data', (chunk) => (output += chunk))
    child.stderr.on('data', (chunk) => (output += chunk))
    child.on('error', (error) => resolve({ code: -1, output: error.message }))
    child.on('close', (code) => resolve({ code, output }))
  })
    .then(async (result) => {
      console.log(`refresh ${new Date().toISOString()}: ${result.output.trim().split('\n').slice(-3).join(' | ')}`)
      await listAgents()
      await settleProjects()
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

const run = (command, args, cwd) => {
  if (dryRun) {
    console.log(`dry run in ${cwd}: ${command} ${JSON.stringify(args)}`)
    return ''
  }
  return childProcess.execFileSync(command, args, { cwd, env: childEnvironment, encoding: 'utf8' })
}

const deliverToCard = async (id, text) => {
  const { sources } = buildState()
  const source = sources[id]
  const task = source && source.task
  await listAgents()
  const sessionId = task && sessionIdOf(task.agent)
  if (!sessionId) return { status: 409, error: 'no agent session on this card' }
  return { status: 200, delivery: await deliver({ sessionId, text, cwd: task.worktree || path.join(home, 'Projects', task.repo) }) }
}

const handlers = {
  '/api/tick': async ({ id, checked }) => {
    const { sectionOf } = buildState()
    updateMine((mine) => {
      mine.ticks[id] = { checked: Boolean(checked), section: sectionOf[id] || null }
    })
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
    updateMine((mine) => {
      mine.order[list] = ids
    })
  },
  '/api/task': async ({ project, title }) => {
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
      projects.tasks[taskId] = { id: taskId, title, project: name, size: null, ticket: null, done: false, added: new Date().toISOString(), agent: null }
      target.tasks.push(taskId)
      target.total += 1
      return taskId
    })
    return { status: 200, id }
  },
  '/api/tracker': async ({ name }) => {
    if (!['water', 'stood'].includes(name)) return { status: 400, error: 'name must be water or stood' }
    updateMine((mine) => {
      mine.trackers[name] = [...(mine.trackers[name] || []).filter(isToday), new Date().toISOString()]
    })
  },
  '/api/log': async ({ text, from }) => {
    if (!text) return { status: 400, error: 'text missing' }
    const entry = { at: new Date().toISOString(), from: from || 'me', text }
    appendLine(logPath, entry)
    if (entry.from !== 'me') return { status: 200 }
    return { status: 200, delivery: await tellAssistant(`[log] ${text}`) }
  },
  '/api/answer': async ({ id, text, options }) => {
    const { sources } = buildState()
    const task = sources[id] && sources[id].task
    if (!task || !task.question) return { status: 404, error: 'no question on this card' }
    const chosen = Array.isArray(options) ? options : []
    const fresh = readJson(taskPathOf(task), task)
    fresh.question = { ...fresh.question, answer: { text: text || '', options: chosen, at: new Date().toISOString() } }
    writeJson(taskPathOf(task), fresh)
    return deliverToCard(id, `[answer] ${text || ''}${chosen.length ? `\nOptions: ${chosen.join(', ')}` : ''}`)
  },
  '/api/agent': async ({ id, kind, note }) => startAgent(id, kind, note || ''),
  '/api/open': async ({ id }) => deliverToCard(id, '[open review]'),
  '/api/send': async ({ id }) => deliverToCard(id, '[comments sent]'),
  '/api/publish': async ({ id, description }) => deliverToCard(id, `[publish]\n${description || ''}`),
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
  '/api/terminal': async ({ id, session }) => {
    if (session) {
      await listAgents()
      const named = agentsList.find((agent) => agent.kind === 'background' && agent.name === session)
      if (!named) return { status: 409, error: `no session named ${session}` }
      const attach = `claude attach ${named.id || named.sessionId}`
      run('open', ['-na', 'Ghostty.app', '--args', `--working-directory=${named.cwd}`, '-e', '/bin/zsh', '-lic', attach], named.cwd)
      return { status: 200, command: attach }
    }
    const { sources } = buildState()
    const source = sources[id]
    const agent = source && ((source.task && source.task.agent) || (source.byHand && source.byHand.agent))
    await listAgents()
    const listed = listedAgentOf(agent)
    if (!listed && !(agent && agent.sessionId)) return { status: 409, error: 'no agent session on this card' }
    const directory = (source.task && source.task.worktree) || (listed && listed.cwd) || path.join(home, 'Projects', source.repository)
    const command = listed ? `claude attach ${listed.id || listed.sessionId}` : `claude --resume ${agent.sessionId}`
    run('open', ['-na', 'Ghostty.app', '--args', `--working-directory=${directory}`, '-e', '/bin/zsh', '-lic', command], directory)
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
      if (body.length > 1000000) request.destroy()
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
      sendJson(response, 200, buildState().state)
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
server.listen(port, '0.0.0.0', () => {
  console.log(`work page on http://localhost:${port}${dryRun ? ' (dry run)' : ''}`)
  listAgents()
  setInterval(listAgents, 20000)
  refresh()
  setInterval(refresh, refreshMilliseconds)
  setInterval(() => drainOutbox().catch((error) => console.log(`outbox: ${error.message}`)), outboxMilliseconds)
})
