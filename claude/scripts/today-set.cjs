const childProcess = require('node:child_process')
const fs = require('node:fs')
const path = require('node:path')

const directory = path.join(process.env.HOME, 'Documents/notes/today')
const stages = ['todo', 'dev', 'self-review', 'review', 'comments', 'approved', 'merged']
const usage = `usage: node today-set.cjs <pull request url, ticket url, or today.js item id> [--stage ${stages.join('|')}] [--status "<what happened>"] [--next "<next step>"] [--done]`

const [key, ...flags] = process.argv.slice(2)
const changes = {}
for (let index = 0; index < flags.length; index += 1) {
  const flag = flags[index]
  if (flag === '--done') changes.done = true
  else if (['--stage', '--status', '--next'].includes(flag) && flags[index + 1] !== undefined) {
    changes[flag.slice(2)] = flags[index + 1]
    index += 1
  } else {
    console.log(usage)
    process.exit(1)
  }
}
if (!key || !Object.keys(changes).length || (changes.stage && !stages.includes(changes.stage))) {
  console.log(usage)
  process.exit(1)
}

global.window = {}
require(path.join(directory, 'today.js'))
require(path.join(directory, 'backlog.js'))
const today = global.window.TODAY
const backlog = global.window.BACKLOG

const hasLink = (item) => (item.links || []).some((link) => link.url === key)
const changed = []

const setTodayItem = (item) => {
  if (item.id === key || hasLink(item)) {
    if (changes.stage) item.stage = changes.stage
    if (changes.status) item.status = changes.status
    if (changes.done) item.done = true
    changed.push(`today.js: ${item.text}`)
  }
  for (const child of item.items || []) setTodayItem(child)
}
for (const block of today.blocks) for (const item of block.items) setTodayItem(item)

for (const stream of backlog.streams) {
  for (const group of stream.groups) {
    for (const item of group.items) {
      if (!hasLink(item)) continue
      if (changes.stage) item.stage = changes.stage
      if (changes.status) item.state = changes.status
      if (changes.next) item.next = changes.next
      changed.push(`backlog.js: ${item.text}`)
    }
  }
}

if (!changed.length) {
  console.log(`no item in today.js or backlog.js has the id or a link "${key}"`)
  process.exit(1)
}

const now = new Date()
const pad = (number) => String(number).padStart(2, '0')
const clock = `${pad(now.getHours())}:${pad(now.getMinutes())}`
today.updated = clock
backlog.updated = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${clock}`

const literal = (value) => JSON.stringify(value, null, 2).replace(/^(\s*)"([A-Za-z_$][\w$]*)":/gm, '$1$2:')
fs.writeFileSync(path.join(directory, 'today.js'), `window.TODAY = ${literal(today)};\n`)
fs.writeFileSync(path.join(directory, 'backlog.js'), `window.BACKLOG = ${literal(backlog)};\n`)

console.log(changed.join('\n'))
const check = childProcess.spawnSync('node', [path.join(__dirname, 'today-check.cjs')], { encoding: 'utf8' })
process.stdout.write(check.stdout)
process.exit(check.status)
