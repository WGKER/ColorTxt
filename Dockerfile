# --------------- 构建阶段（x86构建，输出ARM64应用）---------------
FROM node:20-bookworm AS builder

WORKDIR /app

# 安装编译依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci

COPY . .

# 关键：跨平台编译 Linux ARM64
RUN npm run build -- --linux --arm64

# --------------- 运行阶段（纯ARM64环境）---------------
FROM --platform=linux/arm64 debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libxss1 libasound2 libx11-xcb1 libxkbfile1 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制已经构建好的应用
COPY --from=builder /app/dist/linux-arm64-unpacked .

# 定义可挂载目录
VOLUME ["/app/books", "/app/config"]

CMD ["xvfb-run", "./ColorTxt"]
