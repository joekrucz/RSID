<script>
  import { onMount } from 'svelte';
  import { router } from '@inertiajs/svelte';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  
  let { user, rnd_claims, filters, pagination, stats } = $props();
  
  let search = $state(filters.search || '');
  let currentPage = $state(pagination?.current_page || 1);
  let perPage = $state(filters.per_page || 25);
  
  // Use server-side pagination and search
  let filteredClaims = $state(rnd_claims);
  
  // Update data when props change
  $effect(() => {
    filteredClaims = rnd_claims;
  });
  
  function loadPage(page) {
    const params = new URLSearchParams();
    if (search.trim()) params.set('search', search);
    if (perPage !== 25) params.set('per_page', perPage);
    if (page > 1) params.set('page', page);
    
    const queryString = params.toString();
    const url = queryString ? `/cnf_comms?${queryString}` : '/cnf_comms';
    
    router.get(url, {}, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  let searchTimeout;
  
  function handleSearch() {
    // Clear existing timeout
    if (searchTimeout) {
      clearTimeout(searchTimeout);
    }
    
    // Debounce search to avoid too many requests
    searchTimeout = setTimeout(() => {
      loadPage(1); // Reset to first page when searching
    }, 300);
  }
  
  function handlePerPageChange(newPerPage) {
    perPage = newPerPage;
    loadPage(1); // Reset to first page when changing per page
  }
  
  function goToPage(page) {
    loadPage(page);
  }
  
  function getPriorityColor(priority) {
    switch(priority) {
      case 'high': return 'badge-error';
      case 'medium': return 'badge-warning';
      case 'low': return 'badge-success';
      default: return 'badge-neutral';
    }
  }
  
  function getCategoryColor(category) {
    switch(category) {
      case 'announcement': return 'badge-primary';
      case 'maintenance': return 'badge-warning';
      case 'feature': return 'badge-success';
      case 'update': return 'badge-info';
      default: return 'badge-neutral';
    }
  }
</script>

<svelte:head>
  <title>CNF Comms - RSID App</title>
</svelte:head>

<Layout {user} currentPage="cnf_comms">
  <div class="max-w-7xl mx-auto">
    <!-- Header -->
    <div class="mb-6">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold text-base-content">CNF Communications</h1>
          <p class="text-base-content/70 mt-1">Track CNF status and deadlines for R&D claims</p>
        </div>
        
        <div class="flex items-center space-x-3">
          <Button variant="primary" onclick={() => router.visit('/rnd_claims/new')}>
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
            </svg>
            New R&D Claim
          </Button>
        </div>
      </div>
      
      <!-- Search and Controls -->
      <div class="mt-6 bg-base-100 rounded-lg shadow border border-base-300 p-4">
        <div class="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
          <!-- Search Bar -->
          <div class="flex-1 max-w-md">
            <div class="join w-full">
              <input
                type="text"
                bind:value={search}
                oninput={handleSearch}
                placeholder="Search R&D claims..."
                class="input input-bordered join-item flex-1"
              />
              {#if search}
                <button 
                  class="btn btn-outline join-item"
                  onclick={() => { search = ''; handleSearch(); }}
                  aria-label="Clear search"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                  </svg>
                </button>
              {/if}
            </div>
          </div>
          
          <!-- Per Page Selector -->
          <div class="flex items-center space-x-2">
            <span class="text-sm font-medium text-base-content">Per page:</span>
            <select 
              bind:value={perPage} 
              onchange={() => handlePerPageChange(perPage)}
              class="select select-bordered select-sm"
            >
              <option value="10">10</option>
              <option value="25">25</option>
              <option value="50">50</option>
              <option value="100">100</option>
            </select>
          </div>
        </div>
      </div>
      
      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6 mt-8">
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Total Claims</div>
          <div class="stat-value text-primary">{stats.total}</div>
        </div>
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">CNF Needed</div>
          <div class="stat-value text-error">{stats.cnf_needed}</div>
        </div>
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">CNF Overdue</div>
          <div class="stat-value text-error">{stats.cnf_overdue}</div>
        </div>
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Due Soon</div>
          <div class="stat-value text-warning">{stats.cnf_due_soon}</div>
        </div>
      </div>
    </div>
    
    <!-- R&D Claims Content -->
    <div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
      {#if filteredClaims.length > 0}
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Project</th>
                <th>Company</th>
                <th>CNF Status</th>
                <th>CNF Deadline</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {#each filteredClaims as claim}
                <tr>
                  <td>
                    <div class="font-bold">{claim.title}</div>
                  </td>
                  <td>
                    {#if claim.company}
                      <div class="font-medium">
                        <a 
                          href={`/companies/${claim.company.id}`} 
                          class="link link-primary hover:link-primary-focus"
                        >
                          {claim.company.name}
                        </a>
                      </div>
                    {:else}
                      <div class="text-sm opacity-50">—</div>
                    {/if}
                  </td>
                  <td>
                    <div class="badge {claim.cnf_status_badge_class}">
                      {claim.cnf_status_display}
                    </div>
                  </td>
                  <td>
                    {#if claim.cnf_deadline}
                      <div class="text-sm {claim.cnf_deadline_overdue ? 'text-error font-bold' : claim.cnf_deadline_due_soon ? 'text-warning font-bold' : ''}">
                        {claim.cnf_deadline}
                        {#if claim.cnf_deadline_overdue}
                          <div class="text-xs text-error">Overdue</div>
                        {:else if claim.cnf_deadline_due_soon}
                          <div class="text-xs text-warning">Due Soon</div>
                        {/if}
                      </div>
                    {:else}
                      <div class="text-sm opacity-50">—</div>
                    {/if}
                  </td>
                  <td>
                    <div class="flex gap-2">
                      <button 
                        class="btn btn-sm btn-ghost"
                        onclick={() => router.visit(`/rnd_claims/${claim.id}`)}
                        title="View R&D Claim"
                        aria-label="View {claim.title}"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                        </svg>
                      </button>
                      <button 
                        class="btn btn-sm btn-ghost"
                        onclick={() => router.visit(`/rnd_claims/${claim.id}/edit`)}
                        title="Edit R&D Claim"
                        aria-label="Edit {claim.title}"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                        </svg>
                      </button>
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
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>
            </svg>
            <h3 class="text-lg font-medium text-base-content mb-2">
              {search.trim() ? 'No R&D claims found' : 'No R&D claims yet'}
            </h3>
            <p class="text-base-content/70 mb-6">
              {search.trim() 
                ? `No R&D claims match "${search}". Try adjusting your search terms.`
                : 'Get started by creating your first R&D claim'
              }
            </p>
            {#if !search.trim()}
              <Button variant="primary" onclick={() => router.visit('/rnd_claims/new')}>
                Create Your First R&D Claim
              </Button>
            {/if}
          </div>
        </div>
      {/if}
    </div>
    
    <!-- Pagination Controls -->
    {#if pagination && pagination.total_pages > 1}
      <div class="flex flex-col sm:flex-row justify-between items-center gap-4 mt-6 p-4 bg-base-100 rounded-lg border border-base-300">
        <!-- Pagination Info -->
        <div class="text-sm text-base-content/70">
          Showing {((pagination.current_page - 1) * pagination.per_page) + 1} to {Math.min(pagination.current_page * pagination.per_page, pagination.total_count)} of {pagination.total_count} R&D claims
        </div>
        
        <!-- Pagination Navigation -->
        <div class="flex items-center space-x-2">
          <!-- Previous Button -->
          <button 
            class="btn btn-sm btn-outline"
            disabled={!pagination.has_prev_page}
            onclick={() => goToPage(pagination.current_page - 1)}
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
            </svg>
            Previous
          </button>
          
          <!-- Page Numbers -->
          <div class="flex items-center space-x-1">
            {#each Array.from({length: Math.min(5, pagination.total_pages)}, (_, i) => {
              const startPage = Math.max(1, pagination.current_page - 2);
              const endPage = Math.min(pagination.total_pages, startPage + 4);
              const adjustedStartPage = Math.max(1, endPage - 4);
              return adjustedStartPage + i;
            }).filter(page => page <= pagination.total_pages) as page}
              <button 
                class="btn btn-sm {page === pagination.current_page ? 'btn-primary' : 'btn-outline'}"
                onclick={() => goToPage(page)}
              >
                {page}
              </button>
            {/each}
          </div>
          
          <!-- Next Button -->
          <button 
            class="btn btn-sm btn-outline"
            disabled={!pagination.has_next_page}
            onclick={() => goToPage(pagination.current_page + 1)}
          >
            Next
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
            </svg>
          </button>
        </div>
      </div>
    {/if}
  </div>
</Layout>
