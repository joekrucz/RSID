<script>
  import { toast } from '../stores/toast.js';
  import { createEventDispatcher } from 'svelte';
  // Props: sections: Array<{ title: string, items: Array<{ title: string, dueDate?: string }> }>
  // visibleIndices: number[] of sections to show; if empty, show all
  // persistedItems: Array<{ section, title, checked, due_date, notes, subbie, no_subbie, contract_link }>
  // selectedSectionTitle/itemTitle: current selection to highlight row
  let { sections = [], visibleIndices = [], persistedItems = [], selectedSectionTitle = '', selectedItemTitle = '' } = $props();

  // Local copy so due dates can be edited without external persistence yet
  let localSections = $state(sections.map(s => ({
    title: s.title,
    items: (s.items || []).map(i => ({ title: i.title, dueDate: i.dueDate || '' }))
  })));

  // Section collapsed state
  let sectionsCollapsed = $state({});

  const dispatch = createEventDispatcher();

  function selectItem(sectionIdx, itemIdx) {
    dispatch('select', { sectionIdx, itemIdx, sectionTitle: sections[sectionIdx]?.title, itemTitle: localSections[sectionIdx]?.items?.[itemIdx]?.title });
  }

  function toggleSection(sectionIdx) {
    sectionsCollapsed[sectionIdx] = !sectionsCollapsed[sectionIdx];
  }

  async function setDueDate(sectionIdx, itemIdx, value) {
    localSections[sectionIdx].items[itemIdx].dueDate = value;
    try {
      const frontendSectionTitle = sections[sectionIdx]?.title;
      const backendSectionTitle = sectionMapping[frontendSectionTitle] || frontendSectionTitle;
      const itemTitle = localSections[sectionIdx]?.items?.[itemIdx]?.title;
      const grantApplicationId = window?.location?.pathname?.match(/grant_applications\/(\d+)/)?.[1];
      if (grantApplicationId && backendSectionTitle && itemTitle) {
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
            due_date: value
          })
        });
      }
    } catch (e) {
      console.error('Failed to persist due date', e);
    }
  }

  // Special per-item state
  let subbieByKey = $state({});
  let contractLinkByKey = $state({});
  // Track checked state per item key `${sectionIdx}-${itemIdx}`
  let checkedByKey = $state({});
  let noSubbieByKey = $state({});
  const subbieFees = {
    'Leon Lever': 1000,
    'John Smith': 1500
  };

  function formatGBP(pence) {
    // amounts are in whole GBP; simple formatter
    return `£${Number(pence).toLocaleString('en-GB')}`;
  }

  function feeFor(key) {
    if (noSubbieByKey[key]) return 0;
    const name = subbieByKey[key];
    if (!name) return null;
    return subbieFees[name] ?? 0;
  }

  function keyFor(sectionIdx, itemIdx) {
    return `${sectionIdx}-${itemIdx}`;
  }

  // Map frontend section names to backend section names
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

  // Hydrate from persistedItems on mount/prop change
  $effect(() => {
    const byKey = new Map();
    (persistedItems || []).forEach((pi) => {
      if (pi?.section && pi?.title) {
        byKey.set(`${pi.section}|${pi.title}`, pi);
      }
    });
    sections.forEach((section, sIdx) => {
      (section.items || []).forEach((item, iIdx) => {
        const backendSectionName = sectionMapping[section.title] || section.title;
        const found = byKey.get(`${backendSectionName}|${item.title}`);
        if (found) {
          const k = keyFor(sIdx, iIdx);
          // Sync due date into localSections model
          if (localSections?.[sIdx]?.items?.[iIdx]) {
            localSections[sIdx].items[iIdx].dueDate = found.due_date || localSections[sIdx].items[iIdx].dueDate;
          }
          // Always update checked state from server data
          checkedByKey[k] = !!found.checked;
          // Optional fields
          subbieByKey[k] = found.subbie || subbieByKey[k];
          noSubbieByKey[k] = !!found.no_subbie;
          contractLinkByKey[k] = found.contract_link || contractLinkByKey[k];
        }
      });
    });
    // Emit progress after hydration
    emitProgress();
  });

  function isProjectQualification(sectionIdx, itemIdx) {
    return sections[sectionIdx]?.title === 'Client Acquisition/Project Qualification'
      && sections[sectionIdx]?.items?.[itemIdx]?.title === 'Project Qualification';
  }

  function isAgreementSent(sectionIdx, itemIdx) {
    return sections[sectionIdx]?.title === 'Client Acquisition/Project Qualification'
      && sections[sectionIdx]?.items?.[itemIdx]?.title === 'Agreement Sent';
  }


  function emitProgress() {
    // Compute completion using local checked state where available,
    // otherwise fall back to persisted items from server
    const persistedMap = new Map();
    (persistedItems || []).forEach((pi) => {
      if (pi?.section && pi?.title) persistedMap.set(`${pi.section}|${pi.title}`, !!pi.checked);
    });
    const sectionComplete = sections.map((section, sIdx) => {
      return (section.items || []).every((item, iIdx) => {
        const local = checkedByKey[keyFor(sIdx, iIdx)];
        if (typeof local === 'boolean') return local;
        const backendSectionName = sectionMapping[section.title] || section.title;
        const sKey = `${backendSectionName}|${item.title}`;
        return persistedMap.get(sKey) === true;
      });
    });
    dispatch('progress', { sectionComplete });
  }

  async function persistChecked(sectionTitle, itemTitle, value) {
    try {
      const grantApplicationId = window?.location?.pathname?.match(/grant_applications\/(\d+)/)?.[1];
      if (!grantApplicationId) return;
      
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
      if (!csrfToken) {
        toast.error('Security token missing. Please refresh the page.');
        return;
      }
      
      const res = await fetch(`/grant_applications/${grantApplicationId}/grant_checklist_items/upsert`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        credentials: 'same-origin',
        body: JSON.stringify({ section: sectionTitle, title: itemTitle, checked: !!value })
      });
      
      if (!res.ok) {
        if (res.status === 302) {
          toast.error('Session expired. Please log in again.');
          window.location.href = '/login';
          return;
        }
        throw new Error(`Request failed with status ${res.status}`);
      }
      
      const data = await res.json().catch(() => ({}));
      if (data?.stage) dispatch('stage', { stage: data.stage });
      if (data?.conflict_warning) {
        dispatch('conflict-warning', { 
          message: data.conflict_warning,
          details: data.conflict_details || []
        });
      }
    } catch (e) {
      console.error('Failed to persist checked', e);
      toast.error('Failed to save change');
    }
  }

  function toggleChecked(sectionIdx, itemIdx, value) {
    const frontendSectionTitle = sections[sectionIdx]?.title;
    const backendSectionTitle = sectionMapping[frontendSectionTitle] || frontendSectionTitle;
    const itemTitle = localSections[sectionIdx]?.items?.[itemIdx]?.title;
    const k = keyFor(sectionIdx, itemIdx);
    checkedByKey[k] = !!value;
    persistChecked(backendSectionTitle, itemTitle, !!value);
    emitProgress();
    // Progress is derived from persisted items; we optimistically emit, but
    // stage update will come from server response and be dispatched separately.
  }

  // Expose method for parent to set checked by title
  export function setCheckedByTitle(sectionTitle, itemTitle, value) {
    const sIdx = sections.findIndex((s) => s.title === sectionTitle);
    if (sIdx === -1) return;
    const iIdx = (sections[sIdx]?.items || []).findIndex((i) => i.title === itemTitle);
    if (iIdx === -1) return;
    toggleChecked(sIdx, iIdx, value);
  }
