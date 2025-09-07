<script>
  import { toast } from '../stores/toast.js';
  // Props: sections: Array<{ title: string, items: Array<{ title: string, dueDate?: string }> }>
  let { sections = [] } = $props();

  // Local copy so due dates can be edited without external persistence yet
  let localSections = $state(sections.map(s => ({
    title: s.title,
    items: (s.items || []).map(i => ({ title: i.title, dueDate: i.dueDate || '' }))
  })));

  // Local UI state: expanded map keyed by section index and item index
  let expanded = $state({});
  // Section collapsed state
  let sectionsCollapsed = $state({});

  function toggle(sectionIdx, itemIdx) {
    const key = `${sectionIdx}-${itemIdx}`;
    expanded[key] = !expanded[key];
  }

  function toggleSection(sectionIdx) {
    sectionsCollapsed[sectionIdx] = !sectionsCollapsed[sectionIdx];
  }

  function setDueDate(sectionIdx, itemIdx, value) {
    localSections[sectionIdx].items[itemIdx].dueDate = value;
  }

  // Special per-item state for Project Qualification
  let notesByKey = $state({});
  let filesByKey = $state({});
  let subbieByKey = $state({});
  let contractLinkByKey = $state({});
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

  function isProjectQualification(sectionIdx, itemIdx) {
    return sections[sectionIdx]?.title === 'Client Acquisition/Project Qualification'
      && sections[sectionIdx]?.items?.[itemIdx]?.title === 'Project Qualification';
  }

  function isAgreementSent(sectionIdx, itemIdx) {
    return sections[sectionIdx]?.title === 'Client Acquisition/Project Qualification'
      && sections[sectionIdx]?.items?.[itemIdx]?.title === 'Agreement Sent';
  }

  function handleFileChange(sectionIdx, itemIdx, event) {
    const key = keyFor(sectionIdx, itemIdx);
    const files = Array.from(event.currentTarget.files || []);
    filesByKey[key] = files;
  }

  function handleItemCheck(sectionIdx, itemIdx, event) {
    if (event.currentTarget.checked) {
      toast.success('notification sent to slack');
    }
  }
</script>

<div class="space-y-4">
  {#each sections as section, sIdx}
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
          <li class="px-4 py-3">
            <div class="flex items-start justify-between gap-4">
              <div class="flex items-start">
                <input type="checkbox" class="checkbox checkbox-primary mr-3 mt-1" aria-label={`Mark ${item.title} complete`} onchange={(e) => handleItemCheck(sIdx, iIdx, e)} />
                <div>
                  <div class="font-medium text-gray-900 text-sm">{item.title}</div>
                </div>
              </div>
              <div class="flex items-center gap-2">
                <label class="text-xs text-gray-600" for={`due-${sIdx}-${iIdx}`}>Due</label>
                <input id={`due-${sIdx}-${iIdx}`} type="date" class="input input-sm input-bordered" bind:value={item.dueDate} onchange={(e) => setDueDate(sIdx, iIdx, e.currentTarget.value)} />
                <button class="btn btn-ghost btn-xs" onclick={() => toggle(sIdx, iIdx)} aria-expanded={expanded[`${sIdx}-${iIdx}`] ? 'true' : 'false'} aria-controls={`item-${sIdx}-${iIdx}`}>
                  {expanded[`${sIdx}-${iIdx}`] ? 'Hide' : 'Show'} details
                </button>
              </div>
            </div>
            {#if expanded[`${sIdx}-${iIdx}`]}
              <div id={`item-${sIdx}-${iIdx}`} class="mt-3 rounded-md bg-gray-50 p-3 text-sm text-gray-700 space-y-4">
                {#if isProjectQualification(sIdx, iIdx)}
                  <div>
                    <div class="text-sm font-medium mb-1">Upload supporting documents</div>
                    <input type="file" class="file-input file-input-bordered file-input-sm w-full max-w-md" multiple onchange={(e) => handleFileChange(sIdx, iIdx, e)} />
                    {#if (filesByKey[keyFor(sIdx, iIdx)] || []).length > 0}
                      <ul class="mt-2 list-disc list-inside text-xs text-gray-600">
                        {#each filesByKey[keyFor(sIdx, iIdx)] as f}
                          <li>{f.name} ({Math.ceil(f.size / 1024)} KB)</li>
                        {/each}
                      </ul>
                    {/if}
                  </div>
                  <div>
                    <div class="text-sm font-medium mb-1">Notes</div>
                    <textarea class="textarea textarea-bordered w-full max-w-xl" rows="3" bind:value={notesByKey[keyFor(sIdx, iIdx)]} placeholder="Enter notes for Project Qualification..."></textarea>
                  </div>
                  <div>
                    <div class="text-sm font-medium mb-1">Subbie</div>
                    <div class="flex items-center gap-3 flex-wrap">
                      <select class="select select-bordered select-sm w-full max-w-xs" bind:value={subbieByKey[keyFor(sIdx, iIdx)]} disabled={noSubbieByKey[keyFor(sIdx, iIdx)]}>
                        <option value="" disabled>Select subbie</option>
                        <option value="Leon Lever">Leon Lever</option>
                        <option value="John Smith">John Smith</option>
                      </select>
                      <label class="flex items-center gap-2 text-sm">
                        <input type="checkbox" class="checkbox checkbox-sm" bind:checked={noSubbieByKey[keyFor(sIdx, iIdx)]} />
                        No subbie
                      </label>
                      {#if feeFor(keyFor(sIdx, iIdx)) !== null}
                        <span class="text-sm text-gray-700 whitespace-nowrap">
                          {formatGBP(feeFor(keyFor(sIdx, iIdx)))}
                        </span>
                      {/if}
                    </div>
                  </div>
                {:else if isAgreementSent(sIdx, iIdx)}
                  <div>
                    <div class="text-sm font-medium mb-1">Contract Link</div>
                    <input type="url" class="input input-bordered w-full max-w-xl" placeholder="https://example.com/contract" bind:value={contractLinkByKey[keyFor(sIdx, iIdx)]} />
                  </div>
                {:else}
                  No additional details yet.
                {/if}
              </div>
            {/if}
          </li>
        {/each}
        </ul>
      {/if}
    </div>
  {/each}
</div>
 