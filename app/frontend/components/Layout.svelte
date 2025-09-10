<script>
  import { onMount } from 'svelte';
  import Navbar from './Navbar.svelte';
  import Toast from './Toast.svelte';
  import { setAvailableFeatures } from '../stores/features.js';
  
  let { user, currentPage = 'dashboard', children, fullWidth = false } = $props();
  
  onMount(() => {
    if (user?.availableFeatures) {
      setAvailableFeatures(user.availableFeatures);
    }
  });
</script>

<div class="min-h-screen bg-base-200">
  <div class="sticky top-0 z-50 bg-base-100">
    <Navbar {user} {currentPage} />
  </div>
  
  <main class="{fullWidth ? 'w-full px-0' : 'container mx-auto px-4'} py-8">
    {@render children()}
  </main>
  
  <Toast />
</div> 