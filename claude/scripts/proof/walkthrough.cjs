const fs = require('node:fs')
const os = require('node:os')
const path = require('node:path')
const { execFileSync } = require('node:child_process')

const runtimeDirectory = path.join(os.homedir(), '.claude', 'proof-runtime')
const rehearsing = process.env.PROOF_REHEARSE === '1'

const pace = {
  keystrokeMilliseconds: 90,
  pointerTravelMilliseconds: 500,
  pointerFrameMilliseconds: 16,
  beforeClickMilliseconds: 350,
  afterActionMilliseconds: 700,
  afterNavigationMilliseconds: 1000,
  afterSeeingMilliseconds: 800,
  betweenStepsMilliseconds: 800,
  waitLimitMilliseconds: 10000,
}

function loadPlaywright() {
  try {
    return require(path.join(runtimeDirectory, 'node_modules', 'playwright'))
  } catch (error) {
    throw new Error(
      `playwright is missing. Run: npm install --prefix ${runtimeDirectory} playwright && ${runtimeDirectory}/node_modules/.bin/playwright install chromium`,
    )
  }
}

function showPointer() {
  const install = () => {
    if (!document.documentElement || document.getElementById('proof-pointer')) return
    const pointer = document.createElement('div')
    pointer.id = 'proof-pointer'
    pointer.style.cssText = [
      'position:fixed',
      'left:0',
      'top:0',
      'width:18px',
      'height:18px',
      'margin:-9px 0 0 -9px',
      'border-radius:50%',
      'background:#F2C14E',
      'border:2px solid #1E1E24',
      'opacity:0.9',
      'pointer-events:none',
      'z-index:2147483647',
      'transition:box-shadow 150ms',
    ].join(';')
    document.documentElement.appendChild(pointer)
    document.addEventListener(
      'mousemove',
      (event) => {
        pointer.style.transform = `translate(${event.clientX}px, ${event.clientY}px)`
      },
      true,
    )
    document.addEventListener(
      'mousedown',
      () => {
        pointer.style.boxShadow = '0 0 0 10px #F2C14E66'
      },
      true,
    )
    document.addEventListener(
      'mouseup',
      () => {
        pointer.style.boxShadow = 'none'
      },
      true,
    )
  }
  install()
  document.addEventListener('DOMContentLoaded', install)
}

function convertToMp4({ webmPath, mp4Path, durationSeconds }) {
  try {
    execFileSync('ffmpeg', [
      '-y',
      '-loglevel',
      'error',
      '-i',
      webmPath,
      '-t',
      String(durationSeconds + 0.5),
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-movflags',
      '+faststart',
      '-an',
      mp4Path,
    ])
    fs.rmSync(webmPath)
    return true
  } catch (error) {
    return false
  }
}

async function walkthrough({ name, directory, baseUrl, viewport = { width: 1280, height: 800 } }, script) {
  const { chromium } = loadPlaywright()
  fs.mkdirSync(directory, { recursive: true })

  const browser = await chromium.launch()
  const context = await browser.newContext({
    baseURL: baseUrl,
    viewport,
    recordVideo: rehearsing ? undefined : { dir: directory, size: viewport },
  })
  context.setDefaultTimeout(pace.waitLimitMilliseconds)
  await context.addInitScript(showPointer)
  const page = await context.newPage()
  const startedAt = Date.now()

  const pointer = { x: viewport.width / 2, y: viewport.height / 2 }
  const steps = []
  let failure = null

  const elapsedSeconds = () => Math.round((Date.now() - startedAt) / 100) / 10
  const pause = (milliseconds) => page.waitForTimeout(milliseconds)
  const rest = (milliseconds) => pause(rehearsing ? 0 : milliseconds)
  const locate = (target) => (typeof target === 'string' ? page.locator(target) : target)

  const closeStep = async () => {
    const step = steps[steps.length - 1]
    if (!step) return
    step.screenshot = `${name}-${steps.length}.png`
    step.url = page.url()
    await page.screenshot({ path: path.join(directory, step.screenshot) })
  }

  const movePointerTo = async ({ x, y }) => {
    const frames = rehearsing ? 0 : Math.round(pace.pointerTravelMilliseconds / pace.pointerFrameMilliseconds)
    for (let frame = 1; frame <= frames; frame++) {
      const eased = 1 - Math.pow(1 - frame / frames, 3)
      await page.mouse.move(pointer.x + (x - pointer.x) * eased, pointer.y + (y - pointer.y) * eased)
      await rest(pace.pointerFrameMilliseconds)
    }
    pointer.x = x
    pointer.y = y
  }

  const user = {
    page,
    pause,
    async step(caption) {
      await closeStep()
      steps.push({ caption, startSeconds: elapsedSeconds() })
      await rest(pace.betweenStepsMilliseconds)
    },
    async goTo(url) {
      await page.goto(url)
      await page.mouse.move(pointer.x, pointer.y)
      await rest(pace.afterNavigationMilliseconds)
    },
    async click(target) {
      const locator = locate(target)
      await locator.waitFor({ state: 'visible' })
      await locator.scrollIntoViewIfNeeded()
      const box = await locator.boundingBox()
      await movePointerTo({ x: box.x + box.width / 2, y: box.y + box.height / 2 })
      await rest(pace.beforeClickMilliseconds)
      await locator.click()
      await rest(pace.afterActionMilliseconds)
    },
    async type(target, text) {
      await user.click(target)
      await locate(target).pressSequentially(text, { delay: rehearsing ? 0 : pace.keystrokeMilliseconds })
      await rest(pace.afterActionMilliseconds)
    },
    async press(key) {
      await page.keyboard.press(key)
      await rest(pace.afterActionMilliseconds)
    },
    async see(text) {
      await page.getByText(text).first().waitFor({ state: 'visible' })
      await rest(pace.afterSeeingMilliseconds)
    },
  }

  try {
    await script(user)
  } catch (error) {
    failure = error.message.replace(/\u001b\[[0-9;]*m/g, '')
  }
  await closeStep()
  const durationSeconds = elapsedSeconds()

  const recording = page.video()
  await context.close()
  await browser.close()

  if (rehearsing) {
    console.log(`${name} rehearsal: ${steps.length} steps, ${durationSeconds}s, ${failure ? `FAILED: ${failure}` : 'passed'}`)
    if (failure) process.exitCode = 1
    return { name, durationSeconds, steps, failure }
  }

  const webmPath = path.join(directory, `${name}.webm`)
  fs.renameSync(await recording.path(), webmPath)
  const converted = convertToMp4({ webmPath, mp4Path: path.join(directory, `${name}.mp4`), durationSeconds })

  const result = { name, video: converted ? `${name}.mp4` : `${name}.webm`, durationSeconds, steps, failure }
  fs.writeFileSync(path.join(directory, `${name}.walkthrough.json`), JSON.stringify(result, null, 2))

  console.log(`${name}: ${steps.length} steps, ${durationSeconds}s, ${failure ? `FAILED: ${failure}` : 'completed'}`)
  if (failure) process.exitCode = 1
  return result
}

module.exports = { walkthrough }
