const fs = require('node:fs')
const path = require('node:path')

const directory = path.resolve(process.argv[2] || '.')
const proof = JSON.parse(fs.readFileSync(path.join(directory, 'proof.json'), 'utf8'))
const sections = proof.sections || [{ criteria: proof.criteria }]
proof.criteria = sections.flatMap((section) => section.criteria)

const mediaTypes = { '.mp4': 'video/mp4', '.webm': 'video/webm', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif' }
const statusLabels = { shown: 'shown', failed: 'failed', 'not shown': 'not shown' }

const escapeHtml = (value) =>
  String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')

const base64 = (file) => fs.readFileSync(path.join(directory, file)).toString('base64')
const mediaType = (file) => mediaTypes[path.extname(file).toLowerCase()]
const clock = (seconds) => `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, '0')}`

let videoCount = 0

function renderImage({ file, caption }) {
  return `<figure><img loading="lazy" src="data:${mediaType(file)};base64,${base64(file)}" alt="${escapeHtml(caption)}"><figcaption>${escapeHtml(caption)}</figcaption></figure>`
}

const criteriaCiting = (name) =>
  proof.criteria
    .map((criterion, index) => ({ criterion, number: index + 1 }))
    .filter(({ criterion }) => (criterion.evidence || []).some((evidence) => evidence.walkthrough === name))
    .map(({ number }) => number)

const walkthroughNames = [
  ...new Set(proof.criteria.flatMap((criterion) => (criterion.evidence || []).map((evidence) => evidence.walkthrough).filter(Boolean))),
]

function renderWalkthrough(name) {
  const recorded = JSON.parse(fs.readFileSync(path.join(directory, `${name}.walkthrough.json`), 'utf8'))
  const videoId = `video-${videoCount++}`
  const shows = criteriaCiting(name)
  const steps = recorded.steps
    .map(
      (step) =>
        `<li><button type="button" data-video="${videoId}" data-start="${step.startSeconds}"><span class="time">${clock(step.startSeconds)}</span>${escapeHtml(step.caption)}</button></li>`,
    )
    .join('')
  const screenshots = recorded.steps
    .filter((step) => step.screenshot)
    .map((step, index) => renderImage({ file: step.screenshot, caption: `${index + 1}. ${step.caption} (${step.url})` }))
    .join('')
  const failure = recorded.failure ? `<p class="failure">The walkthrough stopped: ${escapeHtml(recorded.failure)}</p>` : ''
  return `<section class="walkthrough" id="recording-${escapeHtml(name)}">
  <h2>${escapeHtml(recorded.steps[0]?.caption || name)}</h2>
  <p class="how">Shows ${shows.length === 1 ? 'criterion' : 'criteria'} ${shows.join(', ')}</p>
  <video id="${videoId}" controls playsinline muted preload="metadata"></video>
  <script type="application/octet-stream" data-for="${videoId}" data-type="${mediaType(recorded.video)}">${base64(recorded.video)}</script>
  <ol class="steps">${steps}</ol>
  ${failure}
  <details><summary>${recorded.steps.length} screenshots, ${clock(recorded.durationSeconds)} recording</summary>${screenshots}</details>
</section>`
}

function renderEvidence(evidence) {
  if (evidence.walkthrough) return `<p><a href="#recording-${escapeHtml(evidence.walkthrough)}">Shown in the recording above</a></p>`
  if (evidence.image) return renderImage({ file: evidence.image, caption: evidence.caption })
  return `<div class="text"><p class="label">${escapeHtml(evidence.label)}</p><pre>${escapeHtml(evidence.text)}</pre></div>`
}

function renderCriterion(criterion, index) {
  const status = statusLabels[criterion.status] ? criterion.status : 'not shown'
  return `<section class="criterion">
  <h2><span class="status ${status.replace(' ', '-')}">${statusLabels[status]}</span>${index + 1}. ${escapeHtml(criterion.criterion)}</h2>
  <p class="how">${escapeHtml(criterion.how)}</p>
  ${(criterion.evidence || []).map(renderEvidence).join('\n')}
</section>`
}

function renderTryIt(tryIt) {
  if (!tryIt) return ''
  const command = tryIt.command ? `<pre>${escapeHtml(tryIt.command)}</pre>` : ''
  const url = tryIt.url ? `<p><a href="${escapeHtml(tryIt.url)}">${escapeHtml(tryIt.url)}</a></p>` : ''
  const note = tryIt.note ? `<p class="how">${escapeHtml(tryIt.note)}</p>` : ''
  const steps = (tryIt.steps || [])
    .map((step, index) => {
      const stepUrl = step.url ? `<p><a href="${escapeHtml(step.url)}" target="_blank" rel="noopener">${escapeHtml(step.url)}</a></p>` : ''
      const stepCommand = step.command
        ? `<div class="command"><pre>${escapeHtml(step.command)}</pre><button type="button" class="copy" data-copy="${escapeHtml(step.command)}">Copy</button></div>`
        : ''
      const expect = step.expect ? `<p class="how">Expect: ${escapeHtml(step.expect)}</p>` : ''
      return `<li><label><input type="checkbox" data-step="${index}"><span>${escapeHtml(step.do)}</span></label>${stepUrl}${stepCommand}${expect}</li>`
    })
    .join('')
  const list = steps ? `<ol class="try-steps">${steps}</ol>` : ''
  return `<section class="try-it"><h2>Try it</h2>${command}${url}${note}${list}</section>`
}

function renderSections() {
  const rendered = new Set()
  let firstNumber = 0
  return sections
    .map((section) => {
      const names = walkthroughNames.filter(
        (name) => !rendered.has(name) && section.criteria.some((criterion) => (criterion.evidence || []).some((evidence) => evidence.walkthrough === name)),
      )
      names.forEach((name) => rendered.add(name))
      const heading = section.title
        ? `<h2 class="section-title">${escapeHtml(section.title)}</h2>${section.summary ? `<p>${escapeHtml(section.summary)}</p>` : ''}`
        : ''
      const offset = firstNumber
      firstNumber += section.criteria.length
      return `${heading}
  ${names.map(renderWalkthrough).join('\n')}
  ${section.criteria.map((criterion, index) => renderCriterion(criterion, offset + index)).join('\n')}`
    })
    .join('\n')
}

const counts = Object.keys(statusLabels)
  .map((status) => ({ status, count: proof.criteria.filter((criterion) => criterion.status === status).length }))
  .filter(({ count }) => count > 0)
  .map(({ status, count }) => `<span class="status ${status.replace(' ', '-')}">${count} ${status}</span>`)
  .join('')

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(proof.title)}</title>
<style>
  :root { --background: #1E1E24; --surface: #26262E; --border: #3A3A45; --text: #E6E6EA; --muted: #8A8A8A; --accent: #86C9C0; --shown: #8FCB9B; --failed: #E07A7A; --not-shown: #F2C14E; }
  * { box-sizing: border-box; }
  body { margin: 0; padding: 24px 16px 64px; background: var(--background); color: var(--text); font: 16px/1.5 -apple-system, system-ui, sans-serif; }
  main { max-width: 1040px; margin: 0 auto; }
  h1 { font-size: 24px; line-height: 1.25; margin: 0 0 8px; }
  h2 { font-size: 17px; line-height: 1.35; margin: 0 0 6px; }
  h2.section-title { font-size: 21px; margin: 32px 0 8px; padding-top: 16px; border-top: 1px solid var(--border); }
  p { margin: 0 0 12px; }
  a { color: var(--accent); }
  .meta, .how, figcaption, .label { color: var(--muted); font-size: 14px; }
  .counts { margin: 12px 0 24px; }
  section { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; padding: 16px; margin: 0 0 16px; }
  .status { display: inline-block; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; padding: 2px 8px; border-radius: 999px; margin-right: 8px; color: var(--background); vertical-align: 2px; }
  .status.shown { background: var(--shown); }
  .status.failed { background: var(--failed); }
  .status.not-shown { background: var(--not-shown); }
  video, img { display: block; width: 100%; height: auto; border: 1px solid var(--border); border-radius: 6px; background: #000000; }
  .steps { list-style: none; margin: 10px 0; padding: 0; display: grid; gap: 4px; }
  .steps button { width: 100%; text-align: left; background: none; border: 1px solid transparent; border-radius: 6px; color: var(--text); font: inherit; padding: 6px 8px; cursor: pointer; }
  .steps button:hover { border-color: var(--border); }
  .steps button.current { border-color: var(--accent); }
  .time { color: var(--accent); font-variant-numeric: tabular-nums; margin-right: 10px; }
  .failure { color: var(--failed); white-space: pre-wrap; overflow-wrap: anywhere; }
  details { margin-top: 8px; }
  summary { cursor: pointer; color: var(--muted); font-size: 14px; }
  figure { margin: 12px 0 0; }
  figcaption { margin-top: 4px; overflow-wrap: anywhere; }
  .try-steps { margin: 12px 0 0; padding-left: 24px; display: grid; gap: 12px; }
  .try-steps label { display: flex; gap: 8px; align-items: baseline; cursor: pointer; }
  .try-steps li.tried > label span { color: var(--muted); text-decoration: line-through; }
  .command { display: flex; gap: 8px; align-items: flex-start; }
  .command pre { flex: 1; margin-bottom: 6px; }
  .copy { background: none; border: 1px solid var(--border); border-radius: 6px; color: var(--text); font: inherit; font-size: 13px; padding: 4px 10px; cursor: pointer; }
  .copy:hover { border-color: var(--accent); }
  pre { margin: 0 0 12px; padding: 12px; background: var(--background); border: 1px solid var(--border); border-radius: 6px; overflow-x: auto; font: 13px/1.45 ui-monospace, Menlo, monospace; white-space: pre-wrap; overflow-wrap: anywhere; }
</style>
</head>
<body>
<main>
  <h1>${escapeHtml(proof.title)}</h1>
  <p class="meta">${escapeHtml(proof.branch)} · built ${new Date().toISOString().slice(0, 16).replace('T', ' ')} UTC</p>
  <p>${escapeHtml(proof.summary)}</p>
  ${proof.context ? `<p>${escapeHtml(proof.context)}</p>` : ''}
  <p class="counts">${counts}</p>
  ${renderTryIt(proof.tryIt)}
  ${renderSections()}
</main>
<script>
  for (const data of document.querySelectorAll('script[data-for]')) {
    const bytes = Uint8Array.from(atob(data.textContent), (character) => character.charCodeAt(0))
    const video = document.getElementById(data.dataset.for)
    video.src = URL.createObjectURL(new Blob([bytes], { type: data.dataset.type }))
    video.poster = [...video.closest('.walkthrough').querySelectorAll('img')].pop()?.src || ''
  }
  for (const button of document.querySelectorAll('.steps button')) {
    button.addEventListener('click', () => {
      const video = document.getElementById(button.dataset.video)
      video.currentTime = Number(button.dataset.start)
      video.play()
    })
  }
  const triedKey = 'tried ' + document.title
  const readTried = () => {
    try { return JSON.parse(localStorage.getItem(triedKey)) || {} } catch (error) { return {} }
  }
  for (const box of document.querySelectorAll('.try-steps input')) {
    box.checked = Boolean(readTried()[box.dataset.step])
    box.closest('li').classList.toggle('tried', box.checked)
    box.addEventListener('change', () => {
      const tried = readTried()
      tried[box.dataset.step] = box.checked
      try { localStorage.setItem(triedKey, JSON.stringify(tried)) } catch (error) {}
      box.closest('li').classList.toggle('tried', box.checked)
    })
  }
  for (const button of document.querySelectorAll('.copy')) {
    button.addEventListener('click', () => {
      navigator.clipboard.writeText(button.dataset.copy).then(() => {
        button.textContent = 'Copied'
        setTimeout(() => { button.textContent = 'Copy' }, 1200)
      })
    })
  }
  for (const video of document.querySelectorAll('video')) {
    video.addEventListener('timeupdate', () => {
      const buttons = [...document.querySelectorAll('.steps button[data-video="' + video.id + '"]')]
      const current = buttons.filter((button) => Number(button.dataset.start) <= video.currentTime).pop()
      for (const button of buttons) button.classList.toggle('current', button === current)
    })
  }
</script>
</body>
</html>
`

const outputPath = path.join(directory, 'index.html')
fs.writeFileSync(outputPath, html)
console.log(`${outputPath} (${Math.round(fs.statSync(outputPath).size / 1024)} KB)`)
