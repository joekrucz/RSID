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
  let notes = $state('');
  let documents = $state([]);
  let docsLoading = $state(false);
  let uploadInProgress = $state(false);
  let dealOutcome = $state(''); // 'won' | 'lost'
  let reviewDeliveredOn = $state('');

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
    notes = '';
    documents = [];

    const found = (persistedItems || []).find(pi => pi.section === sectionTitle && pi.title === itemTitle);
    if (found) {
      subbie = found.subbie || '';
      noSubbie = !!found.no_subbie;
      contractLink = found.contract_link || '';
      checked = !!found.checked;
      dueDate = found.due_date || '';
      notes = found.notes || '';
      reviewDeliveredOn = found.review_delivered_on || '';
      if (notes === 'won' || notes === 'lost') {
        dealOutcome = notes;
      } else {
        dealOutcome = '';
      }
    }
    // Fetch documents for this task
    if (grantApplicationId && sectionTitle && itemTitle) {
      fetchDocuments();
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

  async function fetchDocuments() {
    if (!grantApplicationId || !sectionTitle || !itemTitle) return;
    try {
      docsLoading = true;
      const res = await fetch(`/grant_applications/${grantApplicationId}/grant_documents?section=${encodeURIComponent(sectionTitle)}&title=${encodeURIComponent(itemTitle)}`);
      const data = await res.json();
      if (data?.success) {
        documents = data.documents || [];
      }
    } catch (e) {
      console.error('Failed to load documents', e);
    } finally {
      docsLoading = false;
    }
  }

  async function uploadDocument(file) {
    if (!file || !grantApplicationId || !sectionTitle || !itemTitle) return;
    try {
      uploadInProgress = true;
      const form = new FormData();
      form.append('file', file);
      form.append('section', sectionTitle);
      form.append('title', itemTitle);
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
      if (csrfToken) form.append('authenticity_token', csrfToken);
      const res = await fetch(`/grant_applications/${grantApplicationId}/grant_documents`, {
        method: 'POST',
        headers: csrfToken ? { 'X-CSRF-Token': csrfToken } : {},
        body: form
      });
      const data = await res.json();
      if (!res.ok || !data?.success) {
        throw new Error(data?.error || (data?.errors || []).join(', ') || 'Upload failed');
      }
      await fetchDocuments();
    } catch (e) {
      console.error('Upload failed', e);
    } finally {
      uploadInProgress = false;
    }
  }

  async function deleteDocument(id) {
    if (!id || !grantApplicationId) return;
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
      const res = await fetch(`/grant_applications/${grantApplicationId}/grant_documents/${id}`, { method: 'DELETE', headers: csrfToken ? { 'X-CSRF-Token': csrfToken } : {} });
      const data = await res.json();
      if (data?.success) {
        documents = documents.filter(d => d.id !== id);
      }
    } catch (e) {
      console.error('Delete failed', e);
    }
  }

  function isProjectQualification() {
    // Match actual section/item titles from the checklist
    return sectionTitle === 'Client Acquisition' && itemTitle === 'Project Qualification';
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

  function isAgreementSent() {
    return sectionTitle === 'Client Acquisition' && itemTitle === 'Agreement Sent';
  }

  function isNewProjectHandover() {
    return sectionTitle === 'Client Acquisition' && itemTitle === 'New Project Handover Sent To Delivery';
  }

  function isDealOutcome() {
    return sectionTitle === 'Client Acquisition' && itemTitle === 'Deal marked as "won" / "lost"';
  }

  function isAmlChecksCompleted() {
    return sectionTitle === 'KO Prep' && itemTitle === 'AML Checks Completed';
  }

  function isProjectResourced() {
    return sectionTitle === 'KO Prep' && itemTitle === 'Project Resourced';
  }

  function isProjectSetup() {
    return sectionTitle === 'KO Prep' && itemTitle === 'Project Set Up - Slack Channel, Delivery Folders, Etc.';
  }

  function isTimelineConfirmed() {
    return sectionTitle === 'Kicked Off' && itemTitle === 'Timeline Confirmed and Accepted by Client';
  }

  function isReviewsConfirmed() {
    return sectionTitle === 'Kicked Off' && itemTitle === 'Reviews Confirmed';
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
    {#if isProjectQualification()}
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
          <div class="text-sm font-medium mb-1">Upload Documents</div>
          <div class="flex items-center gap-2">
            <input type="file" class="file-input file-input-sm file-input-bordered" onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); e.currentTarget.value = ''; }} disabled={uploadInProgress} />
            {#if uploadInProgress}
              <span class="loading loading-spinner loading-sm"></span>
            {/if}
          </div>
          <div class="mt-2 text-xs text-base-content/60">Files are stored under this grant and linked to this task.</div>
          <ul class="mt-2 space-y-1">
            {#if docsLoading}
              <li class="text-sm">Loading documents...</li>
            {:else if documents.length === 0}
              <li class="text-sm text-base-content/60">No documents uploaded yet.</li>
            {:else}
              {#each documents as d}
                <li class="flex items-center justify-between text-sm bg-base-200 rounded px-2 py-1">
                  <a class="link" href={d.file_path} target="_blank" rel="noopener noreferrer">{d.name}</a>
                  <button class="btn btn-ghost btn-xs" onclick={() => { if (confirm('Delete this document? This action cannot be undone.')) deleteDocument(d.id); }}>Delete</button>
                </li>
              {/each}
            {/if}
          </ul>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea class="textarea textarea-bordered textarea-sm w-full" placeholder="Notes..." bind:value={notes} onchange={() => save({ notes })}></textarea>
        </div>
      </div>
    {:else if isAgreementSent()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Client Contract Link</div>
          <input type="url" class="input input-bordered input-sm w-full" placeholder="https://..." bind:value={contractLink} onchange={() => save({ contract_link: contractLink })} />
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Upload Documents</div>
          <div class="flex items-center gap-2">
            <input type="file" class="file-input file-input-sm file-input-bordered" onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); e.currentTarget.value = ''; }} disabled={uploadInProgress} />
            {#if uploadInProgress}
              <span class="loading loading-spinner loading-sm"></span>
            {/if}
          </div>
          <div class="mt-2 text-xs text-base-content/60">Files are stored under this grant and linked to this task.</div>
          <ul class="mt-2 space-y-1">
            {#if docsLoading}
              <li class="text-sm">Loading documents...</li>
            {:else if documents.length === 0}
              <li class="text-sm text-base-content/60">No documents uploaded yet.</li>
            {:else}
              {#each documents as d}
                <li class="flex items-center justify-between text-sm bg-base-200 rounded px-2 py-1">
                  <a class="link" href={d.file_path} target="_blank" rel="noopener noreferrer">{d.name}</a>
                  <button class="btn btn-ghost btn-xs" onclick={() => { if (confirm('Delete this document? This action cannot be undone.')) deleteDocument(d.id); }}>Delete</button>
                </li>
              {/each}
            {/if}
          </ul>
        </div>
      </div>
    {:else if isNewProjectHandover()}
      <div class="space-y-3">
        <div class="text-sm">Fill out this form:</div>
        <a
          href="https://docs.google.com/forms/d/e/1FAIpQLSexXko3DG_8d8soPF9GljdfDe3gPmIsUW5mrjzr880xIqu07Q/viewform"
          class="link link-primary"
          target="_blank"
          rel="noopener noreferrer"
        >Open Google Form</a>
      </div>
    {:else if isDealOutcome()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Deal Outcome</div>
          <select class="select select-bordered select-sm w-full max-w-xs" bind:value={dealOutcome} onchange={() => save({ notes: dealOutcome })}>
            <option value="" disabled selected>Select outcome</option>
            <option value="won">won</option>
            <option value="lost">lost</option>
          </select>
        </div>
      </div>
    {:else if isInvoiceSent()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Upload Documents</div>
          <div class="flex items-center gap-2">
            <input type="file" class="file-input file-input-sm file-input-bordered" onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); e.currentTarget.value = ''; }} disabled={uploadInProgress} />
            {#if uploadInProgress}
              <span class="loading loading-spinner loading-sm"></span>
            {/if}
          </div>
          <div class="mt-2 text-xs text-base-content/60">Files are stored under this grant and linked to this task.</div>
          <ul class="mt-2 space-y-1">
            {#if docsLoading}
              <li class="text-sm">Loading documents...</li>
            {:else if documents.length === 0}
              <li class="text-sm text-base-content/60">No documents uploaded yet.</li>
            {:else}
              {#each documents as d}
                <li class="flex items-center justify-between text-sm bg-base-200 rounded px-2 py-1">
                  <a class="link" href={d.file_path} target="_blank" rel="noopener noreferrer">{d.name}</a>
                  <button class="btn btn-ghost btn-xs" onclick={() => { if (confirm('Delete this document? This action cannot be undone.')) deleteDocument(d.id); }}>Delete</button>
                </li>
              {/each}
            {/if}
          </ul>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Link to client invoice</div>
          <input type="url" class="input input-bordered input-sm w-full" placeholder="https://..." bind:value={contractLink} onchange={() => save({ contract_link: contractLink })} />
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea class="textarea textarea-bordered textarea-sm w-full" placeholder="Notes..." bind:value={notes} onchange={() => save({ notes })}></textarea>
        </div>
      </div>
    {:else if isAmlChecksCompleted()}
      <div class="space-y-2">
        <div class="text-sm font-medium">BAMBOO AML STUFF WILL GO HERE</div>
      </div>
    {:else if isProjectResourced()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Upload Documents</div>
          <div class="flex items-center gap-2">
            <input type="file" class="file-input file-input-sm file-input-bordered" onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); e.currentTarget.value = ''; }} disabled={uploadInProgress} />
            {#if uploadInProgress}
              <span class="loading loading-spinner loading-sm"></span>
            {/if}
          </div>
          <div class="mt-2 text-xs text-base-content/60">Files are stored under this grant and linked to this task.</div>
          <ul class="mt-2 space-y-1">
            {#if docsLoading}
              <li class="text-sm">Loading documents...</li>
            {:else if documents.length === 0}
              <li class="text-sm text-base-content/60">No documents uploaded yet.</li>
            {:else}
              {#each documents as d}
                <li class="flex items-center justify-between text-sm bg-base-200 rounded px-2 py-1">
                  <a class="link" href={d.file_path} target="_blank" rel="noopener noreferrer">{d.name}</a>
                  <button class="btn btn-ghost btn-xs" onclick={() => { if (confirm('Delete this document? This action cannot be undone.')) deleteDocument(d.id); }}>Delete</button>
                </li>
              {/each}
            {/if}
          </ul>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Link to subbie invoice</div>
          <input type="url" class="input input-bordered input-sm w-full" placeholder="https://..." bind:value={contractLink} onchange={() => save({ contract_link: contractLink })} />
        </div>
      </div>
    {:else if isProjectSetup()}
      <div class="space-y-2">
        <div class="text-sm font-medium">ASK NICKY WHAT NEEDS TO GO HERE</div>
      </div>
    {:else if isPaymentReceived()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea class="textarea textarea-bordered textarea-sm w-full" placeholder="Notes..." bind:value={notes} onchange={() => save({ notes })}></textarea>
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
    {:else if isTimelineConfirmed()}
      <div class="space-y-2">
        <div class="text-sm font-medium">NICKY TO PROIVIDE TIMELINE TEMPLATES AND WE WILL WORK OUT HOW BEST TO INCORPORATE</div>
      </div>
    {:else if isReviewsConfirmed()}
      <div class="space-y-4">
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Due</span>
            <input type="date" class="input input-sm input-bordered" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
          </label>
        </div>
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Review delivered on:</span>
            <input type="date" class="input input-sm input-bordered" bind:value={reviewDeliveredOn} onchange={() => save({ review_delivered_on: reviewDeliveredOn })} />
          </label>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Upload Documents</div>
          <div class="flex items-center gap-2">
            <input type="file" class="file-input file-input-sm file-input-bordered" onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); e.currentTarget.value = ''; }} disabled={uploadInProgress} />
            {#if uploadInProgress}
              <span class="loading loading-spinner loading-sm"></span>
            {/if}
          </div>
          <div class="mt-2 text-xs text-base-content/60">Files are stored under this grant and linked to this task.</div>
          <ul class="mt-2 space-y-1">
            {#if docsLoading}
              <li class="text-sm">Loading documents...</li>
            {:else if documents.length === 0}
              <li class="text-sm text-base-content/60">No documents uploaded yet.</li>
            {:else}
              {#each documents as d}
                <li class="flex items-center justify-between text-sm bg-base-200 rounded px-2 py-1">
                  <a class="link" href={d.file_path} target="_blank" rel="noopener noreferrer">{d.name}</a>
                  <button class="btn btn-ghost btn-xs" onclick={() => { if (confirm('Delete this document? This action cannot be undone.')) deleteDocument(d.id); }}>Delete</button>
                </li>
              {/each}
            {/if}
          </ul>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Link to subbie invoice</div>
          <input type="url" class="input input-bordered input-sm w-full" placeholder="https://..." bind:value={contractLink} onchange={() => save({ contract_link: contractLink })} />
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea class="textarea textarea-bordered textarea-sm w-full" placeholder="Notes..." bind:value={notes} onchange={() => save({ notes })}></textarea>
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