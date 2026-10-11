// Render the slide track of the pitch video (silent, 1920×1080) from a narration draft in ../video-narration.md.
// Each [SLIDE x] cue shows slide x for as long as its text takes to say; [DEMO Web2 …] / [DEMO Web3 …] cues use the
// web2 / web3 slides as stand-ins until the screen recordings are cut in.
//   PNG=/tmp/slides node docs/pitch/deck/build-pdf.mjs             (slide images)
//   FFMPEG=/path/to/ffmpeg node docs/pitch/deck/build-video.mjs /tmp/slides out.mp4 [draft=D] [wpm=140]
import { readFileSync, readdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { execFileSync } from 'node:child_process'

const here = fileURLToPath(new URL('.', import.meta.url))
const [pngDir, out, draft = 'D', wpm = '140'] = process.argv.slice(2)
const PAUSE = 0.8 // breath between slides, seconds
const FADE = 0.4

const text = readFileSync(here + '../video-narration.md', 'utf8')
const section = text.split(/^## /m).find((s) => s.startsWith(draft + '.')).split(/^---$/m)[0]
const segments = [...section.matchAll(/^\[(SLIDE|DEMO) (\w+)[^\]]*\]\n([^[]*)/gm)].map(([, kind, name, body]) => {
  const words = body.trim().split(/\s+/).length
  return { slide: kind === 'DEMO' ? name.toLowerCase() : name, words, seconds: +((words / wpm) * 60 + PAUSE).toFixed(1) }
})

const pngs = readdirSync(pngDir)
const inputs = segments.flatMap((s, i) => {
  const file = pngs.find((f) => f.replace(/^\d+-|\.png$/g, '') === s.slide)
  if (!file) throw new Error(`no slide image for "${s.slide}"`)
  return ['-loop', '1', '-t', String(s.seconds + (i < segments.length - 1 ? FADE : 0)), '-i', `${pngDir}/${file}`]
})
let filter = ''
let at = 0
for (let i = 1; i < segments.length; i++) {
  at += segments[i - 1].seconds
  filter += `[${i === 1 ? '0:v' : 'x' + (i - 1)}][${i}:v]xfade=transition=fade:duration=${FADE}:offset=${at.toFixed(1)}[x${i}];`
}
filter += `[x${segments.length - 1}]format=yuv420p[v]`

execFileSync(process.env.FFMPEG ?? 'ffmpeg', ['-y', '-loglevel', 'error', ...inputs, '-filter_complex', filter, '-map', '[v]', '-r', '30', '-c:v', 'libx264', '-crf', '18', out])

let t = 0
for (const s of segments) {
  console.log(`${String(Math.floor(t / 60))}:${(t % 60).toFixed(1).padStart(4, '0')}  ${s.slide.padEnd(8)} ${s.seconds}s  (${s.words} words)`)
  t += s.seconds
}
console.log(`total ${Math.floor(t / 60)}:${(t % 60).toFixed(1).padStart(4, '0')}`)
