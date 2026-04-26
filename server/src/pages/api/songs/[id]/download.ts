import { NextApiRequest, NextApiResponse } from 'next'
import { prisma } from '../../../../lib/prisma'
import { Queue } from 'bullmq'
import IORedis from 'ioredis'

const connection = new IORedis(process.env.REDIS_URL)
const queue = new Queue('downloads', { connection })

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') return res.status(405).end()
  const { id } = req.query
  const song = await prisma.song.findUnique({ where: { id: String(id) } })
  if (!song) return res.status(404).json({ error: 'not found' })
  await queue.add('download-song', { songId: song.id })
  await prisma.song.update({ where: { id: song.id }, data: { status: 'queued' } })
  res.json({ ok: true })
}
