<script>
  import { onMount } from 'svelte';
  import { router } from '@inertiajs/svelte';
  import Layout from '../../components/Layout.svelte';
  import { toast } from '../../stores/toast.js';
  import { theme, availableThemes } from '../../stores/theme.js';
  
  let { user } = $props();
  
  let currentTheme = $state('light');
  let formData = $state({
    name: user.name,
    email: user.email
  });
  
  let loading = $state(false);
  
  onMount(() => {
    // Initialize theme store and get current theme
    const savedTheme = theme.init();
    currentTheme = savedTheme;
  });
  
  function setTheme(selectedTheme) {
    console.log('Theme selector changed to:', selectedTheme);
    theme.setTheme(selectedTheme);
    currentTheme = selectedTheme;
    toast.success('Theme updated successfully!');
  }
  

  
  function handleProfileUpdate() {
    loading = true;
    // Here you would typically send the form data to update the user profile
    // For now, we'll just show a success message
    setTimeout(() => {
      loading = false;
      toast.success('Profile updated successfully!');
    }, 1000);
  }
  
  function handleLogout() {
    if (confirm('Are you sure you want to log out?')) {
      toast.info('Logging out...');
      router.delete('/logout');
    }
  }
</script>

<svelte:head>
  <title>Settings - RSID App</title>
</svelte:head>

<Layout {user} currentPage="settings">
  {#snippet children()}
    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-4xl font-bold text-base-content mb-2">Settings</h1>
      <p class="text-base-content/70">Manage your account preferences and profile information.</p>
    </div>



    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Profile Settings -->
      <div class="lg:col-span-2">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
              </svg>
              Profile Settings
            </h2>
            
            <div class="space-y-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Full Name</span>
                </label>
                <input 
                  type="text" 
                  class="input input-bordered" 
                  placeholder="Enter your full name"
                  bind:value={formData.name}
                />
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Email Address</span>
                </label>
                <input 
                  type="email" 
                  class="input input-bordered" 
                  placeholder="Enter your email"
                  bind:value={formData.email}
                />
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Member Since</span>
                </label>
                <input 
                  type="text" 
                  class="input input-bordered" 
                  value={user.created_at}
                  disabled
                />
              </div>
              
              <div class="card-actions justify-end">
                <button 
                  class="btn btn-primary"
                  disabled={loading}
                  onclick={handleProfileUpdate}
                >
                  {#if loading}
                    <span class="loading loading-spinner loading-sm"></span>
                    Updating...
                  {:else}
                    Update Profile
                  {/if}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Sidebar -->
      <div class="space-y-6">
        <!-- Theme Settings -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zM21 5a2 2 0 00-2-2h-4a2 2 0 00-2 2v12a4 4 0 004 4h4a2 2 0 002-2V5z"></path>
              </svg>
              Theme
            </h2>
            
            <div class="form-control">
              <label class="label">
                <span class="label-text">Theme</span>
              </label>
              <select 
                class="select select-bordered w-full"
                bind:value={currentTheme}
                onchange={() => setTheme(currentTheme)}
              >
                {#each availableThemes as themeOption}
                  <option value={themeOption}>
                    {themeOption.charAt(0).toUpperCase() + themeOption.slice(1)}
                  </option>
                {/each}
              </select>
            </div>
            

          </div>
        </div>

        <!-- Account Actions -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
              </svg>
              Account
            </h2>
            
            <div class="space-y-3">
              <button class="btn btn-outline btn-warning w-full">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
                </svg>
                Change Password
              </button>
              
              <button class="btn btn-outline btn-error w-full" onclick={handleLogout}>
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path>
                </svg>
                Logout
              </button>
            </div>
          </div>
        </div>

        <!-- Quick Stats -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
              </svg>
              Account Info
            </h2>
            
            <div class="stats stats-vertical shadow">
              <div class="stat">
                <div class="stat-title">User ID</div>
                <div class="stat-value text-primary">{user.id}</div>
              </div>
              
              <div class="stat">
                <div class="stat-title">Member Since</div>
                <div class="stat-value text-secondary text-lg">{user.created_at}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  {/snippet}
</Layout> 