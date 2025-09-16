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
    // Match actual section/item titles from the checklist
    return sectionTitle === 'Client Acquisition' && itemTitle === 'Agreement Sent';
  }

  function isInvoiceSent() {
    return sectionTitle === 'Client Invoiced' && itemTitle === 'Invoice Sent';
  }

  function isPaymentReceived() {
    return sectionTitle === 'Invoice Paid' && itemTitle === 'Payment Received';
  }

  function isKickOffConfirmed() {
    return sectionTitle === 'Kicked Off' && itemTitle === 'Kick Off Call Confirmed';
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
    {:else if isInvoiceSent()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Invoice Number</div>
          <input type="text" class="input input-bordered input-sm w-full" placeholder="INV-..." onchange={(e) => save({ invoice_number: e.target.value })} />
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Invoice Date</div>
          <input type="date" class="input input-sm input-bordered" onchange={(e) => save({ invoice_date: e.target.value })} />
        </div>
      </div>
    {:else if isPaymentReceived()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Amount Received</div>
          <input type="number" min="0" step="0.01" class="input input-bordered input-sm w-full" placeholder="0.00" onchange={(e) => save({ amount_received: e.target.value })} />
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Payment Date</div>
          <input type="date" class="input input-sm input-bordered" onchange={(e) => save({ payment_date: e.target.value })} />
        </div>
      </div>
    {:else if isKickOffConfirmed()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Kick Off Date</div>
          <input type="date" class="input input-sm input-bordered" onchange={(e) => save({ kick_off_date: e.target.value })} />
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea class="textarea textarea-bordered textarea-sm w-full" placeholder="Notes..." onchange={(e) => save({ notes: e.target.value })}></textarea>
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
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea class="textarea textarea-bordered textarea-sm w-full" placeholder="Notes..." onchange={(e) => save({ notes: e.target.value })}></textarea>
        </div>
      </div>
    {/if}
  {/if}
</div>