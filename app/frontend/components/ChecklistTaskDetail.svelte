<script>
  import { createEventDispatcher } from 'svelte';
  import DocumentUpload from './DocumentUpload.svelte';
  // Master-detail pane for task-specific content
  // Props: grantApplicationId, sectionTitle, itemTitle, persistedItems, qualificationCostPence
  let { grantApplicationId, sectionTitle, itemTitle, persistedItems = [], qualificationCostPence = 0 } = $props();

  // Local fields
  let technicalQualifier = $state('');
  let noTechnicalQualifier = $state(false);
  let contractLink = $state('');
  let checked = $state(false);
  let dueDate = $state('');
  let notes = $state('');
  let documents = $state([]);
  let docsLoading = $state(false);
  let uploadInProgress = $state(false);
  let dealOutcome = $state(''); // 'won' | 'lost'
  let reviewDeliveredOn = $state('');
  let invoiceSentOn = $state('');
  let invoicePaidOn = $state('');
  let resubDue = $state(''); // 'yes' | 'no'
  // Project Resourced subcontractor fields (UI only for now)
  let resourcedSubcontractor = $state('');
  let resourcedSetupFee = $state(''); // pounds string
  let resourcedSuccessFee = $state(''); // pounds string
  let eligibilityCheckCostPence = $state(0);
  let _saveNotesTimer;
  let uploadInputRef;

  const subbieFees = {
    'Leon Lever': 1000,
    'John Smith': 1500
  };

  function formatGBP(pence) {
    return `£${Number(pence).toLocaleString('en-GB')}`;
  }

  function formatPoundsFromPence(pence) {
    const pounds = Math.round(Number(pence || 0)) / 100;
    return Number.isFinite(pounds) ? pounds : 0;
  }

  function toPenceFromPounds(pounds) {
    const n = Number(pounds);
    if (!Number.isFinite(n)) return 0;
    return Math.round(n * 100);
  }

  function feeFor(name) {
    if (noTechnicalQualifier) return 0;
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
    technicalQualifier = '';
    noTechnicalQualifier = false;
    contractLink = '';
    checked = false;
    dueDate = '';
    notes = '';
    documents = [];

    const backendSectionTitle = sectionMapping[sectionTitle] || sectionTitle;
    const found = (persistedItems || []).find(pi => pi.section === backendSectionTitle && pi.title === itemTitle);
    if (found) {
      technicalQualifier = found.technical_qualifier || '';
      noTechnicalQualifier = !!found.no_technical_qualifier;
      contractLink = found.contract_link || '';
      checked = !!found.checked;
      dueDate = found.due_date || '';
      notes = found.notes || '';
      reviewDeliveredOn = found.review_delivered_on || '';
      invoiceSentOn = found.invoice_sent_on || '';
      invoicePaidOn = found.invoice_paid_on || '';
      resubDue = (found.resub_due || '').toString().trim().toLowerCase();
      eligibilityCheckCostPence = Number(found.eligibility_check_cost_pence || 0);
      const outcome = (found.deal_outcome || '').toString().trim().toLowerCase();
      dealOutcome = (outcome === 'won' || outcome === 'lost') ? outcome : '';
      // completed_at for status display
      completedAt = found.completed_at || '';
    }
    // Fetch documents for this task
    if (grantApplicationId && sectionTitle && itemTitle) {
      fetchDocuments();
    }
    // Also hydrate resourced subcontractor if present
    try {
      if (sectionTitle === 'KO Prep' && itemTitle === 'Project Resourced') {
        resourcedSubcontractor = found?.resourced_subcontractor || '';
      } else if (sectionTitle === 'KO Prep' && itemTitle === 'Project Set Up - Slack Channel, Delivery Folders, Etc.') {
        // Read value from the Project Resourced item
        const resItem = (persistedItems || []).find(pi => pi.section === 'Preparing for Kick Off/AML/Resourcing' && pi.title === 'Project Resourced');
        resourcedSubcontractor = resItem?.resourced_subcontractor || '';
      }
    } catch (_) {}
  });

  const dispatch = createEventDispatcher();

  async function save(attrs) {
    if (!grantApplicationId || !sectionTitle || !itemTitle) return;
    try {
      if (Object.prototype.hasOwnProperty.call(attrs, 'checked')) {
        // Optimistic UI update
        dispatch('change', { field: 'checked', value: attrs.checked, sectionTitle, itemTitle });
        // Update local status instantly
        if (attrs.checked === true) {
          completedAt = new Date().toISOString();
        } else if (attrs.checked === false) {
          completedAt = '';
        }
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
  let completedAt = $state('');
  function formatDateTime(ts) {
    if (!ts) return '';
    const d = new Date(ts);
    if (isNaN(d.getTime())) return '';
    return d.toLocaleString('en-GB', { year: 'numeric', month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' });
  }

  // All tasks show a due date control in the header

  function isOverdue() {
    if (!dueDate) return false;
    try {
      const d = new Date(`${dueDate}T00:00:00`);
      if (isNaN(d.getTime())) return false;
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      return d < today;
    } catch (_) {
      return false;
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
  function isEligibilityChecksCompleted() {
    return sectionTitle === 'Kicked Off' && itemTitle === 'Eligibility Checks Completed';
  }

  function isSuccessFeeInvoiced() {
    return sectionTitle === 'Success Fee Invoiced' && itemTitle === 'Completed';
  }
  function isResubDue() {
    return sectionTitle === 'Resub Due' && itemTitle === 'Completed';
  }
</script>

<div class="bg-base-100 rounded-lg border border-base-300 shadow p-4 min-h-[12rem]">
  {#if !sectionTitle || !itemTitle}
    <div class="text-base-content/70">Select a checklist item to view details.</div>
  {:else}
    <div class="mb-4 flex items-center justify-between gap-3">
      <h3 class="text-2xl font-semibold text-base-content">{itemTitle}</h3>
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Due</span>
          <input type="date" class="input input-xs input-bordered {isOverdue() ? 'input-error text-error' : ''}" bind:value={dueDate} onchange={() => save({ due_date: dueDate })} />
          </label>
        <div class="text-sm whitespace-nowrap {checked ? 'text-success' : 'text-base-content/70'}">
        {#if checked}
          {#if completedAt}
            Completed on {formatDateTime(completedAt)}
          {:else}
            Completed
          {/if}
        {:else}
          Not completed
        {/if}
        </div>
        
      </div>
    </div>
    {#if isProjectQualification()}
      <div class="space-y-4">
        
        <div>
          <div class="text-sm font-medium mb-1">Technical Qualifier</div>
          <div class="flex items-center gap-3 flex-wrap">
            <select class="select select-bordered select-sm w-full max-w-xs" bind:value={technicalQualifier} disabled={noTechnicalQualifier} onchange={() => {
              save({ technical_qualifier: technicalQualifier });
              if (technicalQualifier && !noTechnicalQualifier) {
                const feePounds = feeFor(technicalQualifier) || 0;
                const feePence = toPenceFromPounds(feePounds);
                qualificationCostPence = feePence;
                // Persist to grant application
                fetch(`/grant_applications/${grantApplicationId}`, {
                  method: 'PATCH',
                  headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
                  },
                  credentials: 'same-origin',
                  body: JSON.stringify({ grant_application: { qualification_cost_pence: feePence } })
                }).catch(err => console.error('Failed to save qualification cost', err));
              }
            }}>
              <option value="" disabled>Select technical qualifier</option>
              <option value="Leon Lever">Leon Lever</option>
              <option value="John Smith">John Smith</option>
            </select>
            <label class="flex items-center gap-2 text-sm">
              <input type="checkbox" class="checkbox checkbox-sm" bind:checked={noTechnicalQualifier} onchange={() => save({ no_technical_qualifier: noTechnicalQualifier })} />
              No technical qualifier
            </label>
          </div>
          
        </div>
        <div>
          <div class="text-sm font-medium mb-1">Qualification cost</div>
          <div class="flex items-center gap-2">
            <span class="opacity-70">£</span>
            <input type="number" min="0" step="0.01" class="input input-sm input-bordered w-40" value={formatPoundsFromPence(qualificationCostPence)} oninput={(e) => {
              const p = toPenceFromPounds(e.currentTarget.value);
              qualificationCostPence = p;
              // Persist to grant application
              fetch(`/grant_applications/${grantApplicationId}`, {
                method: 'PATCH',
                headers: {
                  'Content-Type': 'application/json',
                  'X-CSRF-Token': document.querySelector('meta[name=\"csrf-token\"]').getAttribute('content')
                },
                credentials: 'same-origin',
                body: JSON.stringify({ grant_application: { qualification_cost_pence: p } })
              }).catch(err => console.error('Failed to save qualification cost', err));
            }} />
          </div>
        </div>
        <DocumentUpload {grantApplicationId} {sectionTitle} itemTitle={itemTitle} />
        
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
        
        <div>
          <div class="text-sm font-medium mb-1">Client Contract Link</div>
          <input type="url" class="input input-bordered input-sm w-full" placeholder="https://..." bind:value={contractLink} onchange={() => save({ contract_link: contractLink })} />
        </div>
        <DocumentUpload {grantApplicationId} {sectionTitle} itemTitle={itemTitle} />
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
        
        <DocumentUpload {grantApplicationId} {sectionTitle} itemTitle={itemTitle} />
        <div>
          <div class="text-sm font-medium mb-1">Link to client invoice</div>
          <input type="url" class="input input-bordered input-sm w-full" placeholder="https://..." bind:value={contractLink} onchange={() => save({ contract_link: contractLink })} />
        </div>
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Invoice sent on</span>
            <input type="date" class="input input-sm input-bordered" value={invoiceSentOn} onchange={(e) => { invoiceSentOn = e.currentTarget.value; save({ invoice_sent_on: invoiceSentOn }); }} />
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
          <div class="text-sm font-medium mb-1">Subcontractor</div>
          <div class="flex items-center gap-3 flex-wrap">
            {#if isProjectResourced()}
              <select class="select select-bordered select-sm w-full max-w-xs" bind:value={resourcedSubcontractor} onchange={() => save({ resourced_subcontractor: resourcedSubcontractor })}>
                <option value="" disabled>Select subcontractor</option>
              <option value="Leon Lever">Leon Lever</option>
              <option value="John Smith">John Smith</option>
            </select>
            {:else}
              <div class="text-sm opacity-80">{resourcedSubcontractor || '—'}</div>
            {/if}
          </div>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <div class="text-sm font-medium mb-1">Subcontractor setup fee</div>
            <label class="input input-bordered input-sm flex items-center gap-2 w-full max-w-xs">
              <span class="opacity-70">£</span>
              <input class="grow min-w-0" type="number" min="0" step="0.01" placeholder="0.00" bind:value={resourcedSetupFee} />
            </label>
          </div>
          <div>
            <div class="text-sm font-medium mb-1">Subcontractor success fee</div>
            <label class="input input-bordered input-sm flex items-center gap-2 w-full max-w-xs">
              <span class="opacity-70">£</span>
              <input class="grow min-w-0" type="number" min="0" step="0.01" placeholder="0.00" bind:value={resourcedSuccessFee} />
            </label>
          </div>
        </div>
        <DocumentUpload {grantApplicationId} {sectionTitle} itemTitle={itemTitle} />
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
        <div>
          <div class="text-sm font-medium mb-1">Subcontractor</div>
          <div class="text-sm opacity-80">{resourcedSubcontractor || '—'}</div>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <div class="text-sm font-medium mb-1">Delivery folder link</div>
            <input type="url" class="input input-bordered input-sm w-full" placeholder="https://..." value={contractLink} oninput={(e) => { contractLink = e.currentTarget.value; save({ delivery_folder_link: contractLink }); }} />
          </div>
          <div>
            <div class="text-sm font-medium mb-1">Slack channel name</div>
            <input type="text" class="input input-bordered input-sm w-full" placeholder="#channel-name" value={notes} oninput={(e) => { notes = e.currentTarget.value; save({ slack_channel_name: notes }); }} />
          </div>
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
    {:else if isPaymentReceived()}
      <div class="space-y-4">
        <div class="flex items-center gap-4">
          <label class="flex items-center gap-2 text-sm">
            <span>Invoice paid on</span>
            <input type="date" class="input input-sm input-bordered" value={invoicePaidOn} onchange={(e) => { invoicePaidOn = e.currentTarget.value; save({ invoice_paid_on: invoicePaidOn }); }} />
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
            <span>Review delivered on:</span>
            <input type="date" class="input input-sm input-bordered" bind:value={reviewDeliveredOn} onchange={() => save({ review_delivered_on: reviewDeliveredOn })} />
          </label>
        </div>
        <DocumentUpload {grantApplicationId} {sectionTitle} itemTitle={itemTitle} />
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
    {:else if isEligibilityChecksCompleted()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Eligibility Check Cost</div>
          <label class="input input-bordered input-sm flex items-center gap-2 w-full max-w-xs">
            <span class="opacity-70">£</span>
            <input class="grow min-w-0" type="number" min="0" step="0.01" placeholder="0.00" value={formatPoundsFromPence(eligibilityCheckCostPence)} oninput={(e) => {
              const p = toPenceFromPounds(e.currentTarget.value);
              eligibilityCheckCostPence = p;
              save({ eligibility_check_cost_pence: p });
            }} />
          </label>
        </div>
      </div>
    {:else if isSuccessFeeInvoiced()}
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
    {:else if isResubDue()}
      <div class="space-y-4">
        <div>
          <div class="text-sm font-medium mb-1">Resub due</div>
          <select class="select select-bordered select-sm w-full max-w-xs" bind:value={resubDue} onchange={() => save({ resub_due: resubDue })}>
            <option value="" disabled>Select</option>
            <option value="yes">yes</option>
            <option value="no">no</option>
          </select>
        </div>
      </div>
    {:else}
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
    {/if}
  {/if}
</div>