import axios from 'axios'

// 检测是否在 Electron 环境中运行（通过 file:// 协议判断）
export const isElectron = window.location.protocol === 'file:'

// API 基础 URL
export const baseURL = isElectron ? 'http://localhost:9292' : ''

// 创建 axios 实例，Electron 环境使用完整的后端 URL
const api = axios.create({
  baseURL
})

export default api
