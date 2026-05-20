FROM node:20-bookworm AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci

COPY . .

# 正确构建 Linux ARM64
RUN npm run build -- --linux arm64

# 查看产物路径（调试用，能看到文件到底在哪）
RUN ls -la /app/dist/

# 运行时镜像
FROM --platform=linux/arm64 debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libxss1 libasound2 libx11-xcb1 libxkbfile1 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---------------- 关键修复 ----------------
# 自动找构建好的目录，不管叫什么名字
COPY --from=builder /app/dist ./dist

# 启动命令（自动找可执行文件）
CMD ["xvfb-run", "bash", "-c", "ls dist && xvfb-run ./dist/*/ColorTxt"]
