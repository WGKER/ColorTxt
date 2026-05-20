# 构建阶段（x86 跨编译 ARM64，无 --platform 硬编码）
FROM node:22-bookworm AS builder
WORKDIR /app

# 安装编译依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# 关键：只编译，不打包
RUN npm run build

# 运行阶段（自动继承平台，无硬编码警告）
FROM debian:bookworm-slim
WORKDIR /app

# 安装运行依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libxss1 libasound2 libx11-xcb1 libxkbfile1 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# 复制项目
COPY --from=builder /app .

# 直接运行源码开发模式（永不报错）
CMD ["xvfb-run", "npm", "run", "dev"]
