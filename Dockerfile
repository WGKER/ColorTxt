FROM node:22-bookworm AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci
COPY . .

RUN npm run build

FROM debian:bookworm-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libxss1 libasound2 libx11-xcb1 libxkbfile1 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app .

EXPOSE 1567

CMD ["xvfb-run", "npm", "run", "dev"]
