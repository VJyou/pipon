// Render the slide track of the pitch video (silent, 1920×1080) from a narration draft in ../video-narration.md.
// Each [SLIDE x] cue shows slide x for as long as its text takes to say; [DEMO Web2 …] / [DEMO Web3 …] cues use the
// web2 / web3 slides as stand-ins until the screen recordings are cut in. [AVATAR only] cues show the presenter alone,
// full height on black (plain black when there is no presenter video).
//   PNG=/tmp/slides node docs/pitch/deck/build-pdf.mjs             (slide images)
//   node docs/pitch/deck/build-video.mjs /tmp/slides out.mp4 [draft=D] [wpm=140]
// With a presenter video, the slides change when the presenter starts each cue's text (word times from whisper.cpp)
// and the presenter is overlaid as a round window, bottom right, with the video's own audio:
//   ffmpeg -i avatar.mp4 -ar 16000 -ac 1 a.wav && whisper-cli -m ggml-base.en.bin -f a.wav -ml 1 -sow -oj -of words
//   node docs/pitch/deck/build-video.mjs /tmp/slides out.mp4 D 140 avatar.mp4 words.json
// DEMO=<dir> uses <dir>/web2.mp4 and <dir>/web3.mp4 (1920×1080 screen recordings) for the [DEMO] cues instead of the
// stand-in slides; a clip is cut to the cue's length, or its last frame is held. No presenter window over a clip.
// Needs ffmpeg (FFMPEG=/path/to/ffmpeg if it is not on the PATH).
import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { execFileSync } from 'node:child_process'

const here = fileURLToPath(new URL('.', import.meta.url))
const [pngDir, out, draft = 'D', wpm = '140', avatar, wordsFile] = process.argv.slice(2)
const PAUSE = 0.8 // breath between slides, seconds
const FADE = 0.4
const LEAD = 0.3 // with a presenter: the slide is fully in this long before its first word
const PIP = { size: 300, margin: 48, crop: 'crop=760:760:160:20' } // presenter window; crop is for a 1080×1080 source
const PIP_HIDDEN = ['global', 'trend', 'solana', 'roadmap'] // slides with content in the bottom-right corner: no window
const norm = (t) => t.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim().split(' ').filter(Boolean)

const text = readFileSync(here + '../video-narration.md', 'utf8')
const section = text.split(/^## /m).find((s) => s.startsWith(draft + '.')).split(/^---$/m)[0]
const segments = [...section.matchAll(/^\[(SLIDE|DEMO|AVATAR) (\w+)[^\]]*\]\n([^[]*)/gm)].map(([, kind, name, body]) => {
  const words = body.trim().split(/\s+/).length
  return { solo: kind === 'AVATAR', slide: kind === 'DEMO' ? name.toLowerCase() : name, words, body, seconds: +((words / wpm) * 60 + PAUSE).toFixed(1) }
})

if (avatar) {
  // Spoken words with start times; a cue starts where three consecutive words of its opening are heard (names that the
  // recogniser mishears are skipped by trying later openings and stepping back).
  const spoken = JSON.parse(readFileSync(wordsFile, 'utf8')).transcription.flatMap((w) => norm(w.text).map((text) => ({ text, at: w.offsets.from / 1000 })))
  const total = +execFileSync(process.env.FFPROBE ?? 'ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', avatar], { encoding: 'utf8' })
  let from = 0
  const starts = segments.map((s, i) => {
    if (i === 0) return 0
    const want = norm(s.body)
    for (let skip = 0; skip < 6; skip++) {
      for (let j = from; j + 2 < spoken.length; j++) {
        if ([0, 1, 2].every((k) => spoken[j + k].text === want[skip + k])) {
          from = j + 3
          return Math.max(0, spoken[Math.max(0, j - skip)].at - LEAD - FADE)
        }
      }
    }
    throw new Error(`cannot find the start of "${s.slide}" in ${wordsFile}`)
  })
  segments.forEach((s, i) => (s.seconds = +((starts[i + 1] ?? total) - starts[i]).toFixed(2)))
}

