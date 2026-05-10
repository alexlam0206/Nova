import { NextApiRequest, NextApiResponse } from 'next'
import { prisma } from '../../lib/prisma'
import { exec } from 'child_process'

const STORAGE_PATH = process.env.STORAGE_PATH || '/data/storage'

function isTraditionalChinese(text: string): boolean {
  for (const char of text) {
    if (char.charCodeAt(0) >= 0x4E00 && char.charCodeAt(0) <= 0x9FFF) return true
  }
  return false
}

function pickTitle(titles: string[]): string {
  for (const t of titles) {
    if (isTraditionalChinese(t)) return t
  }
  return titles[0] || 'Unknown'
}

function cleanArtist(name: string): string {
  return name.replace(/\s*-\s*Topic$/i, '').trim() || 'Unknown'
}

interface YtResult {
  id: string
  isYouTube: true
  trackName: string
  artistName: string
  coverUrl: string | null
  duration: number | null
  youtubeUrl: string
  source: null
  filePath: null
  status: 'youtube'
  album: null
  year: null
}

function searchYouTube(q: string): Promise<YtResult[]> {
  return new Promise((resolve, reject) => {
    const cmd = `yt-dlp --extractor-args "youtube:player_client=android" --dump-json --flat-playlist --playlist-items 1-10 "ytsearchmusic10:${q.replace(/"/g, '\\"')}"`
    exec(cmd, { timeout: 30000 }, (error, stdout, stderr) => {
      if (error || !stdout) {
        console.error('yt-dlp search error:', stderr || error)
        resolve([])
        return
      }
      const lines = stdout.trim().split('\n')
      const results: YtResult[] = []
      for (const line of lines) {
        try {
          const v = JSON.parse(line)
          const titles = [v.title, v.alt_title].filter(Boolean) as string[]
          const thumbs = v.thumbnail ? [v.thumbnail] : (v.thumbnails || []).map((t: any) => t.url)
          results.push({
            id: v.id || `yt_${Date.now()}`,
            isYouTube: true,
            trackName: pickTitle(titles),
            artistName: cleanArtist(v.channel || v.uploader || 'Unknown'),
            coverUrl: thumbs[thumbs.length - 1] || null,
            duration: v.duration || null,
            youtubeUrl: `https://www.youtube.com/watch?v=${v.id}`,
            source: null,
            filePath: null,
            status: 'youtube',
            album: null,
            year: null,
          })
        } catch { continue }
      }
      resolve(results)
    })
  })
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') return res.status(405).end()
  const q = (req.query.q as string || '').trim()

  const dbSongs = await prisma.song.findMany({
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

  const dbResults = dbSongs.map(s => ({ ...s, isYouTube: false as const, youtubeUrl: null }))

  if (!q) {
    res.json(dbResults)
    return
  }

  const ytResults = await searchYouTube(q)
  const combined = [...dbResults, ...ytResults]
  res.json(combined)
}