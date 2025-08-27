<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../stores/toast.js';
  import NotificationBell from './NotificationBell.svelte';
  
  let { user, currentPage = 'dashboard' } = $props();
  

  
  function handleLogout() {
    if (confirm('Are you sure you want to log out?')) {
      toast.info('Logging out...');
      router.delete('/logout');
    }
  }
  
  function isActive(page) {
    return currentPage === page;
  }
  
  function navigateTo(path) {
    router.visit(path);
  }
</script>

<nav class="bg-base-100 shadow-lg border-b border-base-300">
  <div class="container mx-auto px-4">
    <div class="flex items-center justify-between h-16">
      <!-- Left side -->
      <div class="flex items-center">
        <!-- Menu button -->
        <div class="dropdown">
          <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h8m-8 6h16"></path>
            </svg>
          </div>
          <ul class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
            {#if user}
              <li><button onclick={() => navigateTo('/dashboard')} class:active={isActive('dashboard')}>Dashboard</button></li>
              <li><button onclick={() => navigateTo('/search')} class:active={isActive('search')}>🔍 Search</button></li>
              <li><button onclick={() => navigateTo('/notes')} class:active={isActive('notes')}>Notes</button></li>
              <li><button onclick={() => navigateTo('/todos')} class:active={isActive('todos')}>Todo List</button></li>
              <li><button onclick={() => navigateTo('/file_items')} class:active={isActive('files')}>Files</button></li>
              
              <!-- Employee/Admin only features -->
              {#if user.isEmployee || user.isAdmin}
                <li><button onclick={() => navigateTo('/messages')} class:active={isActive('messages')}>Messages</button></li>
              {/if}
              
              <li><button onclick={() => navigateTo('/grant_applications')} class:active={isActive('grant_applications')}>Grant Applications</button></li>
              <li><button onclick={() => navigateTo('/rnd_projects')} class:active={isActive('rnd_projects')}>R&D Projects</button></li>
              
              <!-- Admin only features -->
              {#if user.isAdmin}
                <li><button onclick={() => navigateTo('/people')} class:active={isActive('people')}>People</button></li>
                <li><button onclick={() => navigateTo('/admin/feature_flags')} class:active={isActive('feature_flags')}>Feature Flags</button></li>
                <li><button onclick={() => navigateTo('/inspector')} class:active={isActive('inspector')}>🔍 App Inspector</button></li>
              {/if}
              
              <li><button onclick={() => navigateTo('/settings')} class:active={isActive('settings')}>Settings</button></li>
            {:else}
              <!-- Show minimal navigation for logged out users -->
              <li><button onclick={() => navigateTo('/login')}>Login</button></li>
              <li><button onclick={() => navigateTo('/signup')}>Sign Up</button></li>
            {/if}
          </ul>
        </div>
        
        <!-- App title -->
        <button class="btn btn-ghost text-xl ml-2" onclick={() => navigateTo('/dashboard')}>RSID App</button>
        
        <!-- Debug indicator for admin -->
        {#if user?.isAdmin}
          <div class="badge badge-primary ml-2">ADMIN</div>
        {/if}
      </div>

      <!-- Right side -->
      <div class="flex items-center gap-2">
        {#if user}
          <!-- Notification Bell -->
          <NotificationBell {user} unreadCount={0} />
          
          <div class="dropdown dropdown-end">
            <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
              <div class="avatar placeholder">
                <div class="bg-neutral text-neutral-content rounded-full w-10">
                  <span class="text-xs">{user.name.split(' ').map(n => n[0]).join('')}</span>
                </div>
              </div>
            </div>
            <ul class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
              <li><span class="text-xs opacity-70">{user.role} {user.isAdmin ? '(Admin)' : ''}</span></li>
              <li><button onclick={() => navigateTo('/settings')}>Profile</button></li>
              <li><button onclick={() => navigateTo('/settings')}>Settings</button></li>
              <li><button onclick={handleLogout}>Logout</button></li>
            </ul>
          </div>
        {:else}
          <!-- Show login/signup buttons for logged out users -->
          <div class="flex space-x-2">
            <button class="btn btn-ghost btn-sm" onclick={() => navigateTo('/login')}>Login</button>
            <button class="btn btn-primary btn-sm" onclick={() => navigateTo('/signup')}>Sign Up</button>
          </div>
        {/if}
      </div>
    </div>
  </div>
</nav>

<style>
  .active {
    background-color: hsl(var(--b2));
  }
</style> 