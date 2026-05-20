# 构建阶段
FROM --platform=linux/arm64 node:20-bookworm-slim AS builder
WORKDIR /app

# 安装系统依赖（修复 better-sqlite3 编译失败）
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci

COPY . .

# 🔥 修复：正确的 ARM64 构建命令
RUN npm run build -- --arm64

# 运行阶段
FROM --platform=linux/arm64 debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libxss1 libasound2 libx11-xcb1 libxkbfile1 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/dist/linux-arm64-unpacked .

CMD ["xvfb-run", "./ColorTxt"]
