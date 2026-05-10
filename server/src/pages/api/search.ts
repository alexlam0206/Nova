import { NextApiRequest, NextApiResponse } from 'next'
import { prisma } from '../../lib/prisma'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') return res.status(405).end()
  const q = (req.query.q as string || '').trim()

  const songs = await prisma.song.findMany({
    where: q ? {
      OR: [
        { trackName: { contains: q, mode: 'insensitive' } },
        { artistName: { contains: q, mode: 'insensitive' } },
      ]
    } : {},
    select: {
      id: true, trackName: true, artistName: true, album: true,
      year: true, coverUrl: true, duration: true, status: true,
      source: true, filePath: true,
    },
    take: q ? 20 : 100,
    orderBy: { createdAt: 'desc' },
  })

  res.json(songs)
}