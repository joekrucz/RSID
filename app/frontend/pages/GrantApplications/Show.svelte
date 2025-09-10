<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Checklist from '../../components/Checklist.svelte';
  import ChecklistTaskDetail from '../../components/ChecklistTaskDetail.svelte';
  let checklistRef;
  
  let { user, grant_application, checklist_items = [] } = $props();
  
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
  $effect(() => { currentGroup = groupForStage(currentStage); });

  function isGroupComplete(group) {
    return (group?.keys || []).every((s) => !!sectionComplete[stages.indexOf(s)]);
  }
  // Master-detail selection
  let selectedSectionTitle = $state('');
  let selectedItemTitle = $state('');
  const grantApplicationId = $derived(grant_application?.id);

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
        return 'Client Acquisition';
      case 'client_invoiced':
        return 'Client invoiced';
      case 'invoice_paid':
        return 'Invoice paid';
      case 'preparing_for_kick_off_aml_resourcing':
        return 'KO Prep';
      case 'kicked_off_in_progress':
        return 'Kicked off';
      case 'submitted':
        return 'Submitted';
      case 'awaiting_funding_decision':
        return 'Awaiting funding decision';
      case 'application_successful_or_not_successful':
        return 'Funding Decision';
      case 'resub_due':
        return 'Resub Due';
      case 'success_fee_invoiced':
        return 'Success fee invoiced';
      case 'success_fee_paid':
        return 'Success fee paid';
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
      <div class="mt-6 grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        <div class="lg:col-span-5 xl:col-span-4 bg-base-100 rounded-lg border border-base-300 shadow-sm p-4 lg:max-h-[60vh] overflow-y-auto">
          <div class="inline-flex items-stretch select-none mb-3">
            {#each stageGroups as g, gi}
              {@const isActive = currentGroup === g.label}
              {@const bgClass = isActive ? 'bg-gray-200 text-gray-900 font-semibold' : 'bg-gray-100 text-gray-700'}
              <button
                class={`relative flex items-center gap-2 px-5 py-2 text-sm transition-colors whitespace-nowrap ${bgClass} ${gi > 0 ? 'pl-12 -ml-6' : ''} outline-none focus:outline-none focus:ring-0`}
                onclick={() => currentGroup = g.label}
                aria-current={isActive ? 'page' : undefined}
                style={`border-top-left-radius:${gi === 0 ? '0.5rem' : '0'}; border-bottom-left-radius:${gi === 0 ? '0.5rem' : '0'}; z-index:${100 - gi};`}
              >
                {#if gi > 0}
                  <span class="absolute left-0 top-0 h-full w-px bg-base-300"></span>
                {/if}
                {#if isGroupComplete(g)}
                  <svg class="w-4 h-4 text-success" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                {/if}
                <span>{g.label}</span>
                {#if gi < stageGroups.length - 1}
                  <span class="pointer-events-none absolute -right-6 top-0 h-full w-6" aria-hidden="true" style={`z-index:${101 - gi}` }>
                    <span class={`absolute inset-0 ${isActive ? 'bg-gray-200' : 'bg-gray-100'}`}
                          style="clip-path: polygon(0% 0%, 100% 50%, 0% 100%);"></span>
                    <span class="absolute inset-y-0 right-5 w-px bg-base-300"
                          style="transform: skewX(-25deg);"></span>
                  </span>
                {/if}
              </button>
            {/each}
          </div>
          <Checklist bind:this={checklistRef} selectedSectionTitle={selectedSectionTitle} selectedItemTitle={selectedItemTitle} on:select={(e) => { selectedSectionTitle = e.detail.sectionTitle; selectedItemTitle = e.detail.itemTitle; }} on:conflict-warning={(e) => { stageConflictWarning = e.detail.message; stageConflictDetails = e.detail.details; }} visibleIndices={visibleSectionIndicesForGroup(currentGroup)} persistedItems={checklist_items} sections={[
          {
            title: 'Client Acquisition',
            items: [
              { title: 'Project Qualification' },
              { title: 'Proposal Presented' },
              { title: 'Agreement Sent' },
              { title: 'New Project Handover Sent To Delivery' },
              { title: 'Deal marked as "won" / "lost"' }
            ]
          },
          {
            title: 'Client Invoiced',
            items: [ { title: 'Invoice Sent' } ]
          },
          {
            title: 'Invoice Paid',
            items: [ { title: 'Payment Received' } ]
          },
          {
            title: 'KO Prep',
            items: [
              { title: 'AML Checks Completed' },
              { title: 'Project Resourced' },
              { title: 'Project Set Up - Slack Channel, Delivery Folders, Etc.' }
            ]
          },
          {
            title: 'Kicked Off',
            items: [
              { title: 'Kick Off Call Confirmed' },
              { title: 'Timeline Confirmed and Accepted by Client' },
              { title: 'Drafting' },
              { title: 'Reviews Confirmed' },
              { title: 'Eligibility Checks Completed' }
            ]
          },
          {
            title: 'Submitted',
            items: [ { title: 'Application Submitted' } ]
          },
          { title: 'Awaiting Funding Decision', items: [ { title: 'Completed' } ] },
          { title: 'Funding Decision', items: [ { title: 'Completed' } ] },
          { title: 'Resub Due', items: [ { title: 'Completed' } ] },
          { title: 'Success Fee Invoiced', items: [ { title: 'Completed' } ] },
          { title: 'Success Fee Paid', items: [ { title: 'Completed' } ] }
        ]} on:progress={(e) => { sectionComplete = e.detail.sectionComplete; }} on:stage={(e) => { currentStage = e.detail.stage; }} />
        </div>
        <div class="lg:col-span-7 xl:col-span-8 bg-base-100 rounded-lg border border-base-300 shadow-sm p-4 lg:sticky lg:top-40">
          <h2 class="text-xl font-semibold text-gray-900 mb-3">Task Details</h2>
          <ChecklistTaskDetail {grantApplicationId} sectionTitle={selectedSectionTitle} itemTitle={selectedItemTitle} persistedItems={checklist_items} on:change={(e) => {
            const { field, value, sectionTitle, itemTitle } = e.detail || {};
            if (field === 'checked') {
              checklistRef?.setCheckedByTitle(sectionTitle || selectedSectionTitle, itemTitle || selectedItemTitle, value);
            }
          }} />
        </div>
      </div>
    </div>
</Layout> 