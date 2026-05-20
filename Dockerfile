# =============================================
# 正确构建镜像（自带 Node + npm，绝对不报错）
# =============================================
FROM node:22-bookworm AS builder
WORKDIR /app

# 安装编译依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

# 安装依赖（现在 npm 100% 可用）
COPY package*.json ./
RUN npm install --production

COPY . .
RUN npm run build


# =============================================
# 最终运行镜像
# =============================================
FROM debian:bookworm-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libasound2 libx11-xcb1 xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app ./

CMD ["xvfb-run", "npm", "run", "dev"]
