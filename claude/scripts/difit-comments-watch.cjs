const fs = require('fs')
const path = require('path')

const usage = 'usage: node difit-comments-watch.cjs <task directory> [port ...]'
const taskDirectory = process.argv[2]
if (!taskDirectory || !fs.existsSync(taskDirectory)) {
  console.error(usage)
  process.exit(2)
}
const givenPorts = process.argv.slice(3).filter((argument) => /^\d+$/.test(argument))
const seenPath = path.join(taskDirectory, 'difit-comments-seen.json')
const pollMilliseconds = 3000
const goneLimit = 5

const readSeen = () => {
  try {
    return new Set(JSON.parse(fs.readFileSync(seenPath, 'utf8')).seen || [])
  } catch (error) {
    return new Set()
  }
}

const writeSeen = (seen) => {
  const temporaryPath = `${seenPath}.tmp`
  fs.writeFileSync(temporaryPath, JSON.stringify({ seen: [...seen] }, null, 2))
  fs.renameSync(temporaryPath, seenPath)
}

const portsOf = () => {
  const ports = new Set(givenPorts)
  for (const name of fs.readdirSync(taskDirectory)) {
    if (!name.endsWith('difit.json')) continue
    try {
      const server = JSON.parse(fs.readFileSync(path.join(taskDirectory, name), 'utf8'))
      const port = server.url ? new URL(server.url).port : server.port
      if (port) ports.add(String(port))
    } catch (error) {
      continue
    }
  }
  return [...ports]
}

const threadsOf = async (port) => {
  const response = await fetch(`http://localhost:${port}/api/comments-json`, { cache: 'no-store', signal: AbortSignal.timeout(5000) })
  if (!response.ok) throw new Error(`answered ${response.status}`)
  const body = await response.json()
  return body.threads || []
}

const oneLine = (text) => String(text || '').replace(/\s*\n\s*/g, ' / ').trim()

const placeOf = (thread) => {
  const position = thread.position || {}
  return `${thread.filePath}:${position.line}${position.side === 'old' ? ' (old side)' : ''}`
}

const announce = (port, thread, seen) => {
  const messages = thread.messages || []
  const lastClaude = messages.map((message) => message.author).lastIndexOf('claude')
  messages.forEach((message, index) => {
    if (message.author === 'claude') return
    const key = `${message.id}@${message.updatedAt}`
    if (seen.has(key)) return
    const editedId = [...seen].some((seenKey) => seenKey.startsWith(`${message.id}@`))
    seen.add(key)
    if (index < lastClaude && !editedId) return
    const kind = editedId ? 'edited' : index === 0 ? 'new thread' : 'reply'
    console.log(`difit ${port} ${placeOf(thread)} ${kind}: ${oneLine(message.body)}`)
  })
}

const main = async () => {
  const seen = readSeen()
  let goneRounds = 0
  while (true) {
    const ports = portsOf()
    let answered = 0
    let changed = false
    for (const port of ports) {
      try {
        const threads = await threadsOf(port)
        answered += 1
        for (const thread of threads) {
          const sizeBefore = seen.size
          announce(port, thread, seen)
          if (seen.size !== sizeBefore) changed = true
        }
      } catch (error) {
        continue
      }
    }
    if (changed) writeSeen(seen)
    goneRounds = answered ? 0 : goneRounds + 1
    if (goneRounds >= goneLimit || !ports.length) {
      console.log(`difit comment watch ended: no difit server answers${ports.length ? ` on ${ports.join(', ')}` : ` (no *difit.json in ${taskDirectory})`}`)
      return
    }
    await new Promise((resolve) => setTimeout(resolve, pollMilliseconds))
  }
}

main()
