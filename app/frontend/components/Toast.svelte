<script>
  import { createEventDispatcher } from 'svelte';
  import { toast } from '../stores/toast.js';
  
  const dispatch = createEventDispatcher();
  
  let timeoutId;
  let toastState = $state({
    message: '',
    type: 'info',
    duration: 5000,
    show: false
  });
  
  // Subscribe to the toast store
  $effect(() => {
    const unsubscribe = toast.subscribe((state) => {
      toastState = state;
      
      if (state.show && state.message) {
        // Clear any existing timeout
        if (timeoutId) clearTimeout(timeoutId);
        
        // Auto-dismiss after duration
        timeoutId = setTimeout(() => {
          toast.hide();
        }, state.duration);
      }
    });
    
    return unsubscribe;
  });
  
  function handleClose() {
    if (timeoutId) clearTimeout(timeoutId);
    toast.hide();
  }
  
  function getIcon() {
    switch (toastState.type) {
      case 'success':
        return `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>`;
      case 'error':
        return `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"></path>`;
      case 'warning':
        return `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>`;
      default:
        return `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>`;
    }
  }
  
  function getAlertClass() {
    const baseClass = 'alert shadow-lg transition-all duration-300 ease-in-out';
    switch (toastState.type) {
      case 'success':
        return `${baseClass} alert-success`;
      case 'error':
        return `${baseClass} alert-error`;
      case 'warning':
        return `${baseClass} alert-warning`;
      default:
        return `${baseClass} alert-info`;
    }
  }
</script>

{#if toastState.show && toastState.message}
  <div class="fixed top-4 right-4 z-50 max-w-sm w-full">
    <div class={getAlertClass()}>
      <svg class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        {@html getIcon()}
      </svg>
      <div class="flex-1">
        <span class="font-medium">{toastState.message}</span>
      </div>
      <button 
        class="btn btn-sm btn-ghost"
        onclick={handleClose}
        aria-label="Close notification"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </button>
    </div>
  </div>
{/if} 