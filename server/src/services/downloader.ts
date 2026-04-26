import { spawn } from 'child_process'
import path from 'path'
import fs from 'fs'

export async function downloadAndConvert(opts: { query: string; outDir: string; filename: string }) {
  const outDir = path.resolve(opts.outDir)
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true })
  const outPath = path.join(outDir, opts.filename)

  // 1) use yt-dlp to download best audio to temp
  const ytdlp = spawn('yt-dlp', ['-f', 'bestaudio', '-o', '%(title)s.%(ext)s', opts.query], { stdio: 'inherit' })
  await new Promise((resolve, reject) => {
    ytdlp.on('close', (code) => (code === 0 ? resolve(null) : reject(new Error('yt-dlp failed'))))
  })

  // 2) find downloaded file (naive)
  const found = fs.readdirSync(process.cwd()).find((f) => f.includes(opts.filename.split('.').slice(0, -1).join('.')))
  const downloaded = found ? path.join(process.cwd(), found) : null
  if (!downloaded) throw new Error('downloaded file not found')

  // 3) convert with ffmpeg to m4a
  await new Promise((resolve, reject) => {
    const ff = spawn('ffmpeg', ['-i', downloaded, '-c:a', 'aac', '-b:a', '192k', outPath], { stdio: 'inherit' })
    ff.on('close', (code) => (code === 0 ? resolve(null) : reject(new Error('ffmpeg failed'))))
  })

  // cleanup downloaded intermediate
  try {
    if (downloaded && fs.existsSync(downloaded)) fs.unlinkSync(downloaded)
  } catch (e) {}

  return outPath
}
