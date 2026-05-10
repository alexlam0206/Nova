import { NextApiRequest, NextApiResponse } from 'next'
import { video_info } from 'play-dl'
import path from 'path'
import fs from 'fs'
import { exec } from 'child_process'
import { prisma } from '../../lib/prisma'

const STORAGE_PATH = process.env.STORAGE_PATH || '/data/storage'

function downloadAudio(url: string, songId: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const outTemplate = path.join(STORAGE_PATH, `${songId}.%(ext)s`)
    const cmd = `yt-dlp --extractor-args "youtube:player_client=android" -f 18 -x --audio-format mp3 -o "${outTemplate}" --no-playlist "${url}"`
    exec(cmd, { timeout: 300000 }, (error, _stdout, stderr) => {
      if (error) {
        console.error('yt-dlp error:', stderr)
        reject(error)
        return
      }
      const mp3Path = path.join(STORAGE_PATH, `${songId}.mp3`)
      const mp4Path = path.join(STORAGE_PATH, `${songId}.mp4`)
      if (fs.existsSync(mp3Path)) {
        resolve(mp3Path)
      } else if (fs.existsSync(mp4Path)) {
        resolve(mp4Path)
      } else {
        const files = fs.readdirSync(STORAGE_PATH).filter(f => f.startsWith(songId))
        if (files.length > 0) {
          resolve(path.join(STORAGE_PATH, files[0]))
        } else {
          reject(new Error('Downloaded file not found'))
        }
      }
    })
  })
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') return res.status(405).end()
  const { url } = req.body
  if (!url) return res.status(400).json({ error: 'url is required' })

  try {
    const existing = await prisma.song.findFirst({ where: { source: url } })
    if (existing) {
      res.json({ ok: true, song: existing, duplicate: true })
      return
    }

    const info = await video_info(url)
    const details = info.video_details
    const trackName = details.title || 'Unknown'
    const artistName = details.channel?.name || 'Unknown'
    const thumbs = details.thumbnails || []
    const coverUrl = thumbs.length > 0 ? thumbs[thumbs.length - 1].url : null
    const duration = parseInt(info.format[0]?.approxDurationMs || '0') / 1000 || null

    const tempId = `yt_${Date.now()}`
    let filePath: string | null = null

    try {
      filePath = await downloadAudio(url, tempId)
    } catch (dlErr) {
      console.warn('download failed:', dlErr)
    }

    const song = await prisma.song.create({
      data: { trackName, artistName, coverUrl, duration, source: url, filePath, status: 'pending' },
    })

    if (filePath) {
      const finalPath = path.join(STORAGE_PATH, `${song.id}.mp3`)
      try {
        fs.renameSync(filePath, finalPath)
        await prisma.song.update({ where: { id: song.id }, data: { filePath: finalPath, status: 'ready' } })
        song.filePath = finalPath
        song.status = 'ready'
      } catch (renameErr) {
        console.warn('rename failed:', renameErr)
      }
    }

    res.json({ ok: true, song })
  } catch (err: any) {
    console.error('youtube import error:', err.message)
    res.status(500).json({ error: 'failed to import', detail: err.message })
  }
}