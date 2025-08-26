import { writable } from 'svelte/store';

function createToastStore() {
  const { subscribe, set, update } = writable({
    message: '',
    type: 'info',
    show: false,
    duration: 5000
  });

  return {
    subscribe,
    show: (message, type = 'info', duration = 5000) => {
      set({ message, type, show: true, duration });
    },
    success: (message, duration = 5000) => {
      set({ message, type: 'success', show: true, duration });
    },
    error: (message, duration = 5000) => {
      set({ message, type: 'error', show: true, duration });
    },
    warning: (message, duration = 5000) => {
      set({ message, type: 'warning', show: true, duration });
    },
    info: (message, duration = 5000) => {
      set({ message, type: 'info', show: true, duration });
    },
    hide: () => {
      update(state => ({ ...state, show: false }));
    },
    reset: () => {
      set({ message: '', type: 'info', show: false, duration: 5000 });
    }
  };
}

export const toast = createToastStore(); 