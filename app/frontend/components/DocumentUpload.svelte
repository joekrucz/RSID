<script>
  // Reusable document upload/list/delete for a specific task
  let { grantApplicationId, sectionTitle, itemTitle } = $props();

  let documents = $state([]);
  let docsLoading = $state(false);
  let uploadInProgress = $state(false);
  let uploadInputRef;

  // Map frontend section names to backend section names (keep in sync)
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

  $effect(() => {
    // Refetch when task identity changes
    if (grantApplicationId && sectionTitle && itemTitle) {
      fetchDocuments();
    } else {
      documents = [];
    }
  });

  async function fetchDocuments() {
    if (!grantApplicationId || !sectionTitle || !itemTitle) return;
    try {
      docsLoading = true;
      const backendSectionTitle = sectionMapping[sectionTitle] || sectionTitle;
      const res = await fetch(`/grant_applications/${grantApplicationId}/grant_documents?section=${encodeURIComponent(backendSectionTitle)}&title=${encodeURIComponent(itemTitle)}`);
      const data = await res.json();
      if (data?.success) {
        documents = data.documents || [];
      } else {
        documents = [];
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
</script>

<div>
  <div class="text-sm font-medium mb-1">Documents</div>
  <div class="flex items-center gap-2">
    <label class="btn btn-sm">
      Upload
      <input type="file" class="hidden" bind:this={uploadInputRef} onchange={(e) => { const f = e.currentTarget.files?.[0]; if (f) uploadDocument(f); }} disabled={uploadInProgress} />
    </label>
    {#if uploadInProgress}
      <span class="loading loading-spinner loading-sm"></span>
    {/if}
  </div>
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


