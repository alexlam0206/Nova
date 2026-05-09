import { NextApiRequest, NextApiResponse } from 'next'
import { execSync } from 'child_process'
import { prisma } from '../../../lib/prisma'

function extractMetadata(query: string) {
  const output = execSync(
    `yt-dlp --dump-json --no-download --no-playlist "${query}"`,
    { encoding: 'utf-8', timeout: 30000 }
  )
  const lines = output.trim().split('\n')
  return lines.map(line => JSON.parse(line))
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') return res.status(405).end()

  const { url, title, artist } = req.body
  if (!url) return res.status(400).json({ error: 'url is required' })

  try {
    let trackName = title
    let artistName = artist
    let coverUrl: string | null = null
    let duration: number | null = null

    if (!trackName || !artistName) {
      const meta = extractMetadata(url)[0]
      trackName = trackName || meta?.title || 'Unknown'
      artistName = artistName || meta?.artist || meta?.uploader || 'Unknown'
      coverUrl = meta?.thumbnail || null
      duration = meta?.duration ? Math.floor(meta.duration) : null
    }

    const song = await prisma.song.create({
      data: {
        trackName,
        artistName,
        coverUrl,
        duration,
        source: url,
        status: 'pending',
      },
    })

    res.json({ ok: true, song })
  } catch (err: any) {
    console.error('youtube import error:', err.message)
    res.status(500).json({ error: 'failed to import', detail: err.message })
  }
}