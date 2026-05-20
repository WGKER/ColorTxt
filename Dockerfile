# 构建阶段
FROM --platform=linux/arm64 node:20-bookworm-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build -- --linux arm64

# 运行阶段
FROM --platform=linux/arm64 debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libxss1 libasound2 libx11-xcb1 libxkbfile1 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/dist/linux-arm64-unpacked .

# 🟢 定义容器内目录：用于存放书籍、配置、缓存
VOLUME ["/app/books", "/app/config", "/app/cache"]

# 无头运行
CMD ["xvfb-run", "./ColorTxt"]
