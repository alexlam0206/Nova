import { Worker } from 'bullmq'
import IORedis from 'ioredis'
import { prisma } from '../lib/prisma'
import { downloadAndConvert } from '../services/downloader'

const connection = new IORedis(process.env.REDIS_URL)

const worker = new Worker('downloads', async (job) => {
  const { songId } = job.data
  const song = await prisma.song.findUnique({ where: { id: songId } })
  if (!song) throw new Error('song not found')
  await prisma.song.update({ where: { id: songId }, data: { status: 'downloading' } })

  try {
    const safeArtist = (song.artistName || 'unknown').replace(/[^a-z0-9]/gi, '_')
    const safeAlbum = (song.album || 'unknown').replace(/[^a-z0-9]/gi, '_')
    const outDir = `${process.env.STORAGE_PATH || './storage'}/music/${safeArtist}/${safeAlbum}`
    const filename = `${song.trackName}.m4a`
    const outPath = await downloadAndConvert({ query: song.source || `${song.artistName} - ${song.trackName}`, outDir, filename })
    await prisma.song.update({ where: { id: songId }, data: { status: 'ready', filePath: outPath } })
  } catch (err) {
    await prisma.song.update({ where: { id: songId }, data: { status: 'error' } })
    throw err
  }
})

worker.on('error', (err) => console.error('Worker error', err))

console.log('Download worker started')
