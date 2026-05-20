# =============================================
# 构建阶段（标准 Node，不影响体积）
# =============================================
FROM node:22-bookworm AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci --only=production  # 只装生产依赖，更小
COPY . .

RUN npm run build


# =============================================
# ✅ 运行阶段：超小底包（node:slim 最小可用）
# =============================================
FROM node:22-bookworm-slim  # 👈 这是最小能用的官方底包
WORKDIR /app

# 只装必须的系统库
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libasound2 libx11-xcb1 libxkbfile1 xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 复制应用
COPY --from=builder /app .

# 启动
CMD ["xvfb-run", "npm", "run", "dev"]
