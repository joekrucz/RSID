<script>
  import { createEventDispatcher } from 'svelte';
  // Master-detail pane for task-specific content
  // Props: grantApplicationId, sectionTitle, itemTitle, persistedItems
  let { grantApplicationId, sectionTitle, itemTitle, persistedItems = [] } = $props();

  // Local fields
  let subbie = $state('');
  let noSubbie = $state(false);
  let contractLink = $state('');
  let checked = $state(false);
  let dueDate = $state('');

  const subbieFees = {
    'Leon Lever': 1000,
    'John Smith': 1500
  };

  function formatGBP(pence) {
    return `£${Number(pence).toLocaleString('en-GB')}`;
  }

  function feeFor(name) {
    if (noSubbie) return 0;
    if (!name) return null;
    return subbieFees[name] ?? 0;
  }

  // Hydrate local state from persistedItems when selection changes
  $effect(() => {
    // Immediately clear fields on task change for a clean slate
    subbie = '';
    noSubbie = false;
    contractLink = '';
    checked = false;
    dueDate = '';

    const found = (persistedItems || []).find(pi => pi.section === sectionTitle && pi.title === itemTitle);
    if (found) {
      subbie = found.subbie || '';
      noSubbie = !!found.no_subbie;
      contractLink = found.contract_link || '';
      checked = !!found.checked;
      dueDate = found.due_date || '';
    }
  });

  const dispatch = createEventDispatcher();

  async function save(attrs) {
    if (!grantApplicationId || !sectionTitle || !itemTitle) return;
    try {
      if (Object.prototype.hasOwnProperty.call(attrs, 'checked')) {
        // Optimistic UI update
        dispatch('change', { field: 'checked', value: attrs.checked, sectionTitle, itemTitle });
      }
      await fetch(`/grant_applications/${grantApplicationId}/grant_checklist_items/upsert`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        credentials: 'same-origin',
        body: JSON.stringify({
          section: sectionTitle,
          title: itemTitle,
          ...attrs
        })
      });
    } catch (e) {
      console.error('Failed to save task detail', e);
    }
  }

  function isAgreementSent() {
    return sectionTitle === 'Client Acquisition/Project Qualification' && itemTitle === 'Agreement Sent';
  }
</script>

<div class="bg-base-100 rounded-lg border border-base-300 shadow p-4 min-h-[12rem]">
  {#if !sectionTitle || !itemTitle}
    <div class="text-base-content/70">Select a checklist item to view details.</div>
  {:else}
    <div class="mb-4">
      <div class="text-sm text-base-content/60">{sectionTitle}</div>
      <h3 class="text-lg font-semibold text-base-content">{itemTitle}</h3>
    </div>
    {#if isAgreementSent()}
      <div class="space-y-4">
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Due</span>
            <input type="date" class="input input-sm input-bordered" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
          </label>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Subbie</div>
          <div class="flex items-center gap-3 flex-wrap">
            <select class="select select-bordered select-sm w-full max-w-xs" bind:value={subbie} disabled={noSubbie} onchange={() => save({ subbie })}>
              <option value="" disabled>Select subbie</option>
              <option value="Leon Lever">Leon Lever</option>
              <option value="John Smith">John Smith</option>
            </select>
            <label class="flex items-center gap-2 text-sm">
              <input type="checkbox" class="checkbox checkbox-sm" bind:checked={noSubbie} onchange={() => save({ no_subbie: noSubbie })} />
              No subbie
            </label>
          </div>
          {#if subbie && !noSubbie}
            <div class="text-xs opacity-60 mt-1">Fee: {formatGBP(feeFor(subbie))}</div>
          {/if}
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Contract Link</div>
          <input type="url" class="input input-bordered input-sm w-full" placeholder="https://..." bind:value={contractLink} onchange={() => save({ contract_link: contractLink })} />
        </div>
      </div>
    {:else}
      <div class="space-y-4">
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Due</span>
            <input type="date" class="input input-sm input-bordered" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
          </label>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Subbie</div>
          <div class="flex items-center gap-3 flex-wrap">
            <select class="select select-bordered select-sm w-full max-w-xs" bind:value={subbie} disabled={noSubbie} onchange={() => save({ subbie })}>
              <option value="" disabled>Select subbie</option>
              <option value="Leon Lever">Leon Lever</option>
              <option value="John Smith">John Smith</option>
            </select>
            <label class="flex items-center gap-2 text-sm">
              <input type="checkbox" class="checkbox checkbox-sm" bind:checked={noSubbie} onchange={() => save({ no_subbie: noSubbie })} />
              No subbie
            </label>
          </div>
          {#if subbie && !noSubbie}
            <div class="text-xs opacity-60 mt-1">Fee: {formatGBP(feeFor(subbie))}</div>
          {/if}
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Contract Link</div>
          <input type="url" class="input input-bordered input-sm w-full" placeholder="https://..." bind:value={contractLink} onchange={() => save({ contract_link: contractLink })} />
        </div>
      </div>
    {/if}
  {/if}
</div>