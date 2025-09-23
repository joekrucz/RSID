<script>
  import { onMount } from 'svelte';
  import { router } from '@inertiajs/svelte';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  
  let { user, rnd_claims, filters, pagination } = $props();
  
  let search = $state(filters.search || '');
  let currentPage = $state(pagination?.current_page || 1);
  let perPage = $state(filters.per_page || 25);
  
  // Use server-side pagination and search
  let filteredClaims = $state(rnd_claims);
  let selectedClaimId = $state(null);
  let selectedClaim = $derived(filteredClaims.find(c => c.id === selectedClaimId));

  function handleRowKeydown(event, claimId) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      selectedClaimId = claimId;
    }
  }
  
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

  function computeSixMonthsAfter(dateStr) {
    if (!dateStr) return null;
    const [y, m, d] = dateStr.split('-').map(Number);
    if (!y || !m || !d) return null;
    const dt = new Date(y, m - 1, d);
    dt.setMonth(dt.getMonth() + 6);
    const yy = dt.getFullYear();
    const mm = String(dt.getMonth() + 1).padStart(2, '0');
    const dd = String(dt.getDate()).padStart(2, '0');
    return `${yy}-${mm}-${dd}`;
  }

  function isOverdue(dateStr) {
    if (!dateStr) return false;
    const today = new Date();
    today.setHours(0,0,0,0);
    const [y, m, d] = dateStr.split('-').map(Number);
    const dt = new Date(y, m - 1, d);
    return dt < today;
  }

  function isDueSoon(dateStr) {
    if (!dateStr) return false;
    const today = new Date();
    today.setHours(0,0,0,0);
    const soon = new Date(today);
    soon.setDate(soon.getDate() + 7);
    const [y, m, d] = dateStr.split('-').map(Number);
    const dt = new Date(y, m - 1, d);
    return dt >= today && dt <= soon;
  }

  function formatDateSixDigits(dateStr) {
    if (!dateStr) return '';
    const [y, m, d] = dateStr.split('-').map(Number);
    if (!y || !m || !d) return '';
    const dd = String(d).padStart(2, '0');
    const mm = String(m).padStart(2, '0');
    const yy = String(y).slice(-2);
    return `${dd}/${mm}/${yy}`; // DD/MM/YY
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
        </div>
        <div class="flex-1 sm:max-w-md">
          <div class="join w-full">
            <input
              type="text"
              bind:value={search}
              oninput={handleSearch}
              placeholder="Search R&D claims..."
              class="input input-bordered join-item w-full"
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
      </div>
      
      
      
    </div>
    
    <!-- R&D Claims Content -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-4">
      <!-- Master: Claims List -->
      <div class="lg:col-span-7 bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
        {#if filteredClaims.length > 0}
          <div class="overflow-x-auto">
            <table class="table table-zebra w-full">
              <thead>
                <tr>
                  <th rowspan="2">CNF Status</th>
                  <th rowspan="2">Name</th>
                  <th rowspan="2">Deadline</th>
                  <th colspan="7" class="text-center">CNF email</th>
                </tr>
                <tr>
                  <th class="w-8 text-center">1</th>
                  <th class="w-8 text-center">2</th>
                  <th class="w-8 text-center">3</th>
                  <th class="w-8 text-center">4</th>
                  <th class="w-8 text-center">5</th>
                  <th class="w-8 text-center">6</th>
                  <th class="w-8 text-center">FS</th>
                </tr>
              </thead>
              <tbody>
                {#each filteredClaims as claim}
                  <tr class="cursor-pointer {selectedClaimId === claim.id ? 'active' : ''}"
                      onclick={() => { selectedClaimId = claim.id; }}
                      onkeydown={(e) => handleRowKeydown(e, claim.id)}
                      tabindex="0"
                      aria-selected={selectedClaimId === claim.id}>
                    <td>
                      <div class="badge {claim.cnf_status_badge_class}">
                        {claim.cnf_status_display}
                      </div>
                    </td>
                    <td>
                      <div class="font-bold">
                        {claim.title}
                        {#if claim.company}
                          <span class="text-base-content/60 font-normal"> — </span>
                          <a 
                            href={`/companies/${claim.company.id}`}
                            class="link link-primary hover:link-primary-focus"
                            onclick={(e) => e.stopPropagation()}
                          >{claim.company.name}</a>
                        {/if}
                      </div>
                    </td>
                    <td>
                      {#if claim.end_date}
                        {#key claim.end_date}
                          {#await Promise.resolve(computeSixMonthsAfter(claim.end_date)) then calcDeadline}
                            {#if calcDeadline}
                              <div class="text-sm {isOverdue(calcDeadline) ? 'text-error font-bold' : isDueSoon(calcDeadline) ? 'text-warning font-bold' : ''}">{formatDateSixDigits(calcDeadline)}</div>
                            {:else}
                              <div class="text-sm opacity-50">—</div>
                            {/if}
                          {/await}
                        {/key}
                      {:else}
                        <div class="text-sm opacity-50">—</div>
                      {/if}
                    </td>
                    <td class="text-center w-8"></td>
                    <td class="text-center w-8"></td>
                    <td class="text-center w-8"></td>
                    <td class="text-center w-8"></td>
                    <td class="text-center w-8"></td>
                    <td class="text-center w-8"></td>
                    <td class="text-center w-8"></td>
                    
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
            </div>
          </div>
        {/if}
      </div>

      <!-- Detail: Selected Claim -->
      <div class="lg:col-span-5">
        <div class="bg-base-100 rounded-lg shadow border border-base-300 p-4 h-full">
          {#if selectedClaim}
            <div class="flex items-start justify-between">
              <div>
                <h2 class="text-xl font-semibold text-base-content">{selectedClaim.title}</h2>
                {#if selectedClaim.company}
                  <div class="text-base-content/70 mt-1">
                    Company: 
                    <a 
                      href={`/companies/${selectedClaim.company.id}`} 
                      class="link link-primary hover:link-primary-focus"
                    >
                      {selectedClaim.company.name}
                    </a>
                  </div>
                {/if}
              </div>
              <div class="badge {selectedClaim.cnf_status_badge_class}">{selectedClaim.cnf_status_display}</div>
            </div>

            <div class="divider"></div>

            <div class="space-y-3">
              <div>
                <span class="text-sm text-base-content/70">CNF Deadline</span>
                {#if selectedClaim.end_date}
                  {#key selectedClaim.end_date}
                    {#await Promise.resolve(computeSixMonthsAfter(selectedClaim.end_date)) then calcDeadline}
                      <div class="text-sm {isOverdue(calcDeadline) ? 'text-error font-bold' : isDueSoon(calcDeadline) ? 'text-warning font-bold' : ''}">
                        {calcDeadline ? formatDateSixDigits(calcDeadline) : '—'}
                      </div>
                    {/await}
                  {/key}
                {:else}
                  <div class="text-sm opacity-50">—</div>
                {/if}
              </div>
            </div>

            <div class="mt-6 flex gap-2">
              <button 
                class="btn btn-sm btn-outline"
                onclick={() => router.visit(`/rnd_claims/${selectedClaim.id}`)}
              >
                View
              </button>
              <button 
                class="btn btn-sm btn-primary"
                onclick={() => router.visit(`/rnd_claims/${selectedClaim.id}/edit`)}
              >
                Edit
              </button>
            </div>
          {:else}
            <div class="h-full flex items-center justify-center text-base-content/60 py-12">
              <div class="text-center">
                <div class="mb-2 font-medium">Select a claim to view details</div>
                <div class="text-sm">Choose a row from the list on the left.</div>
              </div>
            </div>
          {/if}
        </div>
      </div>
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


