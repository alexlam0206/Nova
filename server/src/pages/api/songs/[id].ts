import { NextApiRequest, NextApiResponse } from 'next'
import { prisma } from '../../../lib/prisma'
import fs from 'fs'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'DELETE') return res.status(405).end()
  const { id } = req.query

  const song = await prisma.song.findUnique({ where: { id: String(id) } })
  if (!song) return res.status(404).json({ error: 'not found' })

  if (song.filePath && fs.existsSync(song.filePath)) {
    fs.unlinkSync(song.filePath)
  }

  await prisma.song.delete({ where: { id: String(id) } })
  res.json({ ok: true })
}