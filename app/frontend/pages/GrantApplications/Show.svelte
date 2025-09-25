<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Checklist from '../../components/Checklist.svelte';
  import ChecklistTaskDetail from '../../components/ChecklistTaskDetail.svelte';
  import GrantChecklistPane from '../../components/GrantChecklistPane.svelte';
  import { onMount } from 'svelte';
  let checklistRef;
  
  let { user, grant_application, checklist_items = [] } = $props();
  
  // Map frontend group labels to backend section names used by checklist_items
  const sectionMapping = {
    'Client Acquisition': 'Client Acquisition/Project Qualification',
    'Client Invoiced': 'Client Invoiced',
    'Invoice Paid': 'Invoice Paid',
    'KO Prep': 'Preparing for Kick Off/AML/Resourcing',
    'Kicked Off': 'Kicked Off/In Progress',
    'Submitted': 'Submitted',
    'Awaiting Funding Decision': 'Awaiting Funding Decision',
    'Funding Decision': 'Application Successful/Not Successful',
    'Resub Due': 'Resub Due',
    'Success Fee Invoiced': 'Success Fee Invoiced',
    'Success Fee Paid': 'Success Fee Paid'
  };
  
  // Stage conflict warning state
  let stageConflictWarning = $state(grant_application.stage_conflict_message || null);
  let stageConflictDetails = $state(grant_application.stage_conflict_details || []);
  const stages = [
    'client_acquisition_project_qualification',
    'client_invoiced',
    'invoice_paid',
    'preparing_for_kick_off_aml_resourcing',
    'kicked_off_in_progress',
    'submitted',
    'awaiting_funding_decision',
    'application_successful_or_not_successful',
    'resub_due',
    'success_fee_invoiced',
    'success_fee_paid'
  ];
  let currentStage = $state(grant_application.stage || 'pre_delivery');
  let loading = $state(false);
  let stageLoading = $state(false);
  let checklistSectionsCollapsed = $state({});
  const idxCurrent = $derived(stages.indexOf(currentStage));
  let sectionComplete = $state([]);
  // Track when each stage was selected (ISO strings)
  let stageSelectedAt = $state({});
  // Eagerly hydrate from localStorage before first render (so prior dates show immediately)
  try {
    const gaId = grant_application?.id;
    if (typeof window !== 'undefined' && gaId) {
      const initialKey = `grant:stageDates:${gaId}`;
      const raw = localStorage.getItem(initialKey);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (parsed && typeof parsed === 'object') {
          stageSelectedAt = { ...parsed };
        }
      }
    }
  } catch (_) {}
  const stageGroups = [
    { label: 'Pre-delivery', keys: ['client_acquisition_project_qualification', 'client_invoiced', 'invoice_paid', 'preparing_for_kick_off_aml_resourcing'] },
    { label: 'In delivery', keys: ['kicked_off_in_progress', 'submitted'] },
    { label: 'Post delivery', keys: ['awaiting_funding_decision', 'application_successful_or_not_successful', 'resub_due', 'success_fee_invoiced', 'success_fee_paid'] }
  ];
  function groupForStage(stage) {
    const found = stageGroups.find(g => g.keys.includes(stage));
    return found?.label || 'Pre-delivery';
  }
  let currentGroup = $state('Pre-delivery');
  let userSetGroup = $state(false);
  $effect(() => { if (!userSetGroup) currentGroup = groupForStage(currentStage); });
  const currentGroupIdx = $derived(stageGroups.findIndex(g => g.keys.includes(currentStage)));
  // Initialize currently active stage selection date if not present
  $effect(() => {
    if (currentStage && !stageSelectedAt[currentStage]) {
      stageSelectedAt[currentStage] = new Date().toISOString();
    }
  });

  // Persist/load selected dates across refreshes
  function storageKeyForDates() {
    try { return grantApplicationId ? `grant:stageDates:${grantApplicationId}` : null; } catch (_) { return null; }
  }
  function loadStageDates() {
    try {
      const key = storageKeyForDates();
      if (!key) return;
      const raw = localStorage.getItem(key);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (parsed && typeof parsed === 'object') {
          stageSelectedAt = { ...stageSelectedAt, ...parsed };
        }
      }
    } catch (_) {}
  }
  function saveStageDates() {
    try {
      const key = storageKeyForDates();
      if (!key) return;
      localStorage.setItem(key, JSON.stringify(stageSelectedAt));
    } catch (_) {}
  }

  function isGroupComplete(group) {
    return (group?.keys || []).every((s) => !!sectionComplete[stages.indexOf(s)]);
  }
  // Master-detail selection
  let selectedSectionTitle = $state('');
  let selectedItemTitle = $state('');
  const grantApplicationId = $derived(grant_application?.id);

  function isValidGroup(label) {
    return stageGroups.some((g) => g.label === label);
  }

  function setGroup(label) {
    if (!isValidGroup(label)) return;
    currentGroup = label;
    userSetGroup = true;
    try {
      const params = new URLSearchParams(window.location.search);
      params.set('tab', label);
      const newUrl = `${window.location.pathname}?${params.toString()}`;
      window.history.replaceState(null, '', newUrl);
    } catch (_) {}
    try {
      if (grantApplicationId) {
        localStorage.setItem(`grant:lastTab:${grantApplicationId}`, label);
      }
    } catch (_) {}
  }

  // Secondary stages row (labels like R&D page request)
  function formatSecondaryStageLabel(stage) {
    switch (stage) {
      case 'client_acquisition_project_qualification':
        return 'Acquisition';
      case 'client_invoiced':
        return 'Invoiced';
      case 'invoice_paid':
        return 'Invoice Paid';
      case 'preparing_for_kick_off_aml_resourcing':
        return 'Preparing';
      case 'kicked_off_in_progress':
        return 'In progress';
      case 'submitted':
        return 'Submitted';
      case 'awaiting_funding_decision':
        return 'Awaiting';
      case 'application_successful_or_not_successful':
        return 'Result';
      case 'resub_due':
        return 'Resub Due';
      case 'success_fee_invoiced':
        return 'Invoiced';
      case 'success_fee_paid':
        return 'Paid';
      default:
        return stage.replaceAll('_', ' ');
    }
  }

  function formatSelectedDateLabel(iso) {
    if (!iso) return '';
    try {
      const d = new Date(iso);
      return d.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
    } catch (_) {
      return '';
    }
  }

  onMount(() => {
    // Load any persisted dates for this grant
    loadStageDates();
    // Preference order: URL param → localStorage → stage-derived default
    try {
      const params = new URLSearchParams(window.location.search);
      const urlTab = params.get('tab');
      if (urlTab && isValidGroup(urlTab)) {
        setGroup(urlTab);
        return;
      }
    } catch (_) {}
    try {
      if (grantApplicationId) {
        const saved = localStorage.getItem(`grant:lastTab:${grantApplicationId}`);
        if (saved && isValidGroup(saved)) {
          setGroup(saved);
          return;
        }
      }
    } catch (_) {}
    // Fallback: leave stage-derived default
  });

  function visibleSectionIndicesForGroup(label) {
    switch (label) {
      case 'Pre-delivery':
        return [0,1,2,3];
      case 'In delivery':
        return [4,5];
      case 'Post delivery':
        return [6,7,8,9,10];
      default:
        return [];
    }
  }

  function formatStageLabel(stage) {
    switch (stage) {
      case 'client_acquisition_project_qualification':
        return 'Acquisition';
      case 'client_invoiced':
        return 'Invoiced';
      case 'invoice_paid':
        return 'Invoice paid';
      case 'preparing_for_kick_off_aml_resourcing':
        return 'KO Prep';
      case 'kicked_off_in_progress':
        return 'Kicked off';
      case 'submitted':
        return 'Submitted';
      case 'awaiting_funding_decision':
        return 'Awaiting';
      case 'application_successful_or_not_successful':
        return 'Funding Decision';
      case 'resub_due':
        return 'Resub Due';
      case 'success_fee_invoiced':
        return 'Invoiced';
      case 'success_fee_paid':
        return 'Paid';
      default:
        return stage.replaceAll('_', ' ');
    }
  }

  const stageStyles = {
    client_acquisition_project_qualification: { inactive: 'bg-secondary/20 text-secondary', active: 'bg-secondary text-secondary-content', complete: 'bg-secondary text-secondary-content', fillInactive: 'fill-secondary/20', fillActive: 'fill-secondary', fillComplete: 'fill-secondary' },
    client_invoiced: { inactive: 'bg-warning/20 text-warning', active: 'bg-warning text-warning-content', complete: 'bg-warning text-warning-content', fillInactive: 'fill-warning/20', fillActive: 'fill-warning', fillComplete: 'fill-warning' },
    invoice_paid: { inactive: 'bg-success/20 text-success', active: 'bg-success text-success-content', complete: 'bg-success text-success-content', fillInactive: 'fill-success/20', fillActive: 'fill-success', fillComplete: 'fill-success' },
    preparing_for_kick_off_aml_resourcing: { inactive: 'bg-info/20 text-info', active: 'bg-info text-info-content', complete: 'bg-info text-info-content', fillInactive: 'fill-info/20', fillActive: 'fill-info', fillComplete: 'fill-info' },
    kicked_off_in_progress: { inactive: 'bg-primary/20 text-primary', active: 'bg-primary text-primary-content', complete: 'bg-primary text-primary-content', fillInactive: 'fill-primary/20', fillActive: 'fill-primary', fillComplete: 'fill-primary' },
    submitted: { inactive: 'bg-accent/20 text-accent', active: 'bg-accent text-accent-content', complete: 'bg-accent text-accent-content', fillInactive: 'fill-accent/20', fillActive: 'fill-accent', fillComplete: 'fill-accent' },
    awaiting_funding_decision: { inactive: 'bg-neutral/20 text-neutral', active: 'bg-neutral text-neutral-content', complete: 'bg-neutral text-neutral-content', fillInactive: 'fill-neutral/20', fillActive: 'fill-neutral', fillComplete: 'fill-neutral' },
    application_successful_or_not_successful: { inactive: 'bg-base-content/20 text-base-content', active: 'bg-base-content text-base-100', complete: 'bg-base-content text-base-100', fillInactive: 'fill-base-content/20', fillActive: 'fill-base-content', fillComplete: 'fill-base-content' },
    resub_due: { inactive: 'bg-error/20 text-error', active: 'bg-error text-error-content', complete: 'bg-error text-error-content', fillInactive: 'fill-error/20', fillActive: 'fill-error', fillComplete: 'fill-error' },
    success_fee_invoiced: { inactive: 'bg-warning/20 text-warning', active: 'bg-warning text-warning-content', complete: 'bg-warning text-warning-content', fillInactive: 'fill-warning/20', fillActive: 'fill-warning', fillComplete: 'fill-warning' },
    success_fee_paid: { inactive: 'bg-success/20 text-success', active: 'bg-success text-success-content', complete: 'bg-success text-success-content', fillInactive: 'fill-success/20', fillActive: 'fill-success', fillComplete: 'fill-success' }
  };
  
  
  
  function handleStageChange(targetStage) {
    if (targetStage === currentStage) return;
    stageLoading = true;
    
    fetch(`/grant_applications/${grant_application.id}/change_stage`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ stage: targetStage })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        currentStage = targetStage;
        // Ensure the top tabs highlight follows the bottom stage
        userSetGroup = false;
        currentGroup = groupForStage(targetStage);
        // Record selection timestamp
        stageSelectedAt[targetStage] = new Date().toISOString();
        saveStageDates();
        toast.success(data.message || 'Stage updated successfully!');
        // Reload the page to get updated data
        router.reload();
      } else {
        toast.error(data.message || 'Failed to update stage.');
      }
    })
    .catch(error => {
      console.error('Error updating stage:', error);
      toast.error('Failed to update stage.');
    })
    .finally(() => {
      stageLoading = false;
    });
  }

  
  function handleDelete() {
    if (confirm('Are you sure you want to delete this grant application? This action cannot be undone.')) {
      router.delete(`/grant_applications/${grant_application.id}`, {
        onSuccess: () => {
          toast.success('Grant application deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete grant application.');
        }
      });
    }
  }
  
  function goBack() {
    router.visit('/grant_applications');
  }
 
