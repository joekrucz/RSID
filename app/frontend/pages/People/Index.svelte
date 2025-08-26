<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Select from '../../components/forms/Select.svelte';
  
  let { user, people, search, role_filter, sort_by, sort_order, can_manage_roles, can_create_people, stats } = $props();
  
  let searchQuery = $state(search || '');
  let currentRoleFilter = $state(role_filter || '');
  let currentSortBy = $state(sort_by || 'name');
  let currentSortOrder = $state(sort_order || 'asc');
  let showFilters = $state(false);
  
  function handleSearch() {
    router.get('/people', {
      search: searchQuery || undefined,
      role_filter: currentRoleFilter || undefined,
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  function clearFilters() {
    searchQuery = '';
    currentRoleFilter = '';
    router.get('/people', {
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  function handleSort(sortBy) {
    let newSortOrder = 'asc';
    if (currentSortBy === sortBy) {
      newSortOrder = currentSortOrder === 'asc' ? 'desc' : 'asc';
    }
    
    currentSortBy = sortBy;
    currentSortOrder = newSortOrder;
    
    router.get('/people', {
      search: searchQuery || undefined,
      role_filter: currentRoleFilter || undefined,
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  function promoteUser(userId) {
    if (confirm('Are you sure you want to promote this user to admin?')) {
      router.patch(`/people/${userId}/update_role`, { role: 'admin' }, {
        onSuccess: () => {
          toast.success('User promoted to admin successfully!');
        },
        onError: () => {
          toast.error('Failed to promote user.');
        }
      });
    }
  }
  
  function demoteUser(userId) {
    if (confirm('Are you sure you want to demote this user to client?')) {
      router.patch(`/people/${userId}/update_role`, { role: 'client' }, {
        onSuccess: () => {
          toast.success('User demoted to client successfully!');
        },
        onError: () => {
          toast.error('Failed to demote user.');
        }
      });
    }
  }
  
  function deleteUser(userId, userName) {
    if (confirm(`Are you sure you want to delete ${userName}? This action cannot be undone.`)) {
      router.delete(`/people/${userId}`, {
        onSuccess: () => {
          toast.success('User deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete user.');
        }
      });
    }
  }
  
  function navigateTo(path) {
    router.visit(path);
  }
  
  function getRoleBadgeClass(role) {
    switch (role) {
      case 'admin':
        return 'badge-error';
      case 'employee':
        return 'badge-warning';
      case 'client':
        return 'badge-info';
      default:
        return 'badge-neutral';
    }
  }
  
  function getRoleDisplayName(role) {
    return role.charAt(0).toUpperCase() + role.slice(1);
  }
  
  function getSortIcon(sortBy) {
    if (currentSortBy !== sortBy) return '↕️';
    return currentSortOrder === 'desc' ? '↓' : '↑';
  }
</script>

<svelte:head>
  <title>People Management - RSID App</title>
</svelte:head>

<Layout {user}>
    <!-- Header -->
    <div class="mb-8">
      <div class="flex justify-between items-center mb-4">
        <div>
          <h1 class="text-3xl font-bold text-base-content mb-2">People Management</h1>
          <p class="text-base-content/70">Manage users, employees, and clients in one place</p>
        </div>
        {#if can_create_people}
          <Button variant="primary" onclick={() => navigateTo('/people/new')}>
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
            </svg>
            Add Person
          </Button>
        {/if}
      </div>
      
      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Total People</div>
          <div class="stat-value text-primary">{stats.total}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Clients</div>
          <div class="stat-value text-info">{stats.clients}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Employees</div>
          <div class="stat-value text-warning">{stats.employees}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Admins</div>
          <div class="stat-value text-error">{stats.admins}</div>
        </div>
      </div>
    </div>
    
    <!-- Filters -->
    <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6 mb-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-base-content">Filters</h3>
        <button 
          class="btn btn-ghost btn-sm"
          onclick={() => showFilters = !showFilters}
        >
          {showFilters ? 'Hide' : 'Show'} Filters
        </button>
      </div>
      
      {#if showFilters}
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="form-control">
            <label class="label">
              <span class="label-text">Search</span>
            </label>
            <input
              type="text"
              placeholder="Search by name or email..."
              class="input input-bordered w-full"
              bind:value={searchQuery}
              onkeyup={(e) => e.key === 'Enter' && handleSearch()}
            />
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Role</span>
            </label>
            <Select
              bind:value={currentRoleFilter}
              options={[
                { value: '', label: 'All Roles' },
                { value: 'client', label: 'Clients' },
                { value: 'employee', label: 'Employees' },
                { value: 'admin', label: 'Admins' }
              ]}
            />
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Actions</span>
            </label>
            <div class="flex space-x-2">
              <Button variant="outline" onclick={handleSearch} class="flex-1">
                Apply Filters
              </Button>
              <Button variant="ghost" onclick={clearFilters} class="flex-1">
                Clear
              </Button>
            </div>
          </div>
        </div>
      {/if}
    </div>
    
    <!-- People List -->
    <div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
      {#if people && people.length > 0}
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>
                  <button onclick={() => handleSort('name')} class="flex items-center space-x-1">
                    <span>Name</span>
                    <span class="text-xs">{getSortIcon('name')}</span>
                  </button>
                </th>
                <th>
                  <button onclick={() => handleSort('email')} class="flex items-center space-x-1">
                    <span>Email</span>
                    <span class="text-xs">{getSortIcon('email')}</span>
                  </button>
                </th>
                <th>
                  <button onclick={() => handleSort('role')} class="flex items-center space-x-1">
                    <span>Role</span>
                    <span class="text-xs">{getSortIcon('role')}</span>
                  </button>
                </th>
                <th>
                  <button onclick={() => handleSort('created_at')} class="flex items-center space-x-1">
                    <span>Joined</span>
                    <span class="text-xs">{getSortIcon('created_at')}</span>
                  </button>
                </th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {#each people as person}
                <tr>
                  <td>
                    <div class="flex items-center space-x-3">
                      <div class="avatar placeholder">
                        <div class="bg-neutral text-neutral-content rounded-full w-8">
                          <span class="text-xs">{person.name.charAt(0).toUpperCase()}</span>
                        </div>
                      </div>
                      <div>
                        <div class="font-bold">{person.name}</div>
                      </div>
                    </div>
                  </td>
                  <td>{person.email}</td>
                  <td>
                    <div class="badge {getRoleBadgeClass(person.role)}">
                      {getRoleDisplayName(person.role)}
                    </div>
                  </td>
                  <td>
                    <div class="text-sm">{person.created_at}</div>
                  </td>
                  <td>
                    <div class="dropdown dropdown-end">
                      <div tabindex="0" role="button" class="btn btn-sm btn-ghost">
                        Actions
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                        </svg>
                      </div>
                      <ul class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
                        <li>
                          <button onclick={() => navigateTo(`/people/${person.id}`)} class="w-full text-left">View Details</button>
                        </li>
                        {#if can_manage_roles && person.id !== user.id}
                          {#if person.role !== 'admin'}
                            <li>
                              <button onclick={() => promoteUser(person.id)} class="w-full text-left">Promote to Admin</button>
                            </li>
                          {:else}
                            <li>
                              <button onclick={() => demoteUser(person.id)} class="w-full text-left text-error">Demote to Client</button>
                            </li>
                          {/if}
                          <li>
                            <button onclick={() => deleteUser(person.id, person.name)} class="w-full text-left text-error">Delete</button>
                          </li>
                        {/if}
                      </ul>
                    </div>
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      {:else}
        <div class="text-center py-12">
          <div class="text-base-content/50 mb-4">
            <svg class="w-16 h-16 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
            </svg>
            <h3 class="text-lg font-medium text-base-content mb-2">No people found</h3>
            <p class="text-base-content/70 mb-6">
              {searchQuery || currentRoleFilter ? 'Try adjusting your search terms' : 'No people have been added yet'}
            </p>
            {#if can_create_people}
              <Button variant="primary" onclick={() => navigateTo('/people/new')}>
                Add First Person
              </Button>
            {/if}
          </div>
        </div>
      {/if}
    </div>
</Layout> 