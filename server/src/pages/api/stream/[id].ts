import { NextApiRequest, NextApiResponse } from 'next'
import fs from 'fs'
import path from 'path'
import { prisma } from '../../../lib/prisma'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { id } = req.query
  const song = await prisma.song.findUnique({ where: { id: String(id) } })
  if (!song) return res.status(404).end()

  if (!song.filePath) {
    if (!song.source) return res.status(404).end()
    res.redirect(307, song.source)
    return
  }

  const filePath = path.resolve(song.filePath)
  if (!fs.existsSync(filePath)) return res.status(404).end()

  const stat = fs.statSync(filePath)
  const range = req.headers.range
  const ext = path.extname(filePath).toLowerCase()
  const contentType = ext === '.mp3' ? 'audio/mpeg' : ext === '.m4a' ? 'audio/mp4' : 'audio/mpeg'
  if (!range) {
    res.setHeader('Content-Type', contentType)
    res.setHeader('Content-Length', stat.size)
    fs.createReadStream(filePath).pipe(res)
    return
  }

  const parts = range.replace(/bytes=/, '').split('-')
  const start = parseInt(parts[0], 10)
  const end = parts[1] ? parseInt(parts[1], 10) : stat.size - 1
  const chunkSize = end - start + 1
  const stream = fs.createReadStream(filePath, { start, end })
  res.writeHead(206, {
    'Content-Range': `bytes ${start}-${end}/${stat.size}`,
    'Accept-Ranges': 'bytes',
    'Content-Length': chunkSize,
    'Content-Type': contentType,
  })
  stream.pipe(res)
}
