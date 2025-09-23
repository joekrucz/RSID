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
  let selectedEmailSlot = $state(null); // { claimId, slot: '1'|'2'|'3'|'4'|'5'|'6'|'FS' }

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

  function updateCnfStatus(claimId, newStatus) {
    router.patch(`/rnd_claims/${claimId}`, {
      rnd_claim: {
        cnf_status: newStatus
      }
    }, {
      preserveState: true,
      preserveScroll: true,
      onSuccess: () => {
        // Update the local state to reflect the change
        const claim = filteredClaims.find(c => c.id === claimId);
        if (claim) {
          claim.cnf_status = newStatus;
          // Update display values
          claim.cnf_status_display = getStatusDisplay(newStatus);
          claim.cnf_status_badge_class = getStatusBadgeClass(newStatus);
        }
      }
    });
  }

  function getStatusDisplay(status) {
    switch(status) {
      case 'not_claiming': return 'Not claiming';
      case 'cnf_needed': return 'Needed';
      case 'cnf_exemption_possible': return 'Exemption Possible';
      case 'in_progress': return 'In Progress';
      case 'cnf_submitted': return 'Submitted';
      case 'cnf_exempt': return 'Exempt';
      case 'cnf_missed': return 'Missed';
      default: return status;
    }
  }

  function getStatusBadgeClass(status) {
    switch(status) {
      case 'not_claiming': return 'badge-neutral';
      case 'cnf_needed': return 'badge-error';
      case 'cnf_exemption_possible': return 'badge-warning';
      case 'in_progress': return 'badge-info';
      case 'cnf_submitted': return 'badge-success';
      case 'cnf_exempt': return 'badge-success';
      case 'cnf_missed': return 'badge-error';
      default: return 'badge-neutral';
    }
  }
</script>

<svelte:head>
  <title>CNF Comms - RSID App</title>
</svelte:head>

<Layout {user} currentPage="cnf_comms" fullWidth={true}>
  <div class="w-full px-4">
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
      <div class="lg:col-span-5 bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden flex flex-col">
        {#if filteredClaims.length > 0}
          <div class="overflow-x-auto overflow-y-auto max-h-[70vh] flex-1">
            <table class="table table-zebra w-full table-compact table-fixed">
              <thead>
                <tr>
                  <th rowspan="2" class="px-1 w-[5.5rem]">CNF Status</th>
                  <th rowspan="2" class="px-1 w-[10rem]">Name</th>
                  <th rowspan="2" class="px-1 w-[6rem] text-center">Deadline</th>
                  <th colspan="7" class="text-center">CNF email</th>
                </tr>
                <tr>
                  <th class="w-7 text-center px-1">1</th>
                  <th class="w-7 text-center px-1">2</th>
                  <th class="w-7 text-center px-1">3</th>
                  <th class="w-7 text-center px-1">4</th>
                  <th class="w-7 text-center px-1">5</th>
                  <th class="w-7 text-center px-1">6</th>
                  <th class="w-7 text-center px-1">FS</th>
                </tr>
              </thead>
              <tbody>
                {#each filteredClaims as claim}
                  <tr class="{selectedClaimId === claim.id ? 'active' : ''}"
                      aria-selected={selectedClaimId === claim.id}>
                    <td
                      class="cursor-pointer px-1 w-[5.5rem]"
                      onclick={() => { selectedEmailSlot = null; selectedClaimId = claim.id; }}
                      onkeydown={(e) => handleRowKeydown(e, claim.id)}
                      role="button"
                      tabindex="0"
                    >
                      <div class="badge {claim.cnf_status_badge_class} badge-sm truncate" title={claim.cnf_status_display}>
                        {claim.cnf_status_display}
                      </div>
                    </td>
                    <td class="px-1 whitespace-nowrap w-[10rem]">
                      <div class="font-bold text-sm truncate max-w-[10rem]" title={(claim.company ? `${claim.company.name} ${claim.title}` : claim.title)}>
                        {#if claim.company}
                          {claim.company.name} {claim.title}
                        {:else}
                          {claim.title}
                        {/if}
                      </div>
                    </td>
                    <td class="px-1 whitespace-nowrap text-center w-[6rem]">
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
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg" aria-label="Open CNF email 1"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '1' }; }}>
                        📁
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg" aria-label="Open CNF email 2"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '2' }; }}>
                        📁
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg" aria-label="Open CNF email 3"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '3' }; }}>
                        📁
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg" aria-label="Open CNF email 4"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '4' }; }}>
                        📁
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg" aria-label="Open CNF email 5"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '5' }; }}>
                        📁
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg" aria-label="Open CNF email 6"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '6' }; }}>
                        📁
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg" aria-label="Open CNF email FS"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: 'FS' }; }}>
                        📁
                      </button>
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
            </div>
          </div>
        {/if}
      </div>

      <!-- Detail: Selected Claim -->
      <div class="lg:col-span-7">
        <div class="bg-base-100 rounded-lg shadow border border-base-300 p-4 h-full">
          {#if selectedEmailSlot}
            {#key `${selectedEmailSlot.claimId}-${selectedEmailSlot.slot}`}
              <div class="space-y-3">
                <div class="flex items-start justify-between">
                  <h2 class="text-xl font-semibold text-base-content">CNF Email Placeholder</h2>
                  <button class="btn btn-ghost btn-sm" onclick={() => selectedEmailSlot = null} aria-label="Close placeholder">✕</button>
                </div>
                <div class="text-base-content/70">Claim ID: {selectedEmailSlot.claimId}</div>
                <div class="text-base-content/70">Slot: {selectedEmailSlot.slot}</div>
                <div class="mt-2 text-sm">This is a placeholder for CNF email content. Replace with real view later.</div>
              </div>
            {/key}
          {:else if selectedClaim}
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
                <span class="text-sm text-base-content/70">CNF Status</span>
                <select 
                  class="select select-bordered select-sm w-full mt-1"
                  bind:value={selectedClaim.cnf_status}
                  onchange={() => updateCnfStatus(selectedClaim.id, selectedClaim.cnf_status)}
                >
                  <option value="not_claiming">Not claiming</option>
                  <option value="cnf_needed">Needed</option>
                  <option value="cnf_exemption_possible">Exemption Possible</option>
                  <option value="in_progress">In Progress</option>
                  <option value="cnf_submitted">Submitted</option>
                  <option value="cnf_exempt">Exempt</option>
                  <option value="cnf_missed">Missed</option>
                </select>
              </div>
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
  </div>
</Layout>


