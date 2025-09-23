<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Input from '../../components/forms/Input.svelte';
  import Select from '../../components/forms/Select.svelte';
  import Checklist from '../../components/Checklist.svelte';
  
  let { user, rnd_claim, can_edit } = $props();
  
  const stages = [
    'upcoming',
    'readying_for_delivery',
    'in_progress',
    'finalised',
    'filed_awaiting_hmrc',
    'claim_processed',
    'client_invoiced',
    'paid'
  ];
  
  // Group stages to mirror Grant Applications: Pre-delivery, In delivery, Post delivery
  const stageGroups = [
    { label: 'Pre-delivery', keys: ['upcoming', 'readying_for_delivery'] },
    { label: 'In delivery', keys: ['in_progress', 'finalised'] },
    { label: 'Post delivery', keys: ['filed_awaiting_hmrc', 'claim_processed', 'client_invoiced', 'paid'] }
  ];
  function groupForStage(stage) {
    const found = stageGroups.find(g => g.keys.includes(stage));
    return found?.label || 'Pre-delivery';
  }
  function groupIndexForStage(stage) {
    return stageGroups.findIndex(g => g.keys.includes(stage));
  }
  
  let currentStage = $state(rnd_claim.stage || 'upcoming');
  let stageLoading = $state(false);
  const idxCurrent = $derived(stages.indexOf(currentStage));
  // Track when each stage was selected (ISO strings)
  let stageSelectedAt = $state({});
  // Initialize currently active stage selection date if not present
  $effect(() => {
    if (currentStage && !stageSelectedAt[currentStage]) {
      stageSelectedAt[currentStage] = new Date().toISOString();
    }
  });
  let currentGroup = $state(groupForStage(currentStage));
  let userSetGroup = $state(false);
  const currentGroupIdx = $derived(groupIndexForStage(currentStage));
  $effect(() => { if (!userSetGroup) currentGroup = groupForStage(currentStage); });
  
  function isGroupCompleteLabel(label) {
    const idx = stageGroups.findIndex(g => g.label === label);
    return idx > -1 && idx < currentGroupIdx;
  }
  function setGroup(label) {
    currentGroup = label;
    userSetGroup = true;
  }

  const stageStyles = {
    upcoming: { inactive: 'bg-secondary/20 text-secondary', active: 'bg-secondary text-secondary-content', complete: 'bg-secondary text-secondary-content', fillInactive: 'fill-secondary/20', fillActive: 'fill-secondary', fillComplete: 'fill-secondary' },
    readying_for_delivery: { inactive: 'bg-warning/20 text-warning', active: 'bg-warning text-warning-content', complete: 'bg-warning text-warning-content', fillInactive: 'fill-warning/20', fillActive: 'fill-warning', fillComplete: 'fill-warning' },
    in_progress: { inactive: 'bg-info/20 text-info', active: 'bg-info text-info-content', complete: 'bg-info text-info-content', fillInactive: 'fill-info/20', fillActive: 'fill-info', fillComplete: 'fill-info' },
    finalised: { inactive: 'bg-primary/20 text-primary', active: 'bg-primary text-primary-content', complete: 'bg-primary text-primary-content', fillInactive: 'fill-primary/20', fillActive: 'fill-primary', fillComplete: 'fill-primary' },
    filed_awaiting_hmrc: { inactive: 'bg-accent/20 text-accent', active: 'bg-accent text-accent-content', complete: 'bg-accent text-accent-content', fillInactive: 'fill-accent/20', fillActive: 'fill-accent', fillComplete: 'fill-accent' },
    claim_processed: { inactive: 'bg-neutral/20 text-neutral', active: 'bg-neutral text-neutral-content', complete: 'bg-neutral text-neutral-content', fillInactive: 'fill-neutral/20', fillActive: 'fill-neutral', fillComplete: 'fill-neutral' },
    client_invoiced: { inactive: 'bg-base-content/20 text-base-content', active: 'bg-base-content text-base-100', complete: 'bg-base-content text-base-100', fillInactive: 'fill-base-content/20', fillActive: 'fill-base-content', fillComplete: 'fill-base-content' },
    paid: { inactive: 'bg-success/20 text-success', active: 'bg-success text-success-content', complete: 'bg-success text-success-content', fillInactive: 'fill-success/20', fillActive: 'fill-success', fillComplete: 'fill-success' }
  };
  
  function handleStageChange(targetStage) {
    if (targetStage === currentStage) return;
    stageLoading = true;
    
    fetch(`/rnd_claims/${rnd_claim.id}/change_stage`, {
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
        // Record selection timestamp (to nearest day via display formatting)
        stageSelectedAt[targetStage] = new Date().toISOString();
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
  
  function goBack() {
    router.visit('/rnd_claims');
  }
  
  function navigateTo(path) {
    router.visit(path);
  }
  
  function formatStageLabel(stage) {
    switch (stage) {
      case 'upcoming':
        return 'Upcoming';
      case 'readying_for_delivery':
        return 'Readying for delivery';
      case 'in_progress':
        return 'In progress';
      case 'finalised':
        return 'Finalised';
      case 'filed_awaiting_hmrc':
        return 'Filed (awaiting HMRC)';
      case 'claim_processed':
        return 'Claim processed';
      case 'client_invoiced':
        return 'Client invoiced';
      case 'paid':
        return 'Paid';
      default:
        return stage.replaceAll('_', ' ');
    }
  }

  function formatSelectedDateLabel(iso) {
    if (!iso) return '';
    try {
      const d = new Date(iso);
      return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
    } catch (_) {
      return '';
    }
  }
  
</script>

<svelte:head>
  <title>{rnd_claim.title} - R&D Project - RSID App</title>
</svelte:head>

<Layout {user}>
  <!-- Sticky Header Section -->
  <div class="sticky top-16 z-10 bg-base-200/95 backdrop-blur-sm border-b border-base-300 pb-4">
    <!-- Header -->
    <div class="mb-8">
      <div class="flex items-center justify-between mb-4">
        <div>
          <div class="flex items-center flex-wrap gap-x-3 gap-y-1">
            <button 
              onclick={goBack} 
              class="btn btn-ghost btn-sm p-2 hover:bg-base-300 text-gray-700"
              title="Back to R&D Claims"
              aria-label="Back to R&D Claims"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
            </svg>
          </button>
            <h1 class="text-3xl font-bold text-base-content">{rnd_claim.title}</h1>
            {#if rnd_claim.company}
              <span class="text-base-content/60">•</span>
              <span class="text-base text-base-content/80">
                <span class="opacity-70">Company:</span>
                <a href={`/companies/${rnd_claim.company.id}`} class="text-black hover:underline ml-1">{rnd_claim.company.name}</a>
              </span>
            {/if}
          </div>
        </div>
        {#if can_edit}
          <div class="flex space-x-2">
            <button 
              onclick={() => navigateTo(`/rnd_claims/${rnd_claim.id}/edit`)}
              class="btn btn-ghost btn-sm p-2 text-gray-700 hover:text-gray-900 hover:bg-base-300"
              title="Edit"
              aria-label="Edit Project"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
              </svg>
            </button>
          </div>
        {/if}
      </div>
    </div>
    
    <!-- Stages (Inline copy of Grant tabs UI) -->
    {#key currentStage}
    <div class="mt-2 w-full">
      <div class="bg-white rounded-lg border border-base-300 shadow-sm p-3 mb-3 relative">
        <div class="flex w-full select-none">
          {#each stageGroups as g, gi}
            {@const isActive = currentGroup === g.label}
            {@const isCompletedOrActiveGroup = gi <= currentGroupIdx}
            {@const bgClass = isCompletedOrActiveGroup 
              ? (gi === 0 
                  ? 'bg-gray-700 text-white font-semibold' 
                  : gi === 1 
                    ? 'bg-blue-500 text-white font-semibold' 
                    : 'bg-purple-600 text-white font-semibold')
              : (gi === 1 
                  ? 'bg-blue-100 text-blue-700' 
                  : gi === 2
                    ? 'bg-purple-100 text-purple-700'
                    : 'bg-gray-100 text-gray-700')}
            {@const isFirst = gi === 0}
            {@const isLast = gi === stageGroups.length - 1}
            {@const clipPath = isFirst
              ? 'polygon(0 0, calc(100% - 12px) 0, 100% 50%, calc(100% - 12px) 100%, 0 100%)'
              : (isLast
                ? 'polygon(0 0, 100% 0, 100% 100%, 0 100%, 12px 50%)'
                : 'polygon(0 0, calc(100% - 12px) 0, 100% 50%, calc(100% - 12px) 100%, 0 100%, 12px 50%)')}
            <div class="flex-1 min-w-0 flex flex-col items-stretch" style={`flex:${g.keys.length} 1 0%`}>
              <div class="text-xs text-base-content/60 text-center mb-1 h-4">{gi === 1 ? 'Planned: 2nd May - 10th May' : ''}</div>
            <button
                class={`relative justify-center items-center gap-2 px-5 py-2 text-sm transition-colors ${bgClass} ${gi > 0 ? 'border-l border-base-300' : ''} outline-none focus:outline-none focus:ring-0 ${!isLast ? 'z-10' : ''}`}
                onclick={() => setGroup(g.label)}
                aria-current={isActive ? 'page' : undefined}
                style={`clip-path:${clipPath}; border-top-left-radius:${isFirst ? '0.5rem' : '0'}; border-bottom-left-radius:${isFirst ? '0.5rem' : '0'}; border-top-right-radius:${isLast ? '0.5rem' : '0'}; border-bottom-right-radius:${isLast ? '0.5rem' : '0'};`}
              >
                <span class="inline-flex items-center justify-center w-4 h-4">
                  {#if isGroupCompleteLabel(g.label)}
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
        
        <!-- Secondary row: R&D Claim delivery stages for selected group -->
        <div class="flex w-full gap-2 mt-3">
          {#each stages as s, si}
            {@const isFirst = si === 0}
            {@const isLast = si === stages.length - 1}
            {@const isActive = currentStage === s}
            {@const isInDeliveryStage = s === 'in_progress' || s === 'finalised'}
            {@const isPostDeliveryStage = s === 'filed_awaiting_hmrc' || s === 'claim_processed' || s === 'client_invoiced' || s === 'paid'}
            {@const isPreDeliveryStage = s === 'upcoming' || s === 'readying_for_delivery'}
            {@const isCompletedOrActive = si <= idxCurrent}
            {@const bgClass = isInDeliveryStage
              ? (isCompletedOrActive ? 'bg-blue-500 text-white font-semibold' : 'bg-blue-100 text-blue-700')
              : (isPostDeliveryStage
                  ? (isCompletedOrActive ? 'bg-purple-600 text-white font-semibold' : 'bg-purple-100 text-purple-700')
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
                title={formatStageLabel(s)}
              >
                <span class="sr-only">{formatStageLabel(s)}</span>
                {formatStageLabel(s)}
              </button>
              <div class="text-[11px] leading-tight text-base-content/60 text-center mt-1 h-4">
                {si === idxCurrent && stageSelectedAt[s] ? `Selected: ${formatSelectedDateLabel(stageSelectedAt[s])}` : ''}
              </div>
            </div>
        {/each}
        </div>
      </div>
      {#if stageLoading}
        <span class="loading loading-spinner loading-xs align-middle ml-2"></span>
      {/if}
    </div>
    {/key}
    
    <!-- Content removed as requested -->

    <!-- Master-Detail (empty placeholders) -->
    <div class="mt-6 grid grid-cols-1 lg:grid-cols-3 gap-4">
      <!-- Master Pane -->
      <section class="bg-base-100 rounded-lg border border-base-300 shadow-sm p-4 lg:sticky lg:top-40" role="region" aria-label="R&D Master List">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-base font-semibold text-base-content">Master</h2>
        </div>
        <div class="text-base-content/90 text-sm">
          <Checklist
            sections={[
              { title: 'General (CSM)', items: [
                { title: 'Kick off completed' },
                { title: 'AML check completed' },
                { title: 'Letter of authority signed' }
              ]},
              { title: 'Financials (FC)', items: [
                { title: 'Tax account access established' },
                { title: 'Org structure compiled and confirmed by client' },
                { title: 'Financial information received' },
                { title: 'Pipedrive updated with latest claim details' }
              ]},
              { title: 'Technicals (TC)', items: [
                { title: 'Project list completed' },
                { title: 'Technical narrative completed' }
              ]},
              { title: 'Finalising and filing (FC)', items: [
                { title: 'Apportionments completed' },
                { title: 'Calculations done' },
                { title: 'Claim report compiled' },
                { title: 'Signoff statements compiled' },
                { title: 'Amended tax docs created (Delete if N/A)' },
                { title: 'Ready for verification?' },
                { title: 'Claim verified' },
                { title: 'Claim finalised' },
                { title: 'AIF submitted' },
                { title: 'Submission pack sent to client for signoff' },
                { title: 'Claim filed' }
              ]}
                    ]}
                  />
                </div>
      </section>

      <!-- Detail Pane -->
      <section class="bg-base-100 rounded-lg border border-base-300 shadow-sm p-4 lg:col-span-2" role="region" aria-label="R&D Detail View">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-base font-semibold text-base-content">Detail</h2>
        </div>
        <div class="text-base-content/50 text-sm">
          <!-- Empty detail component placeholder -->
        <div class="text-center py-12">
            <svg class="w-10 h-10 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <p>Select an item to view details</p>
          </div>
        </div>
      </section>
        </div>
    </div>
</Layout> 