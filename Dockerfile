# ==================== 构建阶段（修复所有依赖问题）====================
FROM node:20-bullseye AS builder
WORKDIR /app

# 安装 Electron 打包必需的系统依赖（关键修复）
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpng-dev \
    libjpeg-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY package*.json ./

# 淘宝npm源 + 干净安装（修复卡死/失败）
RUN npm config set registry https://registry.npmmirror.com/ && \
    npm install --legacy-peer-deps

# 复制全部源码
COPY . .

# 构建项目（强制ARM64，关闭无用平台）
RUN npm run build && \
    npm run pack -- --linux --arm64 --x64=false --ia32=false

# ==================== 运行阶段 ====================
FROM arm64v8/debian:bullseye-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnotify4 libnss3 libxss1 libasound2 \
    libdrm2 libgbm1 libx11-xcb1 libxcb-dri3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/release/linux-arm64-unpacked/ .
RUN chmod +x ColorTxt

# 暴露Web端口
EXPOSE 1567

# 启动命令
CMD ["./ColorTxt", "--no-sandbox", "--port=1567", "--host=0.0.0.0"]
