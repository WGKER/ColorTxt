# 直接用 ARM64 环境运行源码，不编译！彻底避开 build 错误
FROM --platform=linux/arm64 node:20-bookworm-slim

WORKDIR /app

# 安装系统依赖（必须）
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    libgtk-3-0 libnss3 libxss1 libasound2 libx11-xcb1 libxkbfile1 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# 复制项目
COPY . .

# 安装依赖（只安装，不构建！）
RUN npm install

# 直接运行源码（dev 模式，不会触发 electron-builder 构建）
CMD ["xvfb-run", "npm", "run", "dev"]
