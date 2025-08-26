<script>
  import Layout from '../../components/Layout.svelte';
  import { router } from '@inertiajs/svelte';
  
  let { user = null } = $props();
  
  function navigateTo(path) {
    router.visit(path, {
      onSuccess: () => {
        // Refresh the page after navigation
        window.location.reload();
      }
    });
  }
</script>

<svelte:head>
  <title>Home - RSID App</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-primary/10 via-secondary/10 to-accent/10">
  <!-- Navigation -->
  <nav class="bg-base-100 shadow">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between h-16">
        <div class="flex items-center">
          <h1 class="text-xl font-bold text-base-content">RSID App</h1>
        </div>
        
        <div class="flex items-center space-x-4">
          <span class="text-base-content/70">Welcome, {user?.name || 'Guest'}!</span>
          <button 
            onclick={() => navigateTo('/dashboard')}
            class="text-base-content/70 hover:text-base-content px-3 py-2 rounded-md text-sm font-medium"
          >
            Dashboard
          </button>
        </div>
      </div>
    </div>
  </nav>

  <!-- Hero Section -->
  <div class="relative overflow-hidden">
    <div class="max-w-7xl mx-auto">
      <div class="relative z-10 pb-8 sm:pb-16 md:pb-20 lg:max-w-2xl lg:w-full lg:pb-28 xl:pb-32">
        <main class="mt-10 mx-auto max-w-7xl px-4 sm:mt-12 sm:px-6 md:mt-16 lg:mt-20 lg:px-8 xl:mt-28">
          <div class="sm:text-center lg:text-left">
            <h1 class="text-4xl tracking-tight font-extrabold text-base-content sm:text-5xl md:text-6xl">
              <span class="block xl:inline">Welcome to</span>
              <span class="block text-primary xl:inline">RSID App</span>
            </h1>
            <p class="mt-3 text-base text-base-content/70 sm:mt-5 sm:text-lg sm:max-w-xl sm:mx-auto md:mt-5 md:text-xl lg:mx-0">
              A comprehensive grant management system built with Rails 8, Svelte 5, and Inertia.js.
            </p>
            <div class="mt-5 sm:mt-8 sm:flex sm:justify-center lg:justify-start">
              <div class="rounded-md shadow">
                <button 
                  onclick={() => navigateTo('/dashboard')}
                  class="btn btn-primary w-full flex items-center justify-center px-8 py-3 text-base font-medium md:py-4 md:text-lg md:px-10"
                >
                  Get Started
                </button>
              </div>
              <div class="mt-3 sm:mt-0 sm:ml-3">
                <button 
                  onclick={() => navigateTo('/grant_applications')}
                  class="btn btn-outline w-full flex items-center justify-center px-8 py-3 text-base font-medium md:py-4 md:text-lg md:px-10"
                >
                  View Applications
                </button>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  </div>

  <!-- Features Section -->
  <div class="py-12 bg-base-100">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="lg:text-center">
        <h2 class="text-base text-primary font-semibold tracking-wide uppercase">Features</h2>
        <p class="mt-2 text-3xl leading-8 font-extrabold tracking-tight text-base-content sm:text-4xl">
          Everything you need to manage grants
        </p>
        <p class="mt-4 max-w-2xl text-xl text-base-content/70 lg:mx-auto">
          Built with modern technologies and best practices for a seamless user experience.
        </p>
      </div>

      <div class="mt-10">
        <dl class="space-y-10 md:space-y-0 md:grid md:grid-cols-2 md:gap-x-8 md:gap-y-10">
          <div class="relative">
            <dt>
              <div class="absolute flex items-center justify-center h-12 w-12 rounded-md bg-primary text-primary-content">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <p class="ml-16 text-lg leading-6 font-medium text-base-content">Rails 8 Backend</p>
            </dt>
            <dd class="mt-2 ml-16 text-base text-base-content/70">
              Latest Rails framework with modern Ruby features and excellent performance.
            </dd>
          </div>

          <div class="relative">
            <dt>
              <div class="absolute flex items-center justify-center h-12 w-12 rounded-md bg-primary text-primary-content">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
              </div>
              <p class="ml-16 text-lg leading-6 font-medium text-base-content">Svelte 5 Frontend</p>
            </dt>
            <dd class="mt-2 ml-16 text-base text-base-content/70">
              Cutting-edge reactive framework with the new runes syntax for optimal performance.
            </dd>
          </div>

          <div class="relative">
            <dt>
              <div class="absolute flex items-center justify-center h-12 w-12 rounded-md bg-primary text-primary-content">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                </svg>
              </div>
              <p class="ml-16 text-lg leading-6 font-medium text-base-content">Inertia.js</p>
            </dt>
            <dd class="mt-2 ml-16 text-base text-base-content/70">
              Seamless SPA experience with server-side rendering capabilities.
            </dd>
          </div>

          <div class="relative">
            <dt>
              <div class="absolute flex items-center justify-center h-12 w-12 rounded-md bg-primary text-primary-content">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <p class="ml-16 text-lg leading-6 font-medium text-base-content">User Authentication</p>
            </dt>
            <dd class="mt-2 ml-16 text-base text-base-content/70">
              Secure authentication system with role-based access control.
            </dd>
          </div>
        </dl>
      </div>
    </div>
  </div>
</div> 