<script>
  import Navbar from './Navbar.svelte';
  import Toast from './Toast.svelte';
  
  let { user, currentPage = 'dashboard', children } = $props();
</script>

<div class="min-h-screen bg-base-200">
  <div class="sticky top-0 z-50 bg-base-100">
    <Navbar {user} {currentPage} />
  </div>
  
  <main class="container mx-auto px-4 py-8">
    {@render children()}
  </main>
  
  <Toast />
</div> 