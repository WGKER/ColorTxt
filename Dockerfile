# =============================================
# 构建阶段（用完即弃，不占用最终镜像空间）
# =============================================
FROM node:22-bookworm AS builder
WORKDIR /app

# 安装编译依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

# 安装生产依赖（最小化）
COPY package*.json ./
RUN npm ci --only=production --force

# 复制项目代码
COPY . .

# 编译项目
RUN npm run build


# =============================================
# 最终运行镜像（极度精简、安全、小体积）
# =============================================
FROM debian:bookworm-slim
WORKDIR /app

# 安装 Electron + 无头运行必需依赖（无多余组件）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libdrm2 libxkbcommon0 libxdamage1 \
    libx11-xcb1 libxcb-dri3-0 libgbm1 libasound2 tzdata \
    xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 从构建阶段复制完整项目（正确写法）
COPY --from=builder /app ./

# 无头模式启动
CMD ["xvfb-run", "npm", "run", "dev"]
