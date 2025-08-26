<script>
  import { router } from '@inertiajs/svelte';
  import { onMount } from 'svelte';
  
  let { user } = $props();
  
  onMount(() => {
    // Redirect to dashboard immediately after component mounts
    router.visit('/dashboard', { replace: true });
  });
</script>

<svelte:head>
  <title>Redirecting... - RSID App</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-success/10 to-accent/10 flex items-center justify-center">
  <div class="text-center">
    <div class="loading loading-spinner loading-lg text-primary mb-4"></div>
          <h2 class="text-2xl font-bold text-base-content mb-2">Welcome back, {user.name}!</h2>
      <p class="text-base-content/70">Redirecting you to your dashboard...</p>
  </div>
</div> 