FROM node:20-bullseye-slim

WORKDIR /usr/src/app

# Install system deps: ffmpeg, python3, pip and openssl for Prisma
RUN apt-get update && \
		apt-get install -y --no-install-recommends \
			ffmpeg \
			python3 \
			python3-pip \
			ca-certificates \
			openssl \
		&& rm -rf /var/lib/apt/lists/*

# Install yt-dlp via pip (more up-to-date)
RUN pip3 install yt-dlp

COPY package.json package-lock.json* ./
RUN npm install --no-audit --no-fund
COPY . .
CMD ["npm", "run", "dev"]
