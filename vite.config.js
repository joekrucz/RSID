import { svelte } from '@sveltejs/vite-plugin-svelte'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import path from 'path'

export default defineConfig({
  plugins: [
   svelte(),
   tailwindcss(),
   RubyPlugin(),
  ],
  server: {
   host: 'localhost',
   strictPort: true,
   hmr: {
    host: 'localhost'
   }
  },
  resolve: {
   alias: {
     '@components': path.resolve(__dirname, 'app/frontend/components')
   }
  },
  build: {
    rollupOptions: {
      output: {
        // Disable CSS code splitting to avoid preload warnings
        manualChunks: undefined,
        assetFileNames: (assetInfo) => {
          // Keep CSS files together to avoid preload issues
          if (assetInfo.name && assetInfo.name.endsWith('.css')) {
            return 'assets/[name]-[hash][extname]'
          }
          return 'assets/[name]-[hash][extname]'
        }
      }
    }
  },
  css: {
    // Ensure CSS is processed correctly
    devSourcemap: true
  },
  // Optimize CSS handling for Inertia.js
  optimizeDeps: {
    include: ['@inertiajs/svelte']
  }
 })
