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
  let emailTemplate = $state('urgent'); // 'initial' | 'monthly' | 'urgent'
  let selectedCnfEmail = $state(null); // The actual CnfEmail record

  // Choose a default template based on the clicked slot and find the CNF email
  $effect(() => {
    if (!selectedEmailSlot) {
      selectedCnfEmail = null;
      return;
    }
    
    const claim = filteredClaims.find(c => c.id === selectedEmailSlot.claimId);
    if (!claim) return;
    
    const slot = String(selectedEmailSlot.slot);
    selectedCnfEmail = claim.cnf_emails?.find(email => email.email_slot === slot) || null;
    
    if (slot === '1') {
      emailTemplate = 'initial';
    } else if (['2','3','4','5'].includes(slot)) {
      emailTemplate = 'monthly';
    } else if (['6','FS'].includes(slot)) {
      emailTemplate = 'urgent';
    } else {
      emailTemplate = 'urgent';
    }
  });

  function getFyFromEndDate(endDateStr) {
    if (!endDateStr) return '';
    const [y] = endDateStr.split('-').map(Number);
    const yy = String(y).slice(-2);
    return `FY${yy}`;
  }

  function getDeadlineFromEndDate(endDateStr) {
    const sixMonths = computeSixMonthsAfter(endDateStr);
    return sixMonths ? formatDateSixDigits(sixMonths) : '';
  }

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

  async function updateCnfStatus(claimId, newStatus) {
    // Optimistically update the UI immediately
    const claim = filteredClaims.find(c => c.id === claimId);
    if (claim) {
      const oldStatus = claim.cnf_status;
      const oldStatusDisplay = claim.cnf_status_display;
      const oldStatusBadgeClass = claim.cnf_status_badge_class;
      
      // Update immediately
      claim.cnf_status = newStatus;
      claim.cnf_status_display = getStatusDisplay(newStatus);
      claim.cnf_status_badge_class = getStatusBadgeClass(newStatus);
    }
    
    try {
      const response = await fetch(`/rnd_claims/${claimId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          rnd_claim: {
            cnf_status: newStatus
          }
        })
      });
      
      if (!response.ok) {
        // Revert on error
        if (claim) {
          claim.cnf_status = oldStatus;
          claim.cnf_status_display = oldStatusDisplay;
          claim.cnf_status_badge_class = oldStatusBadgeClass;
        }
        console.error('Failed to update CNF status');
      }
    } catch (error) {
      // Revert on error
      if (claim) {
        claim.cnf_status = oldStatus;
        claim.cnf_status_display = oldStatusDisplay;
        claim.cnf_status_badge_class = oldStatusBadgeClass;
      }
      console.error('Error updating CNF status:', error);
    }
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
      case 'sent': return 'SENT';
      case 'to_be_sent': return 'TO BE SENT';
      case 'skipped': return 'SKIPPED';
      case 'to_be_skipped': return 'TO BE SKIPPED';
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

  function getCnfEmailForSlot(claim, slot) {
    return claim.cnf_emails?.find(email => email.email_slot === slot) || null;
  }

  function markEmailAsSent() {
    if (!selectedCnfEmail) return;
    
    let newStatus;
    if (selectedCnfEmail.status === 'sent') {
      newStatus = 'to_be_sent';
    } else if (selectedCnfEmail.status === 'to_be_sent') {
      newStatus = 'sent';
    } else if (selectedCnfEmail.status === 'skipped') {
      newStatus = 'to_be_skipped';
    } else if (selectedCnfEmail.status === 'to_be_skipped') {
      newStatus = 'skipped';
    } else {
      newStatus = 'sent';
    }
    
    router.patch(`/cnf_emails/${selectedCnfEmail.id}`, {
      cnf_email: {
        status: newStatus,
        sent_at: newStatus === 'sent' ? new Date().toISOString() : null
      }
    }, {
      preserveState: true,
      preserveScroll: true,
      onSuccess: () => {
        // Update the local state
        selectedCnfEmail.status = newStatus;
        selectedCnfEmail.status_display = getStatusDisplay(newStatus);
        selectedCnfEmail.icon_display = getIconDisplay(newStatus);
        selectedCnfEmail.sent_at = newStatus === 'sent' ? new Date().toISOString() : null;
        
        // Update the claim's email list
        const claim = filteredClaims.find(c => c.id === selectedEmailSlot.claimId);
        if (claim && claim.cnf_emails) {
          const emailIndex = claim.cnf_emails.findIndex(email => email.id === selectedCnfEmail.id);
          if (emailIndex !== -1) {
            claim.cnf_emails[emailIndex] = { ...selectedCnfEmail };
          }
        }
      }
    });
  }

  async function toggleEmailSkipStatus(emailId) {
    if (!selectedCnfEmail || selectedCnfEmail.id !== emailId) return;
    
    let newStatus;
    if (selectedCnfEmail.status === 'to_be_sent') {
      newStatus = 'to_be_skipped';
    } else if (selectedCnfEmail.status === 'to_be_skipped') {
      newStatus = 'to_be_sent';
    } else {
      return; // Only toggle between to_be_sent and to_be_skipped
    }
    
    try {
      const response = await fetch(`/cnf_emails/${selectedCnfEmail.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          cnf_email: {
            status: newStatus
          }
        })
      });
      
      if (response.ok) {
        const data = await response.json();
        if (data.success) {
          // Update the local state
          selectedCnfEmail.status = newStatus;
          selectedCnfEmail.status_display = getStatusDisplay(newStatus);
          selectedCnfEmail.icon_display = getIconDisplay(newStatus);
          
          // Update the claim's email list
          const claim = filteredClaims.find(c => c.id === selectedEmailSlot.claimId);
          if (claim && claim.cnf_emails) {
            const emailIndex = claim.cnf_emails.findIndex(email => email.id === selectedCnfEmail.id);
            if (emailIndex !== -1) {
              claim.cnf_emails[emailIndex] = { ...selectedCnfEmail };
            }
          }
        }
      }
    } catch (error) {
      console.error('Error toggling email skip status:', error);
    }
  }

  function getIconDisplay(status) {
    switch(status) {
      case 'sent': return '📂';
      case 'to_be_sent': return '✉️';
      case 'skipped': return '~';
      case 'to_be_skipped': return '[~]';
      default: return '✉️';
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
            <table class="table w-full table-compact table-fixed">
              <thead class="sticky top-0 z-10 bg-gray-700 text-white">
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
                  {@const email1 = getCnfEmailForSlot(claim, '1')}
                  {@const email2 = getCnfEmailForSlot(claim, '2')}
                  {@const email3 = getCnfEmailForSlot(claim, '3')}
                  {@const email4 = getCnfEmailForSlot(claim, '4')}
                  {@const email5 = getCnfEmailForSlot(claim, '5')}
                  {@const email6 = getCnfEmailForSlot(claim, '6')}
                  {@const emailFS = getCnfEmailForSlot(claim, 'FS')}
                  <tr class="{(claim.cnf_status === 'cnf_exempt' || claim.cnf_status === 'cnf_submitted' || claim.cnf_status === 'not_claiming') ? 'bg-green-50' : ''} {(claim.cnf_deadline && new Date(claim.cnf_deadline) <= new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) && claim.cnf_status !== 'cnf_exempt' && claim.cnf_status !== 'cnf_submitted' && claim.cnf_status !== 'not_claiming') ? 'bg-orange-50' : ''}"
                      aria-selected={selectedClaimId === claim.id}>
                    <td
                      class="cursor-pointer px-1 w-[5.5rem]"
                      onclick={() => { selectedEmailSlot = null; selectedClaimId = claim.id; }}
                      onkeydown={(e) => handleRowKeydown(e, claim.id)}
                      role="button"
                      tabindex="0"
                    >
                      <div class="text-sm truncate max-w-full overflow-hidden {(claim.cnf_status === 'cnf_submitted' || claim.cnf_status === 'cnf_exempt' || claim.cnf_status === 'not_claiming') ? 'text-green-600 font-bold' : ''}" title={claim.cnf_status_display}>
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
                              <div class="text-sm">{formatDateSixDigits(calcDeadline)}</div>
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
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg {selectedEmailSlot?.claimId === claim.id && selectedEmailSlot?.slot === '1' ? 'bg-gray-300' : ''}" aria-label="Open CNF email 1"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '1' }; }}
                        title={email1 ? `${email1.status_display} - ${email1.template_type}` : 'TO BE SENT - Initial'}>
                        {email1?.icon_display || '✉️'}
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg {selectedEmailSlot?.claimId === claim.id && selectedEmailSlot?.slot === '2' ? 'bg-gray-300' : ''}" aria-label="Open CNF email 2"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '2' }; }}
                        title={email2 ? `${email2.status_display} - ${email2.template_type}` : 'TO BE SENT - Monthly'}>
                        {email2?.icon_display || '✉️'}
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg {selectedEmailSlot?.claimId === claim.id && selectedEmailSlot?.slot === '3' ? 'bg-gray-300' : ''}" aria-label="Open CNF email 3"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '3' }; }}
                        title={email3 ? `${email3.status_display} - ${email3.template_type}` : 'TO BE SENT - Monthly'}>
                        {email3?.icon_display || '✉️'}
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg {selectedEmailSlot?.claimId === claim.id && selectedEmailSlot?.slot === '4' ? 'bg-gray-300' : ''}" aria-label="Open CNF email 4"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '4' }; }}
                        title={email4 ? `${email4.status_display} - ${email4.template_type}` : 'TO BE SENT - Monthly'}>
                        {email4?.icon_display || '✉️'}
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg {selectedEmailSlot?.claimId === claim.id && selectedEmailSlot?.slot === '5' ? 'bg-gray-300' : ''}" aria-label="Open CNF email 5"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '5' }; }}
                        title={email5 ? `${email5.status_display} - ${email5.template_type}` : 'TO BE SENT - Monthly'}>
                        {email5?.icon_display || '✉️'}
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg {selectedEmailSlot?.claimId === claim.id && selectedEmailSlot?.slot === '6' ? 'bg-gray-300' : ''}" aria-label="Open CNF email 6"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: '6' }; }}
                        title={email6 ? `${email6.status_display} - ${email6.template_type}` : 'TO BE SENT - Urgent'}>
                        {email6?.icon_display || '✉️'}
                      </button>
                    </td>
                    <td class="text-center w-7 px-1">
                      <button class="btn btn-ghost btn-xs p-0 min-h-0 h-6 w-6 leading-none text-lg {selectedEmailSlot?.claimId === claim.id && selectedEmailSlot?.slot === 'FS' ? 'bg-gray-300' : ''}" aria-label="Open CNF email FS"
                        onclick={(e) => { e.stopPropagation?.(); selectedClaimId = null; selectedEmailSlot = { claimId: claim.id, slot: 'FS' }; }}
                        title={emailFS ? `${emailFS.status_display} - ${emailFS.template_type}` : 'TO BE SENT - Urgent'}>
                        {emailFS?.icon_display || '✉️'}
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
        <div class="bg-base-100 rounded-lg shadow border border-base-300 h-full overflow-hidden {selectedClaimId && !selectedEmailSlot ? 'bg-gray-100' : ''}">
          {#if selectedEmailSlot}
            {#key `${selectedEmailSlot.claimId}-${selectedEmailSlot.slot}`}
              {@const selectedClaimForEmail = filteredClaims.find(c => c.id === selectedEmailSlot.claimId)}
              <div class="h-full flex flex-col">
                <!-- Email Header -->
                <div class="p-3 rounded-t-lg {selectedCnfEmail?.status === 'sent' ? 'bg-success text-success-content' : 
                                               selectedCnfEmail?.status === 'to_be_sent' ? 'bg-warning text-warning-content' :
                                               selectedCnfEmail?.status === 'skipped' ? 'bg-success text-success-content' :
                                               selectedCnfEmail?.status === 'to_be_skipped' ? 'bg-warning text-warning-content' :
                                               'bg-warning text-warning-content'}">
                  <div class="flex items-center justify-between">
                    <div>
                      <h2 class="text-lg font-semibold">
                        {selectedClaimForEmail?.company?.name || 'Company'} - {selectedClaimForEmail?.title || 'Claim'} - {selectedCnfEmail?.email_slot === 'FS' ? 'Failsafe' : selectedCnfEmail?.email_slot ? `${selectedCnfEmail.email_slot}${selectedCnfEmail.email_slot === '1' ? 'st' : selectedCnfEmail.email_slot === '2' ? 'nd' : selectedCnfEmail.email_slot === '3' ? 'rd' : 'th'} Email` : 'Email'}
                      </h2>
                      <div class="flex items-center space-x-4 text-sm opacity-90">
                        <span>{selectedCnfEmail?.status_display || 'TO BE SENT'}</span>
                        <span>•</span>
                        <div class="flex items-center space-x-2">
                          <span>
                            {#if selectedCnfEmail?.sent_at}
                              {new Date(selectedCnfEmail.sent_at).toLocaleDateString()}
                            {:else if selectedCnfEmail?.status === 'to_be_sent' || selectedCnfEmail?.status === 'to_be_skipped'}
                              {new Date(selectedCnfEmail.expected_send_date || selectedCnfEmail.sent_at).toLocaleDateString()}
                            {:else}
                              Not sent
                            {/if}
                          </span>
                          {#if selectedCnfEmail && !selectedCnfEmail.sent_at}
                            <label class="flex items-center space-x-1 cursor-pointer">
                              <input 
                                type="checkbox" 
                                class="checkbox checkbox-xs"
                                checked={selectedCnfEmail?.status === 'to_be_skipped'}
                                onchange={() => toggleEmailSkipStatus(selectedCnfEmail.id)}
                              />
                              <span class="text-xs">Skip</span>
                            </label>
                          {/if}
                        </div>
                      </div>
                    </div>
                    <button class="btn btn-ghost btn-sm {selectedCnfEmail?.status === 'sent' ? 'text-success-content hover:bg-success-content/20' :
                                                       selectedCnfEmail?.status === 'to_be_sent' ? 'text-warning-content hover:bg-warning-content/20' :
                                                       selectedCnfEmail?.status === 'skipped' ? 'text-success-content hover:bg-success-content/20' :
                                                       selectedCnfEmail?.status === 'to_be_skipped' ? 'text-warning-content hover:bg-warning-content/20' :
                                                       'text-warning-content hover:bg-warning-content/20'}" 
                            onclick={() => selectedEmailSlot = null} 
                            aria-label="Close email">
                      ✕
                    </button>
                  </div>
                </div>

                <!-- Email Content -->
                <div class="flex-1 bg-base-100 p-4 space-y-4">
                  <!-- Email Metadata -->
                  <div class="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span class="font-medium text-base-content/70">From:</span>
                      <span class="ml-2">{selectedCnfEmail?.sender_email || 'customersuccess@granttree.co.uk'}</span>
                    </div>
                    <div>
                      <span class="font-medium text-base-content/70">To:</span>
                      <span class="ml-2">{selectedCnfEmail?.recipient_email || (selectedClaimForEmail?.company?.name ? `${selectedClaimForEmail.company.name.toLowerCase().replace(/\s+/g, '')}@company.com` : 'client@company.com')}</span>
                    </div>
                    <div>
                      <span class="font-medium text-base-content/70">CC:</span>
                      <span class="ml-2 text-base-content/50">—</span>
                    </div>
                    <div class="col-span-2">
                      <span class="font-medium text-base-content/70">SUBJECT:</span>
                      <span class="ml-2 font-semibold">
                        {selectedCnfEmail?.subject || 
                         (emailTemplate === 'initial' ? `You are now in your CNF period for ${getFyFromEndDate(selectedClaimForEmail?.end_date)}` :
                          emailTemplate === 'monthly' ? `Reminder: You are in your CNF period for ${getFyFromEndDate(selectedClaimForEmail?.end_date)}` :
                          `CNF DEADLINE REMINDER - due ${getDeadlineFromEndDate(selectedClaimForEmail?.end_date)}`)}
                      </span>
                    </div>
                  </div>


                  <!-- Email Body -->
                  <div class="bg-base-200 p-4 rounded-lg space-y-3 text-sm">
                    {#if selectedCnfEmail?.body}
                      <div class="whitespace-pre-line">{selectedCnfEmail.body}</div>
                    {:else if emailTemplate === 'initial'}
                      <div>Hi,</div>
                      <div>
                        This is an automated, but important message to let you know that you are now within the six-month window to notify HMRC of your intention to make an R&D Tax Credit claim for {getFyFromEndDate(selectedClaimForEmail?.end_date)}.
                        The deadline to submit your CNF is 6 months after the end of the claim's accounting period - if you have extended or shortened your company's year-end, please be advised that will also impact the deadline for the CNF.
                      </div>
                      <div>
                        As part of recent changes to R&D legislation, HMRC now requires companies to submit a 'Claim Notification' to inform them that they intend to claim. This applies to all accounting periods starting on or after 1 April 2023.
                      </div>
                      <div>
                        <strong>Action required</strong><br>
                        To make this process easy, GrantTree can of course submit the notification on your behalf, but we need a few key details from you first. Please complete the attached form to help us to do so. If the form is not submitted in time, HMRC will reject your claim, even if all other criteria are met.
                      </div>
                      <div>
                        <strong>Ignore if…</strong><br>
                        If you're already in touch with us about this, feel free to ignore this message. Otherwise, if you have any questions or need help completing the form, please get in touch with a member of the GrantTree team and we will be happy to assist.
                      </div>
                      <div class="pt-2">
                        Best regards,<br>
                        <strong>The GrantTree Team</strong>
                      </div>
                    {:else if emailTemplate === 'monthly'}
                      <div>Hi,</div>
                      <div>
                        This is a reminder that you are currently within your Claim Notification Form (CNF) period for your {getFyFromEndDate(selectedClaimForEmail?.end_date)} R&D Tax Credit claim.
                      </div>
                      <div>
                        HMRC requires companies to notify them of their intention to claim R&D Tax Relief no later than 6 months after the end of the claim's accounting period. If your year-end has been extended or shortened, please note this will also affect your CNF deadline.
                      </div>
                      <div>
                        <strong>Action required</strong><br>
                        To make this process simple, GrantTree can submit the CNF on your behalf. However, we first need a few key details from you. Please complete the attached form as soon as possible so we can take care of the submission for you. If the CNF is not filed in time, HMRC will reject your claim—even if all other criteria are met.
                      </div>
                      <div>
                        <strong>Ignore if…</strong> If you're already in touch with us about this, feel free to disregard this message. Otherwise, please get in touch with a member of the GrantTree team if you have any questions or need support completing the form.
                      </div>
                      <div class="pt-2">
                        Best regards,<br>
                        <strong>The GrantTree Team</strong>
                      </div>
                    {:else}
                      <div>Hi,</div>
                      <div>
                        This is an <strong>urgent reminder</strong> that the deadline for submitting your R&D Claim Notification Form is <strong>{getDeadlineFromEndDate(selectedClaimForEmail?.end_date)}</strong>.
                      </div>
                      <div>
                        Failure to submit this form by the deadline will prevent you from claiming R&D Tax Relief for your previous accounting period.
                      </div>
                      <div>
                        <strong>Next Steps:</strong>
                        <ul class="list-disc list-inside mt-2 space-y-1 ml-4">
                          <li>If you intend to claim R&D tax relief, please submit the Claim Notification Form immediately.</li>
                          <li>If you believe you do not need to submit this form, please contact us immediately to confirm.</li>
                          <li>If you think another party, including GrantTree, has already handled this for you, or if you have any questions, please contact us immediately.</li>
                          <li>Currently, based on the information we hold, we cannot submit this form on your behalf; you will need to complete this action yourself.</li>
                        </ul>
                      </div>
                      <div>
                        If you have already submitted the notification form or instructed us to do so, thank you - no further action is needed.
                      </div>
                      <div>
                        Please reach out if you need any assistance.
                      </div>
                      <div class="pt-2">
                        Best regards,<br>
                        <strong>The GrantTree Team</strong>
        </div>
      {/if}
    </div>
    
                  <!-- Action Button -->
                  <div class="flex justify-end pt-4">
                    <button class="btn btn-neutral" onclick={markEmailAsSent}>
                      {selectedCnfEmail?.status === 'sent' ? 'Mark as TO BE SENT' : 
                       selectedCnfEmail?.status === 'to_be_sent' ? 'Mark as SENT' :
                       selectedCnfEmail?.status === 'skipped' ? 'Mark as TO BE SKIPPED' :
                       selectedCnfEmail?.status === 'to_be_skipped' ? 'Mark as SKIPPED' : 'Override: Send Now'}
                    </button>
                  </div>
                </div>
              </div>
            {/key}
          {:else if selectedClaim}
            <div class="p-4">
              <div>
                <h2 class="text-xl font-semibold text-base-content">
                  <a 
                    href={`/rnd_claims/${selectedClaim.id}`}
                    class="hover:underline cursor-pointer"
                  >
                    {#if selectedClaim.company}
                      {selectedClaim.company.name} {selectedClaim.title}
                    {:else}
                      {selectedClaim.title}
                    {/if}
                  </a>
                </h2>
              </div>

            <div class="divider"></div>

            <div class="space-y-3">
              <h3 class="text-lg font-semibold text-base-content">CNF Status</h3>
              
              <div>
                <select 
                  class="select select-bordered select-sm w-full"
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
            </div>

            <div class="divider"></div>

            <div class="space-y-3">
              <h3 class="text-lg font-semibold text-base-content">CNF Check</h3>
              
              <!-- CNF Check Table -->
              <div class="overflow-x-auto">
                <table class="table table-zebra w-full table-compact">
                  <thead>
                    <tr>
                      <th class="w-1/6">Previous claim</th>
                      <th class="w-1/6">Filed on</th>
                      <th class="w-1/6">Accepted?</th>
                      <th class="w-1/6">Type</th>
                      <th class="w-1/6">Period start</th>
                      <th class="w-1/6">Result</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td class="text-sm">Claim 1</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                    </tr>
                    <tr>
                      <td class="text-sm">Claim 2</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                    </tr>
                    <tr>
                      <td class="text-sm">Claim 3</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                      <td class="text-sm">—</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div>
                <span class="text-sm text-base-content/70">CNF Deadline</span>
                {#if selectedClaim.end_date}
                  {#key selectedClaim.end_date}
                    {#await Promise.resolve(computeSixMonthsAfter(selectedClaim.end_date)) then calcDeadline}
                      <div class="text-sm">
                        {calcDeadline ? formatDateSixDigits(calcDeadline) : '—'}
                      </div>
                    {/await}
                  {/key}
                {:else}
                  <div class="text-sm opacity-50">—</div>
                {/if}
              </div>
              <div>
                <span class="text-sm text-base-content/70">CNF Submission Date</span>
                {#if selectedClaim.cnf_submission_date}
                  <div class="text-sm">{formatDateSixDigits(selectedClaim.cnf_submission_date)}</div>
                {:else}
                  <div class="text-sm opacity-50">—</div>
                {/if}
              </div>
        </div>
        
            </div>
          {:else}
            <div class="h-full flex items-center justify-center text-base-content/60 py-12 p-4">
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


