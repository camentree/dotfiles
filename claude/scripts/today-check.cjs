const fs = require('node:fs')
const path = require('node:path')

const directory = path.join(process.env.HOME, 'Documents/notes/today')
const problems = []
const problem = (where, what) => problems.push(`${where}: ${what}`)

global.window = {}
for (const name of ['today.js', 'backlog.js', 'thread.js']) {
  try {
    require(path.join(directory, name))
  } catch (error) {
    problem(name, `does not load (${error.message})`)
  }
}
const boardColumns = ['needs-review', 'can-review', 'wait-to-review', 'needs-me', 'accepted', 'blocked', 'drafted']
if (fs.existsSync(path.join(directory, 'prs.js'))) {
  try {
    require(path.join(directory, 'prs.js'))
  } catch (error) {
    problem('prs.js', `does not load (${error.message}); run my-prs.cjs again`)
  }
  const prs = global.window.PRS
  if (prs && (!prs.reviewers || !Array.isArray(prs.pulls))) problem('prs.js', 'has no reviewers or pulls; run my-prs.cjs again')
  for (const pull of (prs && Array.isArray(prs.pulls) && prs.pulls) || []) {
    if (!pull.url || !pull.title || !Array.isArray(pull.needs) || !pull.needs.every((login) => pull.reviews && pull.reviews[login]) || !Array.isArray(pull.notes) || !Array.isArray(pull.dependsOn) || !Array.isArray(pull.pair) || !boardColumns.includes(pull.column)) problem('prs.js', `pull request ${pull.number} is missing fields the page reads; run my-prs.cjs again`)
  }
}
const today = global.window.TODAY
const backlog = global.window.BACKLOG
const thread = global.window.THREAD
const clock = /^\d{2}:\d{2}$/
const minutes = (value) => Number(value.slice(0, 2)) * 60 + Number(value.slice(3))
const stages = ['todo', 'dev', 'self-review', 'review', 'comments', 'approved', 'merged']
const pullUrls = (item) => (item.links || []).map((link) => link.url).filter((url) => url.includes('/pull/'))

if (backlog) {
  if (!Array.isArray(backlog.streams) || !backlog.streams.length) problem('backlog.js', 'streams is empty')
  for (const stream of backlog.streams || []) {
    const where = `backlog.js stream "${stream.name}"`
    if (!stream.name) problem('backlog.js', 'a stream has no name')
    if (!Array.isArray(stream.groups)) problem(where, 'groups is not a list')
    if (stream.project && (typeof stream.done !== 'number' || typeof stream.total !== 'number')) problem(where, 'project: true needs numeric done and total')
    for (const group of stream.groups || []) {
      for (const item of group.items || []) {
        if (!item.text) problem(where, 'an item has no text')
        if (item.stage !== undefined && !stages.includes(item.stage)) problem(where, `"${item.text}" has stage "${item.stage}", not one of ${stages.join(', ')}`)
        for (const link of item.links || []) if (!link.label || !link.url) problem(where, `"${item.text}" has a link without label or url`)
        if (stream.name === 'Reviews' && !item.summary) problem(where, `"${item.text}" has no summary (who was asked, who reviewed)`)
      }
    }
  }
}

