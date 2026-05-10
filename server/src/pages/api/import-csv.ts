import { NextApiRequest, NextApiResponse } from 'next'
import formidable from 'formidable'
import fs from 'fs'
import { parse } from 'csv-parse/sync'
import { prisma } from '../../lib/prisma'

export const config = {
  api: { bodyParser: false },
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') return res.status(405).end()

  const form = new formidable.IncomingForm()
  form.parse(req, async (err, fields, files) => {
    if (err) return res.status(500).json({ error: 'upload error' })
    // @ts-ignore
    const f = files.file
    if (!f) return res.status(400).json({ error: 'no file' })
    const data = fs.readFileSync(f.filepath)
    const records = parse(data, { columns: true, skip_empty_lines: true })
    const created: any[] = []
    for (const r of records) {
      const song = await prisma.song.create({
        data: {
          trackName: r['Track Name'] || r.track || r.title || r['Track Name'] || '',
          artistName: r['Artist Name'] || r.artist || r['Artist'] || '',
          isrc: r['ISRC'] || r.isrc || null,
          album: r['Album'] || null,
        },
      })
      created.push(song)
    }
    res.json({ created })
  })
}
