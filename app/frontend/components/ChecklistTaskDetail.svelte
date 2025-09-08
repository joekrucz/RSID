<script>
  import { createEventDispatcher } from 'svelte';
  // Master-detail pane for task-specific content
  // Props: grantApplicationId, sectionTitle, itemTitle, persistedItems
  let { grantApplicationId, sectionTitle, itemTitle, persistedItems = [] } = $props();

  // Local fields
  let notes = $state('');
  let subbie = $state('');
  let noSubbie = $state(false);
  let contractLink = $state('');
  let files = $state([]);
  let documents = $state([]);
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
    notes = '';
    subbie = '';
    noSubbie = false;
    contractLink = '';
    checked = false;
    dueDate = '';

    const found = (persistedItems || []).find(pi => pi.section === sectionTitle && pi.title === itemTitle);
    if (found) {
      notes = found.notes || '';
      subbie = found.subbie || '';
      noSubbie = !!found.no_subbie;
      contractLink = found.contract_link || '';
      checked = !!found.checked;
      dueDate = found.due_date || '';
    }
    // Load documents for current selection
    loadDocuments();
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

  function handleFileChange(event) {
    files = Array.from(event.currentTarget.files || []);
  }

  async function loadDocuments() {
    documents = [];
    if (!grantApplicationId || !sectionTitle || !itemTitle) return;
    try {
      const res = await fetch(`/grant_applications/${grantApplicationId}/grant_checklist_items/list_documents?section=${encodeURIComponent(sectionTitle)}&title=${encodeURIComponent(itemTitle)}`);
      const data = await res.json();
      if (data?.success) {
        documents = data.documents || [];
      }
    } catch (e) {
      console.error('Failed to load documents', e);
    }
  }

  async function uploadSelectedFiles() {
    if (!grantApplicationId || !sectionTitle || !itemTitle) return;
    for (const f of (files || [])) {
      const form = new FormData();
      form.append('section', sectionTitle);
      form.append('title', itemTitle);
      form.append('file', f);
      try {
        await fetch(`/grant_applications/${grantApplicationId}/grant_checklist_items/upload_document`, {
          method: 'POST',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          },
          body: form
        });
      } catch (e) {
        console.error('Failed to upload file', e);
      }
    }
    files = [];
    await loadDocuments();
  }

  function isProjectQualification() {
    // Show the documents UI whenever the selected item is "Project Qualification",
    // regardless of the exact section title string.
    return (itemTitle || '').trim() === 'Project Qualification';
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
    {#if isProjectQualification()}
    <div class="space-y-4">
      <div class="flex items-center gap-4">
        <label class="flex items-center gap-2 text-sm">
          <span>Due</span>
          <input type="date" class="input input-sm input-bordered" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
        </label>
      </div>
      <div>
        <div class="text-sm font-medium mb-1">Documents</div>
        <input type="file" class="file-input file-input-bordered file-input-sm w-full max-w-md" multiple onchange={handleFileChange} />
        <div class="mt-2 flex items-center gap-2">
          <button class="btn btn-sm btn-primary" disabled={(files || []).length === 0} onclick={uploadSelectedFiles}>Upload</button>
          {#if (files || []).length > 0}
            <span class="text-xs opacity-60">{(files || []).length} file(s) selected</span>
          {/if}
        </div>
        {#if (documents || []).length > 0}
          <ul class="mt-3 space-y-1">
            {#each documents as d}
              <li>
                <a class="link link-primary text-sm" href={`/grant_applications/${grantApplicationId}/grant_checklist_items/download_document?id=${encodeURIComponent(d.id)}`}>
                  {d.name}
                </a>
              </li>
            {/each}
          </ul>
        {:else}
          <div class="text-xs opacity-60 mt-2">No documents uploaded yet.</div>
        {/if}
      </div>
      <div>
        <div class="text-sm font-medium mb-1">Notes</div>
        <textarea class="textarea textarea-bordered w-full" rows="4" bind:value={notes} onchange={() => save({ notes })}></textarea>
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
          {#if feeFor(subbie) !== null}
            <span class="text-sm text-base-content whitespace-nowrap">{formatGBP(feeFor(subbie))}</span>
          {/if}
        </div>
      </div>
    </div>
    {:else if isAgreementSent()}
    <div>
      <div class="flex items-center gap-4 mb-4">
        <label class="flex items-center gap-2 text-sm">
          <span>Due</span>
          <input type="date" class="input input-sm input-bordered" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
        </label>
      </div>
      <div class="text-sm font-medium mb-1">Contract Link</div>
      <input type="url" class="input input-bordered w-full" placeholder="https://example.com/contract" bind:value={contractLink} onchange={() => save({ contract_link: contractLink })} />
      <div class="mt-4">
        <div class="text-sm font-medium mb-1">Notes</div>
        <textarea class="textarea textarea-bordered w-full" rows="4" bind:value={notes} onchange={() => save({ notes })}></textarea>
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
        <textarea class="textarea textarea-bordered w-full" rows="4" bind:value={notes} onchange={() => save({ notes })}></textarea>
      </div>
    </div>
    {/if}
  {/if}
</div>