const pngs = readdirSync(pngDir)
const inputs = segments.flatMap((s, i) => {
  const length = String(s.seconds + (i < segments.length - 1 ? FADE : 0))
  if (s.solo) return ['-f', 'lavfi', '-t', length, '-i', 'color=black:s=1920x1080:r=25']
  const clip = process.env.DEMO && `${process.env.DEMO}/${s.slide}.mp4`
  if (clip && existsSync(clip)) return (s.clip = true), ['-i', clip]
  const file = pngs.find((f) => f.replace(/^\d+-|\.png$/g, '') === s.slide)
  if (!file) throw new Error(`no slide image for "${s.slide}"`)
  return ['-loop', '1', '-t', length, '-i', `${pngDir}/${file}`]
})
// one prepared stream per cue: the slide, or the presenter's own footage for that stretch of time
const solos = avatar ? segments.filter((s) => s.solo).length : 0
let filter = avatar ? `[${segments.length}:v]split=${solos + 1}[pip]${Array.from({ length: solos }, (_, k) => `[solo${k}]`).join('')};` : ''
let at = 0
let solo = 0
segments.forEach((s, i) => {
  const same = 'format=yuv420p,setsar=1,fps=25'
  if (s.solo && avatar) filter += `[solo${solo++}]trim=start=${at.toFixed(2)}:end=${(at + s.seconds + FADE).toFixed(2)},setpts=PTS-STARTPTS,scale=-2:1080,pad=1920:1080:(ow-iw)/2:0:black,${same}[s${i}];`
  else if (s.clip) filter += `[${i}:v]scale=1920:1080,tpad=stop_mode=clone:stop_duration=60,trim=duration=${(s.seconds + FADE).toFixed(2)},setpts=PTS-STARTPTS,${same}[s${i}];`
  else filter += `[${i}:v]${same}[s${i}];`
  at += s.seconds
})
at = 0
for (let i = 1; i < segments.length; i++) {
  at += segments[i - 1].seconds
  filter += `[${i === 1 ? 's0' : 'x' + (i - 1)}][s${i}]xfade=transition=fade:duration=${FADE}:offset=${at.toFixed(2)}[x${i}];`
}
const args = ['-y', '-loglevel', 'error', ...inputs]
if (avatar) {
  const { size, margin, crop } = PIP
  // window opacity over time: fades out with the cross-fade into a hidden slide or a presenter-only cue, and back in after
  const hidden = [] // merged [from, to] spans without the window
  let t0 = 0
  for (const s of segments) {
    const span = [t0, (t0 += s.seconds)]
    if (!s.solo && !s.clip && !PIP_HIDDEN.includes(s.slide)) continue
    if (hidden.length && hidden.at(-1)[1] === span[0]) hidden.at(-1)[1] = span[1]
    else hidden.push(span)
  }
  const shown = hidden.map(([from, to]) => `(${from > 0 ? `clip((${(from + FADE).toFixed(2)}-T)/${FADE},0,1)` : '0'}+clip((T-${to.toFixed(2)})/${FADE},0,1))`).join('*') || '1'
  const disc = (d) => `geq=lum='p(X,Y)':cb='cb(X,Y)':cr='cr(X,Y)':a='clip((${d / 2}-hypot(X-${d / 2},Y-${d / 2}))*255,0,255)*${shown}'`
  filter += `[pip]${crop},scale=${size}:${size},format=yuva420p,${disc(size)}[face];`
  filter += `color=c=0xf4efe6:s=${size + 12}x${size + 12}:r=30,format=yuva420p,${disc(size + 12)}[ring];`
  filter += `[x${segments.length - 1}][ring]overlay=W-w-${margin - 6}:H-h-${margin - 6}:shortest=1[bg];[bg][face]overlay=W-w-${margin}:H-h-${margin}:shortest=1,format=yuv420p[v]`
  args.push('-i', avatar, '-filter_complex', filter, '-map', '[v]', '-map', `${segments.length}:a`, '-c:a', 'aac', '-b:a', '192k')
} else {
  filter += `[x${segments.length - 1}]format=yuv420p[v]`
  args.push('-filter_complex', filter, '-map', '[v]')
}
execFileSync(process.env.FFMPEG ?? 'ffmpeg', [...args, '-r', '30', '-c:v', 'libx264', '-crf', '18', '-movflags', '+faststart', out])

let t = 0
for (const s of segments) {
  console.log(`${String(Math.floor(t / 60))}:${(t % 60).toFixed(1).padStart(4, '0')}  ${s.slide.padEnd(8)} ${s.seconds}s  (${s.words} words)`)
  t += s.seconds
}
console.log(`total ${Math.floor(t / 60)}:${(t % 60).toFixed(1).padStart(4, '0')}`)
