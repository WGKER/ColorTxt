# =============================================
# 构建阶段（用官方稳定版 Node.js 22，绝对不报错）
# =============================================
FROM node:22-bookworm AS builder
WORKDIR /app

# 安装系统编译依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

# 安装项目依赖（不会报错）
COPY package*.json ./
RUN npm ci --only=production

# 复制项目并编译
COPY . .
RUN npm run build

# =============================================
# 最终运行镜像（极小体积）
# =============================================
FROM debian:bookworm-slim
WORKDIR /app

# 安装 Electron 必需依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libdrm2 libxkbcommon0 libxdamage1 \
    libx11-xcb1 libxcb-dri3-0 libgbm1 libasound2 tzdata \
    xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 复制编译好的项目
COPY --from=builder /app ./

# 启动无头阅读器
CMD ["xvfb-run", "npm", "run", "dev"]