</script>

<Layout {user}>
  <div class="max-w-7xl mx-auto">
    <!-- Sticky Header Section -->
    <div class="sticky top-16 z-10 bg-base-200/95 backdrop-blur-sm border-b border-base-300 pb-4">
      <!-- Header -->
      <div class="mb-6">
        <div class="flex justify-between items-start">
          <div class="flex items-start gap-3">
            <button 
              onclick={goBack} 
              class="btn btn-ghost btn-sm p-2 hover:bg-base-300"
              title="Back to Grant Applications"
              aria-label="Back to Grant Applications"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
              </svg>
            </button>
            <div>
              <h1 class="text-3xl font-bold text-base-content mb-1">{grant_application.title}</h1>
              <div class="text-base text-base-content/80 mb-2 flex flex-wrap items-center gap-x-3 gap-y-1">
                {#if grant_application.company}
                  <span>
                    <span class="opacity-70">Company:</span>
                    <a href={`/companies/${grant_application.company.id}`} class="text-black hover:underline ml-1">{grant_application.company.name}</a>
                  </span>
                {/if}
                {#if grant_application.grant_competition}
                  <span class="text-base-content/60">•</span>
                  <span>
                    <span class="opacity-70">Competition:</span>
                    <a href={`/grant_competitions/${grant_application.grant_competition.id}`} class="text-black hover:underline ml-1">{grant_application.grant_competition.grant_name}</a>
                  </span>
                  {#if grant_application.grant_competition.deadline}
                    <span class="text-base-content/60">•</span>
                    <span>
                      <span class="opacity-70">Deadline:</span>
                      <span class="ml-1">{new Date(grant_application.grant_competition.deadline).toLocaleDateString('en-GB', { day: '2-digit', month: '2-digit', year: 'numeric' })}</span>
                    </span>
                  {/if}
                {/if}
              </div>
            </div>
          </div>
          
          <div class="flex space-x-2">
            {#if grant_application.can_edit}
              <button 
                onclick={() => router.visit(`/grant_applications/${grant_application.id}/edit`)}
                class="btn btn-ghost btn-sm p-2 hover:bg-base-300"
                title="Edit Application"
                aria-label="Edit Application"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                </svg>
              </button>
            {/if}
          </div>
        </div>
      </div>

      <!-- Moved Pre/In/Post tabs from master view to header area -->
      <div class="mt-2 w-full">
        <div class="bg-white rounded-lg border border-base-300 shadow-sm p-3 mb-3 relative w-full">
          <div class="flex w-full select-none gap-2">
            {#each stageGroups as g, gi}
              {@const isActive = currentGroup === g.label}
              {@const isCompletedOrActiveGroup = gi <= currentGroupIdx}
              {@const bgClass = gi === 0
                ? (isCompletedOrActiveGroup ? 'bg-gray-700 text-white font-semibold' : 'bg-gray-100 text-gray-700')
                : (gi === 1
                  ? (isCompletedOrActiveGroup ? 'bg-blue-500 text-white font-semibold' : 'bg-gray-100 text-gray-700')
                  : (isCompletedOrActiveGroup ? 'bg-purple-600 text-white font-semibold' : 'bg-gray-100 text-gray-700'))}
              <div class="flex-1 min-w-0 flex flex-col items-stretch" style={`flex:${g.keys.length} 1 0%`}>
                <button
                  class={`relative justify-center items-center gap-2 px-5 py-2 text-sm transition-colors ${bgClass} ${gi === 1 ? 'rounded-none' : (gi === 0 ? 'rounded-l-lg' : 'rounded-r-lg')} outline-none focus:outline-none focus:ring-0`}
                  onclick={() => setGroup(g.label)}
                  aria-current={isActive ? 'page' : undefined}
                >
                  <span class="inline-flex items-center justify-center w-4 h-4">
                    {#if isGroupComplete(g)}
                      <svg class="w-4 h-4 text-success" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                    {/if}
                  </span>
                  <span>{g.label}</span>
                </button>
              </div>
            {/each}
          </div>

          <!-- Secondary row: Grant stages (moved inside same container) -->
          <div class="flex w-full gap-2 mt-3">
          {#each stages as s, si}
            {@const isFirst = si === 0}
            {@const isLast = si === stages.length - 1}
            {@const isActive = currentStage === s}
            {@const isInDeliveryStage = s === 'kicked_off_in_progress' || s === 'submitted'}
            {@const isPostDeliveryStage = s === 'awaiting_funding_decision' || s === 'application_successful_or_not_successful' || s === 'resub_due' || s === 'success_fee_invoiced' || s === 'success_fee_paid'}
            {@const isPreDeliveryStage = !isInDeliveryStage && !isPostDeliveryStage}
            {@const isCompletedOrActive = si <= idxCurrent}
            {@const bgClass = isInDeliveryStage
              ? (isCompletedOrActive ? 'bg-blue-500 text-white font-semibold' : 'bg-gray-100 text-gray-700')
              : (isPostDeliveryStage
                  ? (isCompletedOrActive ? 'bg-purple-600 text-white font-semibold' : 'bg-gray-100 text-gray-700')
                  : (isPreDeliveryStage
                      ? (isCompletedOrActive ? 'bg-gray-700 text-white font-semibold' : 'bg-gray-100 text-gray-700')
                      : (isCompletedOrActive ? 'bg-gray-200 text-gray-900 font-semibold' : 'bg-gray-100 text-gray-700')))}
            {@const clipPath = isFirst
              ? 'polygon(0 0, calc(100% - 12px) 0, 100% 50%, calc(100% - 12px) 100%, 0 100%)'
              : (isLast
                ? 'polygon(0 0, 100% 0, 100% 100%, 0 100%, 12px 50%)'
                : 'polygon(0 0, calc(100% - 12px) 0, 100% 50%, calc(100% - 12px) 100%, 0 100%, 12px 50%)')}
            <div class="flex-1 min-w-0 flex flex-col items-stretch">
              <button
                class={`relative flex-1 justify-center items-center gap-2 px-3 py-1 text-xs transition-colors ${bgClass} ${si > 0 ? 'border-l border-base-300' : ''} outline-none focus:outline-none focus:ring-0 ${!isLast ? 'z-10' : ''}`}
                onclick={() => handleStageChange(s)}
                aria-current={isActive ? 'page' : undefined}
                style={`clip-path:${clipPath}; border-top-left-radius:${isFirst ? '0.5rem' : '0'}; border-bottom-left-radius:${isFirst ? '0.5rem' : '0'}; border-top-right-radius:${isLast ? '0.5rem' : '0'}; border-bottom-right-radius:${isLast ? '0.5rem' : '0'};`}
                title={formatSecondaryStageLabel(s)}
              >
                <span class="sr-only">{formatSecondaryStageLabel(s)}</span>
                {formatSecondaryStageLabel(s)}
              </button>
              <div class="text-[11px] leading-tight text-base-content/60 text-center mt-1 h-4">
                {si <= idxCurrent && stageSelectedAt[s] ? formatSelectedDateLabel(stageSelectedAt[s]) : ''}
              </div>
            </div>
          {/each}
          </div>
        </div>
      </div>
      
      <!-- Stage Conflict Warning -->
      {#if stageConflictWarning}
        <div class="alert alert-warning mb-2 -mt-4">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
          </svg>
          <div class="flex-1">
            <h3 class="font-bold">Stage Conflict Detected</h3>
            <div class="text-xs mb-2">{stageConflictWarning}</div>
            
            {#if stageConflictDetails && stageConflictDetails.length > 0}
              <div class="text-xs">
                <div class="font-medium mb-1">To resolve this conflict, you need to:</div>
                <ul class="list-disc list-inside space-y-1">
                  {#each stageConflictDetails as detail}
                    <li class="flex items-center gap-2">
                      <span class="text-xs">
                        {#if detail.action === 'tick'}
                          <span class="text-success">✓</span>
                        {:else}
                          <span class="text-error">✗</span>
                        {/if}
                      </span>
                      <span>{detail.message}</span>
                    </li>
                  {/each}
                </ul>
              </div>
            {:else}
              <div class="text-xs mt-1">
                You can either:
                <ul class="list-disc list-inside mt-1">
                  <li>Complete the required checklist items to match the current stage</li>
                  <li>Manually change the stage to match the checklist completion</li>
                </ul>
              </div>
            {/if}
          </div>
        </div>
      {/if}
      
      
    </div>
    
    
    
      <!-- Checklist + Detail (Master-Detail) -->
      <div class="mt-6 grant-grid">
        <div class="grant-left">
          <GrantChecklistPane
            bind:checklistRef
            {stageGroups}
            {currentGroup}
            setCurrentGroup={setGroup}
            {isGroupComplete}
            {selectedSectionTitle}
            {selectedItemTitle}
            {checklist_items}
            {visibleSectionIndicesForGroup}
            showTabs={false}
            on:select={(e) => { selectedSectionTitle = e.detail.sectionTitle; selectedItemTitle = e.detail.itemTitle; }}
            on:change={(e) => {
              const { field, value, sectionTitle, itemTitle } = e.detail || {};
              const backendSection = sectionMapping[sectionTitle] || sectionTitle;
              const idx = checklist_items.findIndex(ci => ci.section === backendSection && ci.title === itemTitle);
              if (idx >= 0) {
                const updated = { ...checklist_items[idx], [field]: value };
                if (field === 'checked') updated.completed_at = value ? new Date().toISOString() : null;
                checklist_items[idx] = updated;
                checklist_items = [...checklist_items];
              }
            }}
            on:conflict-warning={(e) => { stageConflictWarning = e.detail.message; stageConflictDetails = e.detail.details; }}
            on:progress={(e) => { sectionComplete = e.detail.sectionComplete; }}
            on:stage={(e) => { currentStage = e.detail.stage; }}
          />
        </div>
        <!-- Right column -->
        <div class="bg-base-100 rounded-lg border border-base-300 shadow-sm p-4 lg:sticky lg:top-40 relative z-10 grant-right">
          <ChecklistTaskDetail {grantApplicationId} qualificationCostPence={grant_application?.qualification_cost_pence} sectionTitle={selectedSectionTitle} itemTitle={selectedItemTitle} persistedItems={checklist_items} on:change={(e) => {
            const { field, value, sectionTitle, itemTitle } = e.detail || {};
            const sec = sectionTitle || selectedSectionTitle;
            const tit = itemTitle || selectedItemTitle;
            if (!sec || !tit) return;
            // Optimistically update checklist_items array so detail rehydrates without refresh
            const backendSection = sectionMapping[sec] || sec;
            const idx = checklist_items.findIndex(ci => ci.section === backendSection && ci.title === tit);
            if (idx >= 0) {
              const updated = { ...checklist_items[idx], [field]: value };
              if (field === 'checked') {
                updated.completed_at = value ? new Date().toISOString() : null;
              }
              checklist_items[idx] = updated;
              // Force reactivity so child $effect sees new props
              checklist_items = [...checklist_items];
            }
            if (field === 'checked') {
              checklistRef?.setCheckedByTitle(sec, tit, value);
            }
          }} />
        </div>
      </div>
    </div>
</Layout> 