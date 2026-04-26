import { NextApiRequest, NextApiResponse } from 'next'
import fs from 'fs'
import path from 'path'
import { prisma } from '../../../lib/prisma'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { id } = req.query
  const song = await prisma.song.findUnique({ where: { id: String(id) } })
  if (!song || !song.filePath) return res.status(404).end()

  const filePath = path.resolve(song.filePath)
  if (!fs.existsSync(filePath)) return res.status(404).end()

  const stat = fs.statSync(filePath)
  const range = req.headers.range
  if (!range) {
    res.setHeader('Content-Type', 'audio/mp4')
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
    'Content-Type': 'audio/mp4',
  })
  stream.pipe(res)
}
