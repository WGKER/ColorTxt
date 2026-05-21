# 直接用ARM64环境构建 + 运行，彻底避免跨平台打包崩溃
FROM arm64v8/node:20-bullseye

# 设置工作目录
WORKDIR /app

# 安装系统依赖（Electron + 中文环境必备）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnotify4 libnss3 libxss1 libasound2 \
    libdrm2 libgbm1 libx11-xcb1 libxcb-dri3-0 \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY package*.json ./

# 安装依赖（淘宝源）
RUN npm config set registry https://registry.npmmirror.com/ && \
    npm install --legacy-peer-deps

# 复制全部项目代码
COPY . .

# 只编译，不打包（彻底避开打包失败问题）
RUN npm run build

# 暴露Web端口 1567
EXPOSE 1567

# 直接启动编译好的应用（Docker无沙箱模式）
CMD ["npm", "run", "start", "--", "--no-sandbox", "--port=1567", "--host=0.0.0.0"]
