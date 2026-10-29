import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// Servislerde CORS yok; geliştirmede istekler Vite üzerinden aynı origin'den geçer.
const proxy = (target: string, prefix: string) => ({
  target,
  changeOrigin: true,
  rewrite: (path: string) => path.replace(new RegExp(`^${prefix}`), ''),
})

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/identity': proxy('http://localhost:5101', '/identity'),
      '/institution': proxy('http://localhost:5102', '/institution'),
    },
  },
})
