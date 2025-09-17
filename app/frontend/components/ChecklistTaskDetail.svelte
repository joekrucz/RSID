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
  let _saveNotesTimer;
  let uploadInputRef;

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

  function scheduleSaveNotes() {
    try { if (_saveNotesTimer) clearTimeout(_saveNotesTimer); } catch (_) {}
    _saveNotesTimer = setTimeout(() => { save({ notes }); }, 400);
  }

  // Map frontend section names to backend section names (same as Checklist.svelte)
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

    const backendSectionTitle = sectionMapping[sectionTitle] || sectionTitle;
    const found = (persistedItems || []).find(pi => pi.section === backendSectionTitle && pi.title === itemTitle);
    if (found) {
      subbie = found.subbie || '';
      noSubbie = !!found.no_subbie;
      contractLink = found.contract_link || '';
      checked = !!found.checked;
      dueDate = found.due_date || '';
      notes = found.notes || '';
      reviewDeliveredOn = found.review_delivered_on || '';
      const outcome = (found.deal_outcome || '').toString().trim().toLowerCase();
      dealOutcome = (outcome === 'won' || outcome === 'lost') ? outcome : '';
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
      const backendSectionTitle = sectionMapping[sectionTitle] || sectionTitle;
      await fetch(`/grant_applications/${grantApplicationId}/grant_checklist_items/upsert`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        credentials: 'same-origin',
        body: JSON.stringify({
          section: backendSectionTitle,
          title: itemTitle,
          ...attrs
        })
      });
      // Notify parent so it can optimistically update persistedItems (notes, due_date, etc.)
      for (const [k, v] of Object.entries(attrs)) {
        dispatch('change', { field: k, value: v, sectionTitle, itemTitle });
      }
    } catch (e) {
      console.error('Failed to save task detail', e);
    }
  }

  async function fetchDocuments() {
    if (!grantApplicationId || !sectionTitle || !itemTitle) return;
    try {
      docsLoading = true;
      const backendSectionTitle = sectionMapping[sectionTitle] || sectionTitle;
      const res = await fetch(`/grant_applications/${grantApplicationId}/grant_documents?section=${encodeURIComponent(backendSectionTitle)}&title=${encodeURIComponent(itemTitle)}`);
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
      const backendSectionTitle = sectionMapping[sectionTitle] || sectionTitle;
      form.append('section', backendSectionTitle);
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
      try { if (uploadInputRef) uploadInputRef.value = ''; } catch (_) {}
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

  function isSuccessFeeInvoiced() {
    return sectionTitle === 'Success Fee Invoiced' && itemTitle === 'Completed';
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
            <label class="btn btn-sm">
              Choose file
              <input type="file" class="hidden" bind:this={uploadInputRef} onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); }} disabled={uploadInProgress} />
            </label>
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
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes for Project Qualification..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>

      </div>
    {:else if isAgreementSent()}
      <div class="space-y-4">
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Due</span>
            <input type="date" class="input input-sm input-bordered" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
          </label>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Client Contract Link</div>
          <input type="url" class="input input-bordered input-sm w-full" placeholder="https://..." bind:value={contractLink} onchange={() => save({ contract_link: contractLink })} />
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Upload Documents</div>
          <div class="flex items-center gap-2">
            <label class="btn btn-sm">
              Choose file
              <input type="file" class="hidden" bind:this={uploadInputRef} onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); }} disabled={uploadInProgress} />
            </label>
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
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
      </div>
    {:else if isNewProjectHandover()}
      <div class="space-y-3">
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Due</span>
            <input type="date" class="input input-sm input-bordered" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
          </label>
        </div>
        <div class="text-sm">Fill out this form:</div>
        <a
          href="https://docs.google.com/forms/d/e/1FAIpQLSexXko3DG_8d8soPF9GljdfDe3gPmIsUW5mrjzr880xIqu07Q/viewform"
          class="link link-primary"
          target="_blank"
          rel="noopener noreferrer"
        >Open Google Form</a>
        <div>
          <div class="text-sm font-medium mb-1 mt-2">Notes</div>
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
      </div>
    {:else if isDealOutcome()}
      <div class="space-y-4">
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Due</span>
            <input type="date" class="input input-sm input-bordered" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
          </label>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Deal Outcome</div>
          <select class="select select-bordered select-sm w-full max-w-xs" bind:value={dealOutcome} onchange={() => save({ deal_outcome: dealOutcome })}>
            <option value="" disabled>Select outcome</option>
            <option value="won">won</option>
            <option value="lost">lost</option>
          </select>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
      </div>
    {:else if isInvoiceSent()}
      <div class="space-y-4">
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Due</span>
            <input type="date" class="input input-sm input-bordered" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
          </label>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Upload Documents</div>
          <div class="flex items-center gap-2">
            <label class="btn btn-sm">
              Choose file
              <input type="file" class="hidden" bind:this={uploadInputRef} onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); }} disabled={uploadInProgress} />
            </label>
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
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
      </div>
    {:else if isAmlChecksCompleted()}
      <div class="space-y-4">
        <div class="text-sm font-medium">BAMBOO AML STUFF WILL GO HERE</div>
        <div>
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
      </div>
    {:else if isProjectResourced()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Upload Documents</div>
          <div class="flex items-center gap-2">
            <label class="btn btn-sm">
              Choose file
              <input type="file" class="hidden" bind:this={uploadInputRef} onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); }} disabled={uploadInProgress} />
            </label>
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
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
      </div>
    {:else if isProjectSetup()}
      <div class="space-y-4">
        <div class="text-sm font-medium">ASK NICKY WHAT NEEDS TO GO HERE</div>
        <div>
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
      </div>
    {:else if isPaymentReceived()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
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
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
      </div>
    {:else if isTimelineConfirmed()}
      <div class="space-y-4">
        <div class="text-sm font-medium">NICKY TO PROIVIDE TIMELINE TEMPLATES AND WE WILL WORK OUT HOW BEST TO INCORPORATE</div>
        <div>
          <div class="text-sm font-medium mb-1">Notes</div>
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
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
            <label class="btn btn-sm">
              Choose file
              <input type="file" class="hidden" bind:this={uploadInputRef} onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); }} disabled={uploadInProgress} />
            </label>
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
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
        
      </div>
    {:else if isSuccessFeeInvoiced()}
      <div class="space-y-4">
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Due</span>
            <input type="date" class="input input-sm input-bordered" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
          </label>
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Upload Documents</div>
          <div class="flex items-center gap-2">
            <label class="btn btn-sm">
              Choose file
              <input type="file" class="hidden" bind:this={uploadInputRef} onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); }} disabled={uploadInProgress} />
            </label>
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
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
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
          <textarea
            class="textarea textarea-bordered textarea-sm w-full"
            placeholder="Notes..."
            bind:value={notes}
            oninput={scheduleSaveNotes}
            onblur={() => save({ notes })}
          ></textarea>
        </div>
      </div>
    {/if}
  {/if}
</div>