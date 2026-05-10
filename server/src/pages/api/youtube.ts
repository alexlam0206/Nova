import { NextApiRequest, NextApiResponse } from 'next'
import { video_info } from 'play-dl'
import path from 'path'
import fs from 'fs'
import http from 'http'
import https from 'https'
import { prisma } from '../../lib/prisma'

const STORAGE_PATH = process.env.STORAGE_PATH || '/data/storage'

function fetchStream(url: string): Promise<NodeJS.ReadableStream> {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith('https') ? https : http
    const req = mod.request(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        fetchStream(res.headers.location!).then(resolve).catch(reject)
      } else {
        resolve(res)
      }
    })
    req.on('error', reject)
    req.end()
  })
}

async function downloadAudio(url: string, songId: string): Promise<string> {
  const outPath = path.join(STORAGE_PATH, `${songId}.m4a`)
  const info = await video_info(url)
  const audioFmt = info.format.find((f: any) => f.type?.startsWith('audio'))
  if (!audioFmt?.url) throw new Error('No audio URL')

  const stream = await fetchStream(audioFmt.url) as NodeJS.ReadableStream
  const writeStream = fs.createWriteStream(outPath)
  stream.pipe(writeStream)
  return new Promise((resolve, reject) => {
    writeStream.on('finish', () => resolve(outPath))
    writeStream.on('error', reject)
  })
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') return res.status(405).end()
  const { url } = req.body
  if (!url) return res.status(400).json({ error: 'url is required' })

  try {
    const info = await video_info(url)
    const details = info.video_details
    const trackName = details.title || 'Unknown'
    const artistName = details.author?.name || 'Unknown'
    const coverUrl = details.thumbnails?.[0]?.url || null
    const duration = parseInt(info.format[0]?.approxDurationMs || '0') / 1000 || null

    const tempId = `temp_${Date.now()}`
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
      const finalPath = path.join(STORAGE_PATH, `${song.id}.m4a`)
      fs.renameSync(filePath, finalPath)
      await prisma.song.update({ where: { id: song.id }, data: { filePath: finalPath, status: 'ready' } })
      song.filePath = finalPath
      song.status = 'ready'
    }

    res.json({ ok: true, song })
  } catch (err: any) {
    console.error('youtube import error:', err.message)
    res.status(500).json({ error: 'failed to import', detail: err.message })
  }
}