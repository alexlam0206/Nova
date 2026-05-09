import { NextApiRequest, NextApiResponse } from 'next'
import { prisma } from '../../../lib/prisma'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') return res.status(405).end()
  const q = (req.query.q as string || '').trim()
  if (!q) return res.json([])

  const songs = await prisma.song.findMany({
    where: {
      OR: [
        { trackName: { contains: q, mode: 'insensitive' } },
        { artistName: { contains: q, mode: 'insensitive' } },
      ]
    },
    take: 20,
    orderBy: { createdAt: 'desc' },
  })

  res.json(songs)
}