</script>

<div class="space-y-4">
  {#each sections as section, sIdx}
    {#if visibleIndices.length === 0 || visibleIndices.includes(sIdx)}
    <div class="bg-white rounded-lg shadow-sm border">
      <div class="px-4 py-3 border-b">
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-gray-900">{section.title}</h3>
          <button 
            class="btn btn-sm btn-ghost"
            onclick={() => toggleSection(sIdx)}
            aria-label={sectionsCollapsed[sIdx] ? 'Expand section' : 'Collapse section'}
          >
            <svg 
              class="w-4 h-4 transition-transform duration-200 {sectionsCollapsed[sIdx] ? 'rotate-180' : ''}" 
              fill="none" 
              stroke="currentColor" 
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
            </svg>
          </button>
        </div>
      </div>
      {#if !sectionsCollapsed[sIdx]}
        <ul class="divide-y">
        {#each localSections[sIdx].items as item, iIdx}
          {@const isSelected = sections[sIdx]?.title === selectedSectionTitle && localSections[sIdx]?.items?.[iIdx]?.title === selectedItemTitle}
          {@const k = keyFor(sIdx, iIdx)}
          <button class={`w-full text-left px-4 py-3 cursor-pointer rounded ${isSelected ? 'bg-base-200 border border-base-300' : ''}`} onclick={() => selectItem(sIdx, iIdx)}>
            <div class="flex items-start justify-between gap-4">
              <div class="flex items-start gap-2">
                <input type="checkbox" class="checkbox checkbox-sm checkbox-primary mt-0.5"
                  checked={!!checkedByKey[k]}
                  onchange={(e) => {
                    e.stopPropagation();
                    toggleChecked(sIdx, iIdx, e.currentTarget.checked);
                  }}
                  aria-label={`Mark ${item.title} as ${checkedByKey[k] ? 'incomplete' : 'complete'}`} />
                <div class="font-medium text-gray-900 text-sm">{item.title}</div>
              </div>
              
            </div>
          </button>
        {/each}
        </ul>
      {/if}
    </div>
    {/if}
  {/each}
</div>
 
 