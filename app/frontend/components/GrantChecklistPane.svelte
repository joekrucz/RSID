<script>
  import Checklist from './Checklist.svelte';
  let { 
    checklistRef = null,
    stageGroups = [],
    currentGroup = 'Pre-delivery',
    setCurrentGroup = (g) => {},
    isGroupComplete = () => false,
    selectedSectionTitle = '',
    selectedItemTitle = '',
    checklist_items = [],
    visibleSectionIndicesForGroup = () => [],
  } = $props();

  // The component just renders tabs + checklist and forwards events upward
</script>

<div class="bg-white rounded-lg border border-base-300 shadow-sm p-3 mb-3 relative overflow-hidden">
  <div class="inline-flex items-stretch select-none">
    {#each stageGroups as g, gi}
      {@const isActive = currentGroup === g.label}
      {@const bgClass = isActive ? 'bg-gray-200 text-gray-900 font-semibold' : 'bg-gray-100 text-gray-700'}
      <button
        class={`relative flex items-center gap-2 px-5 py-2 text-sm transition-colors whitespace-nowrap ${bgClass} ${gi > 0 ? 'pl-12 -ml-6' : ''} outline-none focus:outline-none focus:ring-0`}
        onclick={() => setCurrentGroup(g.label)}
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
</div>

<div class="bg-base-100 rounded-lg border border-base-300 shadow-sm p-4 lg:max-h-[60vh] overflow-y-auto z-0">
  <Checklist
    bind:this={checklistRef}
    {selectedSectionTitle}
    {selectedItemTitle}
    on:select
    on:conflict-warning
    on:progress
    on:stage
    visibleIndices={visibleSectionIndicesForGroup(currentGroup)}
    persistedItems={checklist_items}
    sections={[
      { title: 'Client Acquisition', items: [ { title: 'Project Qualification' }, { title: 'Proposal Presented' }, { title: 'Agreement Sent' }, { title: 'New Project Handover Sent To Delivery' }, { title: 'Deal marked as "won" / "lost"' } ] },
      { title: 'Client Invoiced', items: [ { title: 'Invoice Sent' } ] },
      { title: 'Invoice Paid', items: [ { title: 'Payment Received' } ] },
      { title: 'KO Prep', items: [ { title: 'AML Checks Completed' }, { title: 'Project Resourced' }, { title: 'Project Set Up - Slack Channel, Delivery Folders, Etc.' } ] },
      { title: 'Kicked Off', items: [ { title: 'Kick Off Call Confirmed' }, { title: 'Timeline Confirmed and Accepted by Client' }, { title: 'Drafting' }, { title: 'Reviews Confirmed' }, { title: 'Eligibility Checks Completed' } ] },
      { title: 'Submitted', items: [ { title: 'Application Submitted' } ] },
      { title: 'Awaiting Funding Decision', items: [ { title: 'Completed' } ] },
      { title: 'Funding Decision', items: [ { title: 'Completed' } ] },
      { title: 'Resub Due', items: [ { title: 'Completed' } ] },
      { title: 'Success Fee Invoiced', items: [ { title: 'Completed' } ] },
      { title: 'Success Fee Paid', items: [ { title: 'Completed' } ] }
    ]}
  />
</div>


