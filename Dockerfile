# =============================================
# 构建阶段（完整环境，编译完就扔）
# 只用来编译，不进最终镜像
# =============================================
FROM node:22-bookworm AS builder
WORKDIR /app

# 安装编译工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

# 安装依赖
COPY package*.json ./
RUN npm ci --only=production --force

# 复制代码
COPY . .

# 只编译，不打包
RUN npm run build


# =============================================
# 🔥 最终运行阶段（超小体积：100MB 级别）
# =============================================
FROM debian:bookworm-slim
WORKDIR /app

# 只装 Electron 必须的最小依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libdrm2 libxkbcommon0 libxdamage1 \
    libx11-xcb1 libxcb-dri3-0 libgbm1 libasound2 tzdata \
    xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 只复制运行必需文件（超级小）
COPY --from=builder /app ./
COPY --from=builder /app/node_modules ./node_modules

# 运行（无头模式）
CMD ["xvfb-run", "npm", "run", "dev"]
