const fs = require('node:fs')
const path = require('node:path')

const directory = path.join(process.env.HOME, 'Documents/notes/today')
const archive = path.join(directory, 'archive')

global.window = {}
require(path.join(directory, 'today.js'))
const planDate = global.window.TODAY.date
const now = new Date()
const pad = (number) => String(number).padStart(2, '0')
const todayDate = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`

if (planDate >= todayDate) {
  console.log(`today.js is the plan for ${planDate}; nothing to archive until a later day`)
  process.exit(0)
}

fs.mkdirSync(archive, { recursive: true })
fs.copyFileSync(path.join(directory, 'today.js'), path.join(archive, `${planDate}.js`))
fs.copyFileSync(path.join(directory, 'backlog.js'), path.join(archive, `${planDate}.backlog.js`))
console.log(`archived the plan for ${planDate} to archive/${planDate}.js and its backlog to archive/${planDate}.backlog.js; today.js can now be rewritten`)
