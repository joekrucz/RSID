<script>
  import { onMount } from 'svelte';
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import RndClaimsPipelineView from '../../components/RndClaimsPipelineView.svelte';
  
  let { user, rnd_claims, pipeline_data, filters, stats, pagination, view_mode = 'list' } = $props();
  
  let search = $state(filters.search || '');
  let currentView = $state(view_mode);
  let currentPage = $state(pagination?.current_page || 1);
  let perPage = $state(filters.per_page || 25);
  
  // Use server-side pagination and search
  let filteredClaims = $state(rnd_claims);
  let filteredPipelineData = $state(pipeline_data);
  
  // Update data when props change
  $effect(() => {
    filteredClaims = rnd_claims;
    filteredPipelineData = pipeline_data;
  });
  
  // Check localStorage on mount if no explicit view parameter in URL
  onMount(() => {
    if (!window.location.search.includes('view=')) {
      const savedView = localStorage.getItem('rnd_claims_view');
      if (savedView && savedView !== view_mode) {
        currentView = savedView;
        // Update the URL to reflect the saved preference
        router.get('/rnd_claims', { 
          search: search || undefined,
          view: currentView
        }, {
          preserveState: true,
          preserveScroll: true,
          replace: true // Replace current history entry instead of adding new one
        });
      }
    }
  });
  
  function switchView(view) {
    currentView = view;
    
    // Save view preference to localStorage
    if (typeof window !== 'undefined') {
      localStorage.setItem('rnd_claims_view', view);
    }
    
    // Reload with new view
    loadPage(1);
  }
  
  function loadPage(page) {
    const params = new URLSearchParams();
    if (search.trim()) params.set('search', search);
    if (perPage !== 25) params.set('per_page', perPage);
    if (currentView !== 'list') params.set('view', currentView);
    if (page > 1) params.set('page', page);
    
    const queryString = params.toString();
    const url = queryString ? `/rnd_claims?${queryString}` : '/rnd_claims';
    
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
  
  function handleDelete(claimId) {
    if (confirm('Are you sure you want to delete this R&D claim? This action cannot be undone.')) {
      router.delete(`/rnd_claims/${claimId}`, {
        onSuccess: () => {
          toast.success('R&D claim deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete R&D claim.');
        }
      });
    }
  }
  
  function getStageDisplayName(stage) {
    return stage.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
  }
  
  function getStageBadgeClass(stage) {
    switch(stage) {
      case 'upcoming': return 'badge-secondary';
      case 'readying_for_delivery': return 'badge-warning';
      case 'in_progress': return 'badge-info';
      case 'finalised': return 'badge-primary';
      case 'filed_awaiting_hmrc': return 'badge-accent';
      case 'claim_processed': return 'badge-neutral';
      case 'client_invoiced': return 'badge-base-content';
      case 'paid': return 'badge-success';
      default: return 'badge-neutral';
    }
  }
</script>

<svelte:head>
  <title>R&D Claims - RSID App</title>
</svelte:head>

<Layout {user}>
  <div class="max-w-7xl mx-auto">
    <!-- Header -->
    <div class="mb-6">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold text-base-content">R&D Claims</h1>
          <p class="text-base-content/70 mt-1">Manage your research and development claims</p>
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
                placeholder="Search claims..."
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
          
          <!-- View Toggle -->
          <div class="flex items-center space-x-2">
            <span class="text-sm font-medium text-base-content">View:</span>
            <div class="btn-group">
              <button 
                class="btn btn-sm {currentView === 'list' ? 'btn-primary' : 'btn-outline'}"
                onclick={() => switchView('list')}
              >
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16"></path>
                </svg>
                List
              </button>
              <button 
                class="btn btn-sm {currentView === 'pipeline' ? 'btn-primary' : 'btn-outline'}"
                onclick={() => switchView('pipeline')}
              >
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2"></path>
                </svg>
                Pipeline
              </button>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Stats Cards -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Total Claims</div>
          <div class="stat-value text-primary">{stats.total}</div>
        </div>
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Total Expenditure</div>
          <div class="stat-value text-accent">{stats.total_expenditure ? new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP' }).format(stats.total_expenditure) : '£0'}</div>
        </div>
      </div>
    </div>
    
    <!-- Claims Content -->
    {#if currentView === 'list'}
      <!-- List View -->
      <div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
        {#if filteredClaims.length > 0}
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Project</th>
                <th>Company</th>
                <th>Stage</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {#each filteredClaims as claim}
                <tr>
                  <td>
                    <div class="flex items-center space-x-3">
                      <div class="avatar placeholder">
                        <div class="bg-primary text-primary-content rounded-full w-8">
                          <span class="text-xs">R&D</span>
                        </div>
                      </div>
                      <div>
                        <div class="font-bold">
                          <a 
                            href="/rnd_claims/{claim.id}" 
                            class="link link-primary hover:link-primary-focus"
                          >
                            {claim.title}
                          </a>
                        </div>
                        <div class="text-sm opacity-50 line-clamp-1">{claim.description}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    {#if claim.company}
                      <div class="font-medium">{claim.company.name}</div>
                    {:else}
                      <div class="text-sm opacity-50">—</div>
                    {/if}
                  </td>
                  <td>
                    <div class="badge {getStageBadgeClass(claim.stage)}">
                      {getStageDisplayName(claim.stage)}
                    </div>
                  </td>
                  <td>
                    <div class="flex gap-2">
                      <button 
                        class="btn btn-sm btn-ghost"
                        onclick={() => router.visit(`/rnd_claims/${claim.id}`)}
                        title="View Claim"
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
                        title="Edit Claim"
                        aria-label="Edit {claim.title}"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                        </svg>
                      </button>
                      <button 
                        class="btn btn-sm btn-ghost text-error"
                        onclick={() => handleDelete(claim.id)}
                        title="Delete Claim"
                        aria-label="Delete {claim.title}"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
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
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            <h3 class="text-lg font-medium text-base-content mb-2">
              {search.trim() ? 'No claims found' : 'No R&D claims yet'}
            </h3>
            <p class="text-base-content/70 mb-6">
              {search.trim() 
                ? `No claims match "${search}". Try adjusting your search terms.`
                : 'Get started by creating your first R&D claim'
              }
            </p>
            {#if !search.trim()}
              <Button variant="primary" onclick={() => router.visit('/rnd_claims/new')}>
                Create Your First Claim
              </Button>
            {/if}
          </div>
        </div>
        {/if}
      </div>
      
      <!-- Pagination Controls (only for list view) -->
      {#if currentView === 'list' && pagination && pagination.total_pages > 1}
        <div class="flex flex-col sm:flex-row justify-between items-center gap-4 mt-6 p-4 bg-base-100 rounded-lg border border-base-300">
          <!-- Pagination Info -->
          <div class="text-sm text-base-content/70">
            Showing {((pagination.current_page - 1) * pagination.per_page) + 1} to {Math.min(pagination.current_page * pagination.per_page, pagination.total_count)} of {pagination.total_count} claims
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
    {:else}
      <!-- Pipeline View -->
      <RndClaimsPipelineView pipeline_data={filteredPipelineData} />
    {/if}
  </div>
</Layout>