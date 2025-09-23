<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Input from '../../components/forms/Input.svelte';
  import Select from '../../components/forms/Select.svelte';
  
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
  
  let currentStage = $state(rnd_claim.stage || 'upcoming');
  let stageLoading = $state(false);
  const idxCurrent = $derived(stages.indexOf(currentStage));

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
          <button onclick={goBack} class="btn btn-ghost btn-sm mb-2">
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
            </svg>
            Back to R&D Claims
          </button>
          <div class="flex items-center space-x-4">
            <h1 class="text-3xl font-bold text-base-content">{rnd_claim.title}</h1>
          </div>
        </div>
        {#if can_edit}
          <div class="flex space-x-2">
            <Button variant="secondary" onclick={() => navigateTo(`/rnd_claims/${rnd_claim.id}/edit`)}>
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
              </svg>
              Edit Project
            </Button>
          </div>
        {/if}
      </div>
    </div>
    
    <!-- Stages -->
    {#key currentStage}
    <div class="mt-2 w-full">
      <ul class="flex items-stretch w-full gap-0">
        {#each stages as s, i}
          {@const isComplete = idxCurrent > i}
          {@const isActive = idxCurrent === i}
          {@const palette = stageStyles[s] || { inactive: 'bg-base-300 text-base-content', active: 'bg-base-content text-base-100', complete: 'bg-base-content text-base-100', fillInactive: 'fill-base-300', fillActive: 'fill-base-content', fillComplete: 'fill-base-content' }}
          <li class="relative flex items-stretch flex-1 min-w-0">
            <button
              class={`h-6 px-2 rounded-l-md w-full ${isComplete ? palette.complete : isActive ? palette.active : palette.inactive}`}
              disabled={stageLoading}
              onclick={() => handleStageChange(s)}
              title={s.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
              aria-current={currentStage === s ? 'step' : undefined}
            >
              <span class="sr-only">{s.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}</span>
            </button>
            {#if i < stages.length - 1}
              <svg class="h-6 w-2 -ml-px" viewBox="0 0 14 32" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                <polygon points="0,0 14,16 0,32" class={isComplete ? palette.fillComplete : isActive ? palette.fillActive : palette.fillInactive} />
              </svg>
            {/if}
          </li>
        {/each}
      </ul>
      {#if stageLoading}
        <span class="loading loading-spinner loading-xs align-middle ml-2"></span>
      {/if}
    </div>
    {/key}
    
    
  </div>

  <!-- Content removed as requested -->
</Layout> 