if (today) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(today.date || '')) problem('today.js', 'date is not YYYY-MM-DD')
  if (!clock.test(today.updated || '')) problem('today.js', 'updated is not HH:MM')
  if (!Array.isArray(today.blocks) || !today.blocks.length) problem('today.js', 'blocks is empty')
  const streamNames = new Set(((backlog && backlog.streams) || []).map((stream) => stream.name))
  const ids = new Set()
  let previousEnd = 0
  const checkItem = (item, where, depth) => {
    if (!item.id || !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(item.id)) problem(where, `item id "${item.id}" is not kebab-case`)
    if (ids.has(item.id)) problem(where, `item id "${item.id}" is used twice`)
    ids.add(item.id)
    if (!item.text) problem(where, `item ${item.id} has no text`)
    if (item.stage !== undefined && !stages.includes(item.stage)) problem(where, `item ${item.id} has stage "${item.stage}", not one of ${stages.join(', ')}`)
    if (item.kind === 'break') problem(where, `item ${item.id} is a break task; water and standing are tracked in the page header`)
    if (/^Start one session/i.test(item.text || '')) problem(where, `item ${item.id} is worded as an instruction about sessions; title it as the work`)
    for (const link of item.links || []) if (!link.label || !link.url) problem(where, `item ${item.id} has a link without label or url`)
    for (const copy of item.copy || []) {
      if (!copy.label || !copy.text) problem(where, `item ${item.id} has a copy entry without label or text`)
      if (/^copy( prompt)?$/i.test((copy.label || '').trim())) problem(where, `item ${item.id} copy label does not say what is copied`)
      if (/(^|&& )claude /.test(copy.text || '') && !/^cd /.test(copy.text)) problem(where, `item ${item.id} command does not start with cd`)
      const launch = /(?:^|&& )claude\s+(\S+)/.exec(copy.text || '')
      if (launch && /^[-"']/.test(launch[1]) && !/(?:^|&& )claude --model (?:fable|opus|sonnet) /.test(copy.text)) problem(where, `item ${item.id} starts a claude session without --model fable|opus|sonnet right after claude`)
    }
    if (item.items && depth >= 1) problem(where, `item ${item.id} nests more than one level`)
    if (item.items && item.stage !== undefined) problem(where, `item ${item.id} has nested items and a stage; put the stage on its children`)
    for (const child of item.items || []) checkItem(child, where, depth + 1)
  }
  for (const block of today.blocks || []) {
    const where = `today.js block ${block.start}`
    if (!clock.test(block.start || '') || !clock.test(block.end || '')) {
      problem(where, 'start or end is not HH:MM')
      continue
    }
    if (minutes(block.end) <= minutes(block.start)) problem(where, 'ends before it starts')
    if (minutes(block.start) < previousEnd) problem(where, 'overlaps the block before it or is out of order')
    previousEnd = minutes(block.end)
    if (!block.stream) problem(where, 'has no stream')
    if (typeof block.title !== 'string') problem(where, 'title is not a string')
    if (/^slot \d/i.test(block.title || '')) problem(where, 'title is a planner label, not the work')
    if (!Array.isArray(block.items)) problem(where, 'items is not a list')
    const items = block.items || []
    if (block.stream === 'Break') {
      if (items.length) problem(where, 'a Break block has items')
    } else if (!items.length) {
      problem(where, 'has no items (meetings go in a "Meetings" block as items)')
    } else if (block.stream === 'Meeting') {
      problem(where, 'stream is "Meeting"; meetings share a "Meetings" block, one item each')
    } else if (block.stream !== 'Meetings' && !streamNames.has(block.stream)) {
      problem(where, `stream "${block.stream}" is not a stream in backlog.js`)
    }
    for (const item of items) checkItem(item, where, 0)
  }
  if (backlog) {
    const plannedUrls = new Set()
    const collect = (item) => {
      pullUrls(item).forEach((url) => plannedUrls.add(url))
      for (const child of item.items || []) collect(child)
    }
    for (const block of today.blocks || []) for (const item of block.items || []) collect(item)
    for (const stream of backlog.streams || []) {
      for (const group of stream.groups || []) {
        for (const item of group.items || []) {
          const urls = pullUrls(item)
          if (item.today && urls.length && !urls.some((url) => plannedUrls.has(url))) problem(`backlog.js stream "${stream.name}"`, `"${item.text}" is marked today but no plan item links its pull request, so ticks will not sync`)
        }
      }
    }
  }
}

if (today) {
  let state = {}
  try {
    state = JSON.parse(fs.readFileSync(path.join(directory, 'state.json'), 'utf8'))
  } catch (error) {}
  const earlierPlanDates = Object.keys(state).filter((date) => date < today.date).sort()
  const lastPlanDate = earlierPlanDates[earlierPlanDates.length - 1]
  if (lastPlanDate && !fs.existsSync(path.join(directory, 'archive', `${lastPlanDate}.js`))) problem('today.js', `is the plan for ${today.date}, but the plan for ${lastPlanDate} has no archive/${lastPlanDate}.js; run today-archive.cjs before writing a new day's plan`)
}

if (thread && !Array.isArray(thread.messages)) problem('thread.js', 'messages is not a list')

const page = path.join(directory, 'index.html')
if (!fs.existsSync(page)) problem('index.html', 'the page is missing')
else if (!fs.lstatSync(page).isSymbolicLink()) problem('index.html', 'is no longer the link to ~/Projects/dotfiles/claude/skills/today/page/index.html; someone replaced the page')

if (problems.length) {
  console.log(problems.join('\n'))
  process.exit(1)
}
console.log('today.js, backlog.js and thread.js fit the page')
