// Render the slide track of the pitch video (silent, 1920×1080) from a narration draft in ../video-narration.md.
// Each [SLIDE x] cue shows slide x for as long as its text takes to say; [DEMO Web2 …] / [DEMO Web3 …] cues use the
// web2 / web3 slides as stand-ins until the screen recordings are cut in. [AVATAR only] cues show the presenter alone,
// full height on black (plain black when there is no presenter video). [TITLE some words] is a section break: the
// picture goes white, the words fade in and out, and the next cue starts (TITLE_SECONDS, no speech).
//   PNG=/tmp/slides node docs/pitch/deck/build-pdf.mjs             (slide images)
//   node docs/pitch/deck/build-video.mjs /tmp/slides out.mp4 [draft=D] [wpm=140]
// With a presenter video, the slides change when the presenter starts each cue's text (word times from whisper.cpp)
// and the presenter is overlaid as a round window, bottom right, with the video's own audio. A section break pauses
// the presenter between two sentences for its length:
//   ffmpeg -i avatar.mp4 -ar 16000 -ac 1 a.wav && whisper-cli -m ggml-base.en.bin -f a.wav -ml 1 -sow -oj -of words
//   node docs/pitch/deck/build-video.mjs /tmp/slides out.mp4 D 140 avatar.mp4 words.json
// DEMO=<dir> uses <dir>/web2.mp4 and <dir>/web3.mp4 (1920×1080 screen recordings) for the [DEMO] cues instead of the
// stand-in slides; a clip is cut to the cue's length, or its last frame is held. No presenter window over a clip.
// Needs ffmpeg (FFMPEG=/path/to/ffmpeg if it is not on the PATH); section breaks also need playwright-core from
// app/verifier-demo and the local Chrome, as build-pdf.mjs does.
import { existsSync, mkdtempSync, readFileSync, readdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { execFileSync } from 'node:child_process'

const here = fileURLToPath(new URL('.', import.meta.url))
const [pngDir, out, draft = 'D', wpm = '140', avatar, wordsFile] = process.argv.slice(2)
const PAUSE = 0.8 // breath between slides, seconds
const FADE = 0.4
const LEAD = 0.3 // with a presenter: the slide is fully in this long before its first word
const TITLE_SECONDS = 3.5
const TITLE_FADE = 0.8 // to white and back, and the words in and out
const PIP = { size: 300, margin: 48, crop: 'crop=760:760:160:20' } // presenter window; crop is for a 1080×1080 source
// slides with content in the bottom-right corner: no window
const PIP_HIDDEN = ['global', 'trend', 'solana', 'roadmap', 'circuit', 'web2flow', 'web3flow']
const norm = (t) => t.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim().split(' ').filter(Boolean)
const n2 = (x) => x.toFixed(2)

const text = readFileSync(here + '../video-narration.md', 'utf8')
const section = text.split(/^## /m).find((s) => s.startsWith(draft + '.')).split(/^---$/m)[0]
const segments = [...section.matchAll(/^\[(SLIDE|DEMO|AVATAR|TITLE) ([^\]]*)\]\n([^[]*)/gm)].map(([, kind, rest, body]) => {
  if (kind === 'TITLE') return { title: rest.trim(), slide: 'title', words: 0, body: '', seconds: TITLE_SECONDS }
  const name = rest.match(/\w+/)[0]
  const words = body.trim().split(/\s+/).length
  return { solo: kind === 'AVATAR', demo: kind === 'DEMO', slide: kind === 'DEMO' ? name.toLowerCase() : name, words, body, seconds: +((words / wpm) * 60 + PAUSE).toFixed(1) }
})
const last = segments.length - 1
// cross-fade between cue i and the next one
const fade = (i) => (segments[i].title || segments[i + 1]?.title ? TITLE_FADE : FADE)

const cuts = [] // presenter times where a section break is inserted
if (avatar) {
  // Spoken words with times; a cue starts where three consecutive words of its opening are heard (names that the
  // recogniser mishears are skipped by trying later openings and stepping back).
  const spoken = JSON.parse(readFileSync(wordsFile, 'utf8')).transcription.flatMap((w) => norm(w.text).map((text) => ({ text, at: w.offsets.from / 1000, to: w.offsets.to / 1000 })))
  const total = +execFileSync(process.env.FFPROBE ?? 'ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', avatar], { encoding: 'utf8' })
  let from = 0
  const first = segments.map((s, i) => {
    if (i === 0 || s.title) return null
    const want = norm(s.body)
    for (let skip = 0; skip < 6; skip++) {
      for (let j = from; j + 2 < spoken.length; j++) {
        if ([0, 1, 2].every((k) => spoken[j + k].text === want[skip + k])) {
          from = j + 3
          return Math.max(1, j - skip)
        }
      }
    }
    throw new Error(`cannot find the start of "${s.slide}" in ${wordsFile}`)
  })
  // start of each cue on the output timeline; a section break sits in the silence before the next cue's first word
  let shift = 0
  const starts = segments.map((s, i) => {
    if (i === 0) return 0
    if (s.title) {
      const next = first[i + 1]
      const cut = (spoken[next - 1].to + spoken[next].at) / 2
      cuts.push(cut)
      shift += TITLE_SECONDS
      return cut + shift - TITLE_SECONDS
    }
    if (segments[i - 1].title) return cuts.at(-1) + shift
    return Math.max(0, spoken[first[i]].at - LEAD - FADE) + shift
  })
  segments.forEach((s, i) => (s.seconds = +((starts[i + 1] ?? total + shift) - starts[i]).toFixed(2)))
}

// the words of each section break as an image, in the deck's heading face
const titles = segments.filter((s) => s.title)
if (titles.length) {
  const require = createRequire(new URL('../../../app/verifier-demo/package.json', import.meta.url))
  const { chromium } = require('playwright-core')
  const dir = mkdtempSync(tmpdir() + '/pipon-title-')
  const browser = await chromium.launch({ executablePath: process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' })
  const tab = await browser.newPage({ viewport: { width: 1920, height: 1080 } })
  for (const [k, s] of titles.entries()) {
    await tab.setContent(`<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fredoka:wght@700&display=swap">
      <body style="margin:0;width:1920px;height:1080px;display:flex;align-items:center;justify-content:center;background:#fff">
      <h1 style="margin:0;font:700 112px 'Fredoka', Arial, sans-serif;color:#2a1f1c"></h1>`, { waitUntil: 'networkidle' })
    await tab.locator('h1').evaluate((h, t) => (h.textContent = t), s.title)
    await tab.evaluate(() => document.fonts.ready)
    await tab.screenshot({ path: (s.png = `${dir}/${k}.png`) })
  }
  await browser.close()
}

const pngs = readdirSync(pngDir)
const inputs = segments.flatMap((s, i) => {
  const length = String(s.seconds + (i < last ? fade(i) : 0))
  if (s.solo) return ['-f', 'lavfi', '-t', length, '-i', 'color=black:s=1920x1080:r=25']
  if (s.title) return ['-loop', '1', '-t', length, '-i', s.png]
  const clip = s.demo && process.env.DEMO && `${process.env.DEMO}/${s.slide}.mp4`
  if (clip && existsSync(clip)) return (s.clip = true), ['-i', clip]
  const file = pngs.find((f) => f.replace(/^\d+-|\.png$/g, '') === s.slide)
  if (!file) throw new Error(`no slide image for "${s.slide}"`)
  return ['-loop', '1', '-t', length, '-i', `${pngDir}/${file}`]
})

let filter = ''
if (avatar) {
  // the presenter on the output timeline: held still and silent during each section break
  const edges = [0, ...cuts]
  edges.forEach((a, k) => {
    const end = k < cuts.length ? `:end=${n2(cuts[k])}` : ''
    const hold = k < cuts.length ? `,tpad=stop_mode=clone:stop_duration=${TITLE_SECONDS}` : ''
    const quiet = k < cuts.length ? `,afade=t=out:st=${n2(cuts[k] - a - 0.05)}:d=0.05,apad=pad_dur=${TITLE_SECONDS}` : ''
    filter += `[${segments.length}:v]trim=start=${n2(a)}${end},setpts=PTS-STARTPTS,fps=25${hold}[pv${k}];`
    filter += `[${segments.length}:a]atrim=start=${n2(a)}${end},asetpts=PTS-STARTPTS${k ? ',afade=t=in:d=0.05' : ''}${quiet}[pa${k}];`
  })
  filter += `${edges.map((_, k) => `[pv${k}][pa${k}]`).join('')}concat=n=${edges.length}:v=1:a=1[pv][pa];`
  const solos = segments.filter((s) => s.solo).length
  filter += `[pv]split=${solos + 1}[pip]${Array.from({ length: solos }, (_, k) => `[solo${k}]`).join('')};`
}
// one prepared stream per cue: the slide, the clip, the section break, or the presenter's own footage for that time
let at = 0
let solo = 0
segments.forEach((s, i) => {
  const same = 'format=yuv420p,setsar=1,fps=25'
  const length = s.seconds + (i < last ? fade(i) : 0)
  if (s.solo && avatar) filter += `[solo${solo++}]trim=start=${n2(at)}:end=${n2(at + length)},setpts=PTS-STARTPTS,scale=-2:1080,pad=1920:1080:(ow-iw)/2:0:black,${same}[s${i}];`
  else if (s.clip) filter += `[${i}:v]scale=1920:1080,tpad=stop_mode=clone:stop_duration=60,trim=duration=${n2(length)},setpts=PTS-STARTPTS,${same}[s${i}];`
  else if (s.title) {
    // white, then the words in and out; the cross-fades on both sides are the fades to and from white
    filter += `[${i}:v]format=yuva420p,fade=t=in:st=${TITLE_FADE}:d=${TITLE_FADE}:alpha=1,fade=t=out:st=${n2(s.seconds - TITLE_FADE)}:d=${TITLE_FADE}:alpha=1[t${i}];`
    filter += `color=c=white:s=1920x1080:r=25:d=${n2(length)}[w${i}];[w${i}][t${i}]overlay=shortest=1,${same}[s${i}];`
  } else filter += `[${i}:v]${same}[s${i}];`
  at += s.seconds
})
at = 0
for (let i = 1; i < segments.length; i++) {
  at += segments[i - 1].seconds
  filter += `[${i === 1 ? 's0' : 'x' + (i - 1)}][s${i}]xfade=transition=fade:duration=${fade(i - 1)}:offset=${n2(at)}[x${i}];`
}
const args = ['-y', '-loglevel', 'error', ...inputs]
if (avatar) {
  const { size, margin, crop } = PIP
  // window opacity over time: fades out with the cross-fade into a cue without the window, and back in after it
  const hidden = [] // merged [from, to] spans without the window
  let t0 = 0
  for (const s of segments) {
    const span = [t0, (t0 += s.seconds)]
    if (!s.solo && !s.clip && !s.title && !PIP_HIDDEN.includes(s.slide)) continue
    if (hidden.length && hidden.at(-1)[1] === span[0]) hidden.at(-1)[1] = span[1]
    else hidden.push(span)
  }
  const shown = hidden.map(([from, to]) => `(${from > 0 ? `clip((${n2(from + FADE)}-T)/${FADE},0,1)` : '0'}+clip((T-${n2(to)})/${FADE},0,1))`).join('*') || '1'
  const disc = (d) => `geq=lum='p(X,Y)':cb='cb(X,Y)':cr='cr(X,Y)':a='clip((${d / 2}-hypot(X-${d / 2},Y-${d / 2}))*255,0,255)*${shown}'`
  filter += `[pip]${crop},scale=${size}:${size},format=yuva420p,${disc(size)}[face];`
  filter += `color=c=0xf4efe6:s=${size + 12}x${size + 12}:r=30,format=yuva420p,${disc(size + 12)}[ring];`
  filter += `[x${last}][ring]overlay=W-w-${margin - 6}:H-h-${margin - 6}:shortest=1[bg];[bg][face]overlay=W-w-${margin}:H-h-${margin}:shortest=1,format=yuv420p[v]`
  args.push('-i', avatar, '-filter_complex', filter, '-map', '[v]', '-map', '[pa]', '-c:a', 'aac', '-b:a', '192k')
} else {
  filter += `[x${last}]format=yuv420p[v]`
  args.push('-filter_complex', filter, '-map', '[v]')
}
execFileSync(process.env.FFMPEG ?? 'ffmpeg', [...args, '-r', '30', '-c:v', 'libx264', '-crf', '18', '-movflags', '+faststart', out])

let t = 0
for (const s of segments) {
  console.log(`${String(Math.floor(t / 60))}:${(t % 60).toFixed(1).padStart(4, '0')}  ${s.slide.padEnd(8)} ${s.seconds}s  (${s.words} words)`)
  t += s.seconds
}
console.log(`total ${Math.floor(t / 60)}:${(t % 60).toFixed(1).padStart(4, '0')}`)
