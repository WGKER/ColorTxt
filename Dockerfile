# 构建阶段
FROM node:22-bookworm AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# --------------------------
# 最终运行镜像（最小底包，语法绝对正确）
# --------------------------
FROM node:22-bookworm-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libasound2 libx11-xcb1 xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app ./

CMD ["xvfb-run", "npm", "run", "dev"]
