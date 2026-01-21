import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  root: '.', // 显式指定根目录，虽然默认就是当前目录
  base: './', // 使用相对路径，支持 Electron file:// 协议
  build: {
    outDir: '../dist', // 构建到项目根目录下的 dist
    emptyOutDir: true
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:9292',
        changeOrigin: true
      },
      '/ca.crt': {
        target: 'http://localhost:9292',
        changeOrigin: true
      }
    }
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  }
})