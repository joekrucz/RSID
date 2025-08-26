import { writable } from 'svelte/store';

function createThemeStore() {
  // Initialize with default theme
  const { subscribe, set, update } = writable('light');

  return {
    subscribe,
    
    // Initialize theme from localStorage on app start
    init: () => {
      if (typeof window !== 'undefined') {
        const savedTheme = localStorage.getItem('daisyui-theme') || 'light';
        document.documentElement.setAttribute('data-theme', savedTheme);
        set(savedTheme);
        return savedTheme;
      }
      return 'light';
    },
    
    // Set a new theme
    setTheme: (theme) => {
      if (typeof window !== 'undefined') {
        console.log('Setting theme to:', theme);
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('daisyui-theme', theme);
        set(theme);
      }
    },
    
    // Get current theme
    getCurrentTheme: () => {
      if (typeof window !== 'undefined') {
        return localStorage.getItem('daisyui-theme') || 'light';
      }
      return 'light';
    }
  };
}

export const theme = createThemeStore();

// Available themes
export const availableThemes = [
  'light', 'dark', 'cyberpunk', 'bumblebee', 'emerald', 'corporate', 
  'synthwave', 'retro', 'valentine', 'halloween', 'garden', 'forest', 
  'aqua', 'lofi', 'pastel', 'fantasy', 'wireframe', 'black', 'luxury', 
  'dracula', 'cmyk', 'autumn', 'business', 'acid', 'lemonade', 'night', 
  'coffee', 'winter'
]; 