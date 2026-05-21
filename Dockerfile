# 构建阶段
FROM node:20-bullseye-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm config set registry https://registry.npmmirror.com/ && npm install
COPY . .

# 编译 + 打包 Linux ARM64
RUN npm run build && npm run pack -- --linux --arm64

# 运行阶段（ARM64 专用镜像）
FROM arm64v8/debian:bullseye-slim

# 安装 Electron 运行依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnotify4 libnss3 libxss1 libasound2 \
    libdrm2 libgbm1 libx11-xcb1 libxcb-dri3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/release/linux-arm64-unpacked/ .
RUN chmod +x ColorTxt

# 暴露 Web 访问端口 1567
EXPOSE 1567

# 关键：启动时强制监听 0.0.0.0:1567，允许外部访问
CMD ["./ColorTxt", "--no-sandbox", "--port=1567", "--host=0.0.0.0"]
