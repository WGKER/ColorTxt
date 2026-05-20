FROM --platform=linux/arm64 node:22-bookworm-slim

WORKDIR /app

# 安装依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 \
    libgtk-3-0 libnss3 libxss1 libasound2 libx11-xcb1 libxkbfile1 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# 复制项目
COPY . .

# 安装依赖
RUN npm install

# 直接运行（不执行会报错的 build）
CMD ["xvfb-run", "npm", "run", "dev"]
