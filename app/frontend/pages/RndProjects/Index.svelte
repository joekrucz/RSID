<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Select from '../../components/forms/Select.svelte';
  
  let { user, rnd_projects, search, status_filter, client_filter, sort_by, sort_order, can_create_projects, can_manage_projects, stats, clients } = $props();
  
  let searchQuery = $state(search || '');
  let currentStatusFilter = $state(status_filter || '');
  let currentClientFilter = $state(client_filter || '');
  let currentSortBy = $state(sort_by || 'created_at');
  let currentSortOrder = $state(sort_order || 'desc');
  let showFilters = $state(false);
  
  function handleSearch() {
    router.get('/rnd_projects', {
      search: searchQuery || undefined,
      status_filter: currentStatusFilter || undefined,
      client_filter: currentClientFilter || undefined,
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  function clearFilters() {
    searchQuery = '';
    currentStatusFilter = '';
    currentClientFilter = '';
    router.get('/rnd_projects', {
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  function handleSort(sortBy) {
    let newSortOrder = 'desc';
    if (currentSortBy === sortBy) {
      newSortOrder = currentSortOrder === 'desc' ? 'asc' : 'desc';
    }
    
    currentSortBy = sortBy;
    currentSortOrder = newSortOrder;
    
    router.get('/rnd_projects', {
      search: searchQuery || undefined,
      status_filter: currentStatusFilter || undefined,
      client_filter: currentClientFilter || undefined,
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  function deleteProject(projectId, projectTitle) {
    if (confirm(`Are you sure you want to delete "${projectTitle}"? This action cannot be undone.`)) {
      router.delete(`/rnd_projects/${projectId}`, {
        onSuccess: () => {
          toast.success('R&D Project deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete R&D Project.');
        }
      });
    }
  }
  
  function navigateTo(path) {
    router.visit(path);
  }
  
  function getStatusBadgeClass(status) {
    switch (status) {
      case 'draft':
        return 'badge-neutral';
      case 'active':
        return 'badge-info';
      case 'completed':
        return 'badge-success';
      case 'ready_for_claim':
        return 'badge-warning';
      default:
        return 'badge-neutral';
    }
  }
  
  function getStatusDisplayName(status) {
    return status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
  }
  
  function getSortIcon(sortBy) {
    if (currentSortBy !== sortBy) return '↕️';
    return currentSortOrder === 'desc' ? '↓' : '↑';
  }
  
  function formatCurrency(amount) {
    return new Intl.NumberFormat('en-GB', {
      style: 'currency',
      currency: 'GBP'
    }).format(amount || 0);
  }
</script>

<svelte:head>
  <title>R&D Projects - RSID App</title>
</svelte:head>

<Layout {user}>
    <!-- Header -->
    <div class="mb-8">
      <div class="flex justify-between items-center mb-4">
        <div>
          <h1 class="text-3xl font-bold text-base-content mb-2">R&D Projects</h1>
          <p class="text-base-content/70">Manage research and development projects for tax credit claims</p>
        </div>
        {#if can_create_projects}
          <Button variant="primary" onclick={() => navigateTo('/rnd_projects/new')}>
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
            </svg>
            New R&D Project
          </Button>
        {/if}
      </div>
      
      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-4 mb-6">
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Total Projects</div>
          <div class="stat-value text-primary">{stats.total}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Draft</div>
          <div class="stat-value text-neutral">{stats.draft}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Active</div>
          <div class="stat-value text-info">{stats.active}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Completed</div>
          <div class="stat-value text-success">{stats.completed}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Ready for Claim</div>
          <div class="stat-value text-warning">{stats.ready_for_claim}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Total Expenditure</div>
          <div class="stat-value text-accent">{formatCurrency(stats.total_expenditure)}</div>
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
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div class="form-control">
            <label class="label">
              <span class="label-text">Search</span>
            </label>
            <input
              type="text"
              placeholder="Search by title or description..."
              class="input input-bordered w-full"
              bind:value={searchQuery}
              onkeyup={(e) => e.key === 'Enter' && handleSearch()}
            />
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Status</span>
            </label>
            <Select
              bind:value={currentStatusFilter}
              options={[
                { value: '', label: 'All Statuses' },
                { value: 'draft', label: 'Draft' },
                { value: 'active', label: 'Active' },
                { value: 'completed', label: 'Completed' },
                { value: 'ready_for_claim', label: 'Ready for Claim' }
              ]}
            />
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Client</span>
            </label>
            <Select
              bind:value={currentClientFilter}
              options={[
                { value: '', label: 'All Clients' },
                ...clients.map(client => ({ value: client.id.toString(), label: client.name }))
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
    
    <!-- Projects List -->
    <div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
      {#if rnd_projects && rnd_projects.length > 0}
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>
                  <button onclick={() => handleSort('title')} class="flex items-center space-x-1">
                    <span>Project</span>
                    <span class="text-xs">{getSortIcon('title')}</span>
                  </button>
                </th>
                <th>
                  <button onclick={() => handleSort('client')} class="flex items-center space-x-1">
                    <span>Client</span>
                    <span class="text-xs">{getSortIcon('client')}</span>
                  </button>
                </th>
                <th>
                  <button onclick={() => handleSort('start_date')} class="flex items-center space-x-1">
                    <span>Duration</span>
                    <span class="text-xs">{getSortIcon('start_date')}</span>
                  </button>
                </th>
                <th>
                  <button onclick={() => handleSort('total_expenditure')} class="flex items-center space-x-1">
                    <span>Expenditure</span>
                    <span class="text-xs">{getSortIcon('total_expenditure')}</span>
                  </button>
                </th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {#each rnd_projects as project}
                <tr>
                  <td>
                    <div class="flex items-center space-x-3">
                      <div class="avatar placeholder">
                        <div class="bg-primary text-primary-content rounded-full w-8">
                          <span class="text-xs">R&D</span>
                        </div>
                      </div>
                      <div>
                        <div class="font-bold">{project.title}</div>
                        <div class="text-sm opacity-50 line-clamp-1">{project.description}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div>
                      <div class="font-medium">{project.client.name}</div>
                      <div class="text-sm opacity-50">{project.client.email}</div>
                    </div>
                  </td>
                  <td>
                    <div class="text-sm">
                      {project.start_date} - {project.end_date}
                    </div>
                    <div class="text-xs opacity-50">
                      {project.duration_days} days
                    </div>
                  </td>
                  <td>
                    <div class="font-medium">{formatCurrency(project.total_expenditure)}</div>
                    {#if project.can_be_claimed}
                      <div class="text-xs text-success">Ready to claim</div>
                    {/if}
                  </td>
                  <td>
                    <div class="badge {getStatusBadgeClass(project.status)}">
                      {getStatusDisplayName(project.status)}
                    </div>
                  </td>
                  <td>
                    <div class="flex items-center space-x-2">
                      <button 
                        onclick={() => navigateTo(`/rnd_projects/${project.id}`)}
                        class="btn btn-sm btn-ghost"
                        title="View Details"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                        </svg>
                      </button>
                      {#if can_manage_projects}
                        <button 
                          onclick={() => navigateTo(`/rnd_projects/${project.id}/edit`)}
                          class="btn btn-sm btn-ghost"
                          title="Edit Project"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          </svg>
                        </button>
                        <button 
                          onclick={() => deleteProject(project.id, project.title)}
                          class="btn btn-sm btn-ghost text-error"
                          title="Delete Project"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                          </svg>
                        </button>
                      {/if}
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
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"></path>
            </svg>
            <h3 class="text-lg font-medium text-base-content mb-2">No R&D projects found</h3>
            <p class="text-base-content/70 mb-6">
              {searchQuery || currentStatusFilter || currentClientFilter ? 'Try adjusting your search terms' : 'No R&D projects have been created yet'}
            </p>
            {#if can_create_projects}
              <Button variant="primary" onclick={() => navigateTo('/rnd_projects/new')}>
                Create First R&D Project
              </Button>
            {/if}
          </div>
        </div>
      {/if}
    </div>
</Layout>

<style>
  .line-clamp-1 {
    display: -webkit-box;
    -webkit-line-clamp: 1;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
</style> 