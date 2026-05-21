# 构建阶段
FROM node:22-bookworm AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# 运行镜像（ARM NAS 专用，最小体积）
FROM node:22-bookworm-slim
WORKDIR /app

# ARM NAS 必须装的依赖（少一个都启动不了）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libxss1 libasound2 libx11-xcb1 libxkbfile1 \
    xvfb libgbm1 libdrm2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app .

# 暴露端口 1567
EXPOSE 1567

# ✅ ARM NAS 专用启动命令（必须加这些参数才能跑）
CMD ["xvfb-run", "--auto-servernum", "--server-num=1", "npm", "run", "dev"]
