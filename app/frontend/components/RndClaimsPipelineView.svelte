<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../stores/toast.js';
  
  let { pipeline_data } = $props();
  
  let draggedClaim = $state(null);
  let draggedFromStage = $state(null);
  let dragOverStage = $state(null);
  let hasDragged = $state(false);
  
  function formatStageName(stage) {
    return stage.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
  }
  
  function isPreDeliveryStage(stage) {
    return stage === 'upcoming' || stage === 'readying_for_delivery';
  }

  function formatDate(value) {
    if (!value) return '';
    try {
      const d = new Date(value);
      return d.toLocaleDateString('en-GB', { day: '2-digit', month: '2-digit', year: 'numeric' });
    } catch (_) {
      return value;
    }
  }

  function formatCurrencyGBP(amount) {
    if (!amount) return '£0';
    try {
      return new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP' }).format(amount);
    } catch (_) {
      return `£${amount}`;
    }
  }
  
  // delete action removed from card footer
  
  // Dual-scrollbar (top and bottom) syncing
  let topScrollEl;
  let bottomScrollEl;
  let topSpacerEl;
  let customTrackEl;
  let isDraggingThumb = false;
  let dragStartX = 0;
  let dragStartScrollLeft = 0;
  let customTrackWidth = 0;
  let customThumbWidth = $state(0);
  let customThumbLeft = $state(0);
  let customScrollPercent = $state(0);
  let contentScrollWidth = 0;
  const allStages = [
    'upcoming',
    'readying_for_delivery',
    'in_progress',
    'finalised',
    'filed_awaiting_hmrc',
    'claim_processed',
    'client_invoiced',
    'paid'
  ];
  function syncFromTop() {
    if (bottomScrollEl && topScrollEl) bottomScrollEl.scrollLeft = topScrollEl.scrollLeft;
    updateCustomScrollbar();
  }
  function syncFromBottom() {
    if (bottomScrollEl && topScrollEl) topScrollEl.scrollLeft = bottomScrollEl.scrollLeft;
    updateCustomScrollbar();
  }
  $effect(() => {
    // Prefer actual content width when available
    if (bottomScrollEl && bottomScrollEl.scrollWidth) {
      contentScrollWidth = bottomScrollEl.scrollWidth;
      if (topSpacerEl) topSpacerEl.style.width = `${contentScrollWidth}px`;
      updateCustomScrollbar();
      return;
    }
    // Fallback: approximate based on visible stage columns
    try {
      const cols = allStages.reduce((acc, s) => acc + (pipeline_data && pipeline_data[s] ? 1 : 0), 0);
      const colWidth = 320; // ~w-80
      const gap = 24; // space-x-6 ~= 1.5rem
      contentScrollWidth = Math.max(colWidth, cols * colWidth + Math.max(0, cols - 1) * gap);
      if (topSpacerEl) topSpacerEl.style.width = `${contentScrollWidth}px`;
    } catch (_) {}
    updateCustomScrollbar();
  });

  function updateCustomScrollbar() {
    if (!bottomScrollEl || !customTrackEl) return;
    const contentWidth = bottomScrollEl.scrollWidth;
    const viewportWidth = bottomScrollEl.clientWidth;
    customTrackWidth = customTrackEl.clientWidth;
    if (contentWidth <= 0 || viewportWidth <= 0) {
      customThumbWidth = 0;
      customThumbLeft = 0;
      customScrollPercent = 0;
      return;
    }
    const ratio = viewportWidth / contentWidth;
    customThumbWidth = Math.max(30, customTrackWidth * ratio);
    const maxThumbLeft = Math.max(0, customTrackWidth - customThumbWidth);
    const scrollRatio = bottomScrollEl.scrollLeft / (contentWidth - viewportWidth || 1);
    customThumbLeft = Math.min(maxThumbLeft, Math.max(0, scrollRatio * maxThumbLeft));
    customScrollPercent = Math.round(scrollRatio * 100);
  }

  function onThumbMouseDown(event) {
    isDraggingThumb = true;
    dragStartX = event.clientX;
    dragStartScrollLeft = bottomScrollEl?.scrollLeft || 0;
    document.addEventListener('mousemove', onThumbMouseMove);
    document.addEventListener('mouseup', onThumbMouseUp);
    event.preventDefault();
  }
  function onThumbMouseMove(event) {
    if (!isDraggingThumb || !bottomScrollEl || !customTrackEl) return;
    const contentWidth = bottomScrollEl.scrollWidth;
    const viewportWidth = bottomScrollEl.clientWidth;
    const deltaX = event.clientX - dragStartX;
    const maxThumbLeft = Math.max(0, customTrackEl.clientWidth - customThumbWidth);
    const contentScrollable = Math.max(1, contentWidth - viewportWidth);
    const scrollPerPx = contentScrollable / Math.max(1, maxThumbLeft);
    bottomScrollEl.scrollLeft = Math.min(contentScrollable, Math.max(0, dragStartScrollLeft + deltaX * scrollPerPx));
    syncFromBottom();
  }
  function onThumbMouseUp() {
    isDraggingThumb = false;
    document.removeEventListener('mousemove', onThumbMouseMove);
    document.removeEventListener('mouseup', onThumbMouseUp);
  }
  function onTrackClick(event) {
    if (!customTrackEl || !bottomScrollEl) return;
    const rect = customTrackEl.getBoundingClientRect();
    const clickX = event.clientX - rect.left;
    const targetLeft = clickX - customThumbWidth / 2;
    const maxThumbLeft = Math.max(0, customTrackEl.clientWidth - customThumbWidth);
    const clampedLeft = Math.min(maxThumbLeft, Math.max(0, targetLeft));
    const contentWidth = bottomScrollEl.scrollWidth;
    const viewportWidth = bottomScrollEl.clientWidth;
    const contentScrollable = Math.max(1, contentWidth - viewportWidth);
    const scrollRatio = clampedLeft / Math.max(1, maxThumbLeft);
    bottomScrollEl.scrollLeft = scrollRatio * contentScrollable;
    syncFromBottom();
  }
  function onTrackKeyDown(event) {
    if (!bottomScrollEl) return;
    if (event.key === 'Enter' || event.key === ' ') {
      onTrackClick(event);
      event.preventDefault();
    } else if (event.key === 'ArrowLeft') {
      bottomScrollEl.scrollLeft = Math.max(0, bottomScrollEl.scrollLeft - bottomScrollEl.clientWidth * 0.9);
      syncFromBottom();
      event.preventDefault();
    } else if (event.key === 'ArrowRight') {
      const maxScroll = Math.max(0, bottomScrollEl.scrollWidth - bottomScrollEl.clientWidth);
      bottomScrollEl.scrollLeft = Math.min(maxScroll, bottomScrollEl.scrollLeft + bottomScrollEl.clientWidth * 0.9);
      syncFromBottom();
      event.preventDefault();
    }
  }
  
  function handleDragStart(event, claim, stage) {
    draggedClaim = claim;
    draggedFromStage = stage;
    hasDragged = false; // Reset drag flag
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/html', event.target.outerHTML);
    
    // Add visual feedback
    event.target.style.opacity = '0.5';
  }
  
  function handleDragEnd(event) {
    event.target.style.opacity = '1';
    draggedClaim = null;
    draggedFromStage = null;
    dragOverStage = null;
    // Reset drag flag after a short delay to allow click event to be processed
    setTimeout(() => {
      hasDragged = false;
    }, 100);
  }
  
  function handleDragOver(event, stage) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
    dragOverStage = stage;
  }
  
  function handleDragLeave(event) {
    // Only clear dragOverStage if we're leaving the drop zone entirely
    if (!event.currentTarget.contains(event.relatedTarget)) {
      dragOverStage = null;
    }
  }
  
  async function handleDrop(event, targetStage) {
    event.preventDefault();
    
    if (draggedClaim && draggedFromStage !== targetStage) {
      hasDragged = true; // Mark that a drag operation occurred
      
      try {
        // Update the stage via PATCH request
        const response = await fetch(`/rnd_claims/${draggedClaim.id}/change_stage`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
            'Accept': 'application/json'
          },
          body: JSON.stringify({ stage: targetStage })
        });
        
        const data = await response.json();
        
        if (data.success) {
          toast.success(`Moved to ${formatStageName(targetStage)}`);
          // Refresh the page to update the pipeline data
          router.reload();
        } else {
          toast.error(data.message || 'Failed to update stage');
        }
      } catch (error) {
        console.error('Error updating stage:', error);
        toast.error('Failed to update stage');
      }
    }
    
    dragOverStage = null;
  }
  
  function getDropZoneClass(stage) {
    let classes = 'transition-colors duration-200';
    if (dragOverStage === stage && draggedFromStage !== stage) {
      classes += ' bg-primary/20 border-2 border-dashed border-primary';
    }
    return classes;
  }
  
  function getStageBadgeClass(stage) {
    switch(stage) {
      // Pre-delivery (grey family)
      case 'upcoming': return 'badge-ghost';
      case 'readying_for_delivery': return 'badge-neutral';
      // In delivery (blue family)
      case 'in_progress': return 'badge-info';
      case 'finalised': return 'badge-primary';
      // Post delivery (purple family)
      case 'filed_awaiting_hmrc': return 'badge-accent';
      case 'claim_processed': return 'badge-accent';
      case 'client_invoiced': return 'badge-accent';
      // Paid (success)
      case 'paid': return 'badge-success';
      default: return 'badge-neutral';
    }
  }
</script>

<style>
  /* Ensure the top scrollbar is visibly rendered across browsers */
  .top-scroll { scrollbar-width: thin; scrollbar-color: #94a3b8 #e5e7eb; }
  .top-scroll::-webkit-scrollbar { height: 8px; }
  .top-scroll::-webkit-scrollbar-track { background: #e5e7eb; border-radius: 4px; }
  .top-scroll::-webkit-scrollbar-thumb { background: #94a3b8; border-radius: 4px; }
  .top-scroll::-webkit-scrollbar-thumb:hover { background: #64748b; }
  /* Avoid collapsing height on some engines */
  .top-scroll > div { min-height: 2px; }
  
</style>

<div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
  <div class="p-6">
    <!-- Top custom scrollbar (same as Grant Applications) -->
    <div class="mb-2 pl-1 pr-1">
      <div 
        class="custom-scrollbar-track" 
        bind:this={customTrackEl} 
        onclick={onTrackClick}
        role="scrollbar"
        aria-label="Pipeline horizontal scroll"
        aria-orientation="horizontal"
        aria-controls="rnd-pipeline-scroll-content"
        aria-valuenow={customScrollPercent}
        tabindex="0"
        onkeydown={onTrackKeyDown}
      >
        <div 
          class="custom-scrollbar-thumb" 
          style={`left:${customThumbLeft}px;width:${customThumbWidth}px`} 
          onmousedown={onThumbMouseDown}
          role="slider"
          aria-label="Scroll position"
          aria-orientation="horizontal"
          aria-valuenow={customScrollPercent}
          tabindex="0"
        ></div>
      </div>
    </div>
    <div id="rnd-pipeline-scroll-content" class="pipeline-scroll flex space-x-6 overflow-x-auto overflow-y-hidden pb-4 snap-x snap-mandatory" bind:this={bottomScrollEl} onscroll={syncFromBottom}>
      {#if pipeline_data && (pipeline_data['upcoming'] || pipeline_data['readying_for_delivery'])}
            <div class="flex-shrink-0 snap-start">
              <div class="rounded-lg p-4 min-h-96 bg-gray-100 border border-gray-400 text-base-content">
            <div class="flex space-x-6">
              {#if pipeline_data['upcoming']}
                <div class="flex-shrink-0 w-80">
                  <div class="rounded-lg p-4 min-h-96 bg-gray-50 border border-gray-200 {getDropZoneClass('upcoming')} text-base-content"
                       role="region"
                       aria-label="Drop zone for {formatStageName('upcoming')}"
                       ondragover={(e) => handleDragOver(e, 'upcoming')}
                       ondragleave={handleDragLeave}
                       ondrop={(e) => handleDrop(e, 'upcoming')}>
                    <div class="flex items-center justify-between mb-3">
                      <h3 class="font-semibold text-base-content text-sm">{formatStageName('upcoming')}</h3>
                      <div class="flex items-center gap-2">
                        <div class="text-gray-700 font-extrabold">{pipeline_data['upcoming'].count}</div>
                        <div class="text-xs text-base-content/60">{formatCurrencyGBP(pipeline_data['upcoming'].total_value)}</div>
                      </div>
                    </div>
                    <div class="space-y-3">
                      {#each pipeline_data['upcoming'].claims as claim}
                        <div class="bg-base-100 rounded-lg p-4 shadow-sm border border-base-300 hover:shadow-md transition-shadow cursor-move focus:outline-none focus:ring-2 focus:ring-primary/40"
                             role="button"
                             tabindex="0"
                             draggable="true"
                             ondragstart={(e) => handleDragStart(e, claim, 'upcoming')}
                             ondragend={handleDragEnd}
                             onclick={() => { if (!hasDragged) { router.visit(`/rnd_claims/${claim.id}`); } }}
                             onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); router.visit(`/rnd_claims/${claim.id}`); } }}>
                          <div class="flex items-start justify-between mb-2">
                            <div class="flex items-start space-x-2 flex-1">
                              <div class="text-base-content/30 mt-1 cursor-move" title="Drag to move">
                                <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 24 24"><path d="M11 18c0 1.1-.9 2-2 2s-2-.9-2-2 .9-2 2-2 2 .9 2 2zm-2-8c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm6 4c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/></svg>
                              </div>
                              <h4 class="font-medium text-sm text-base-content line-clamp-2 flex-1">{claim.title}</h4>
                            </div>
                          </div>
                          {#if claim.company}
                            <div class="text-xs text-base-content/70 mb-2">
                              <a href={`/companies/${claim.company.id}`} class="text-black hover:underline">{claim.company.name}</a>
                            </div>
                          {/if}
                            <div class="text-xs text-base-content/60 text-right">{formatCurrencyGBP(claim.total_expenditure)}</div>
                        </div>
                      {/each}
                      {#if pipeline_data['upcoming'].count === 0}
                        <div class="text-center py-8 text-base-content/50">
                          <svg class="mx-auto h-8 w-8 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path></svg>
                          <p class="text-sm">No claims</p>
                        </div>
                      {/if}
                    </div>
                  </div>
                </div>
              {/if}
              {#if pipeline_data['readying_for_delivery']}
                <div class="flex-shrink-0 w-80">
                      <div class="rounded-lg p-4 min-h-96 bg-gray-50 border border-gray-200 {getDropZoneClass('readying_for_delivery')} text-base-content"
                       role="region"
                       aria-label="Drop zone for {formatStageName('readying_for_delivery')}"
                       ondragover={(e) => handleDragOver(e, 'readying_for_delivery')}
                       ondragleave={handleDragLeave}
                       ondrop={(e) => handleDrop(e, 'readying_for_delivery')}>
                    <div class="flex items-center justify-between mb-3">
                      <h3 class="font-semibold text-base-content text-sm">{formatStageName('readying_for_delivery')}</h3>
                          <div class="flex items-center gap-2">
                            <div class="text-gray-700 font-extrabold">{pipeline_data['readying_for_delivery'].count}</div>
                            <div class="text-xs text-base-content/60">{formatCurrencyGBP(pipeline_data['readying_for_delivery'].total_value)}</div>
                          </div>
                    </div>
                    <div class="space-y-3">
                      {#each pipeline_data['readying_for_delivery'].claims as claim}
                        <div class="bg-base-100 rounded-lg p-4 shadow-sm border border-base-300 hover:shadow-md transition-shadow cursor-move focus:outline-none focus:ring-2 focus:ring-primary/40"
                             role="button"
                             tabindex="0"
                             draggable="true"
                             ondragstart={(e) => handleDragStart(e, claim, 'readying_for_delivery')}
                             ondragend={handleDragEnd}
                             onclick={() => { if (!hasDragged) { router.visit(`/rnd_claims/${claim.id}`); } }}
                             onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); router.visit(`/rnd_claims/${claim.id}`); } }}>
                          <div class="flex items-start justify-between mb-2">
                            <div class="flex items-start space-x-2 flex-1">
                              <div class="text-base-content/30 mt-1 cursor-move" title="Drag to move">
                                <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 24 24"><path d="M11 18c0 1.1-.9 2-2 2s-2-.9-2-2 .9-2 2-2 2 .9 2 2zm-2-8c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm6 4c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/></svg>
                              </div>
                              <h4 class="font-medium text-sm text-base-content line-clamp-2 flex-1">{claim.title}</h4>
                            </div>
                          </div>
                          {#if claim.company}
                            <div class="text-xs text-base-content/70 mb-2">
                              <a href={`/companies/${claim.company.id}`} class="text-black hover:underline">{claim.company.name}</a>
                            </div>
                          {/if}
                              <div class="text-xs text-base-content/60 text-right">{formatCurrencyGBP(claim.total_expenditure)}</div>
                        </div>
                      {/each}
                      {#if pipeline_data['readying_for_delivery'].count === 0}
                        <div class="text-center py-8 text-base-content/50">
                          <svg class="mx-auto h-8 w-8 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path></svg>
                          <p class="text-sm">No claims</p>
                        </div>
                      {/if}
                    </div>
                  </div>
                </div>
              {/if}
            </div>
          </div>
        </div>
      {/if}
      <!-- In-delivery combined wrapper (in_progress + finalised) -->
      {#if pipeline_data && (pipeline_data['in_progress'] || pipeline_data['finalised'])}
        <div class="flex-shrink-0 snap-start">
          <div class="rounded-lg p-4 min-h-96 bg-blue-100 border border-blue-400 text-blue-900">
            <div class="flex space-x-6">
              {#if pipeline_data['in_progress']}
                <div class="flex-shrink-0 w-80">
                  <div class="rounded-lg p-4 min-h-96 bg-blue-50 border border-blue-100 {getDropZoneClass('in_progress')} text-base-content"
                       role="region"
                       aria-label="Drop zone for {formatStageName('in_progress')}"
                       ondragover={(e) => handleDragOver(e, 'in_progress')}
                       ondragleave={handleDragLeave}
                       ondrop={(e) => handleDrop(e, 'in_progress')}>
                    <div class="flex items-center justify-between mb-3">
                      <h3 class="font-semibold text-base-content text-sm">{formatStageName('in_progress')}</h3>
                      <div class="flex items-center gap-2">
                        <div class="text-blue-700 font-extrabold">{pipeline_data['in_progress'].count}</div>
                        <div class="text-xs text-base-content/60">{formatCurrencyGBP(pipeline_data['in_progress'].total_value)}</div>
                      </div>
                    </div>
                    <div class="space-y-3">
                      {#each pipeline_data['in_progress'].claims as claim}
                        <div class="bg-base-100 rounded-lg p-4 shadow-sm border border-base-300 hover:shadow-md transition-shadow cursor-move focus:outline-none focus:ring-2 focus:ring-primary/40"
                             role="button"
                             tabindex="0"
                             draggable="true"
                             ondragstart={(e) => handleDragStart(e, claim, 'in_progress')}
                             ondragend={handleDragEnd}
                             onclick={() => { if (!hasDragged) { router.visit(`/rnd_claims/${claim.id}`); } }}
                             onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); router.visit(`/rnd_claims/${claim.id}`); } }}>
                          <div class="flex items-start justify-between mb-2">
                            <div class="flex items-start space-x-2 flex-1">
                              <div class="text-base-content/30 mt-1 cursor-move" title="Drag to move">
                                <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 24 24"><path d="M11 18c0 1.1-.9 2-2 2s-2-.9-2-2 .9-2 2-2 2 .9 2 2zm-2-8c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm6 4c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/></svg>
                              </div>
                              <h4 class="font-medium text-sm text-base-content line-clamp-2 flex-1">{claim.title}</h4>
                            </div>
                          </div>
                          {#if claim.company}
                            <div class="text-xs text-base-content/70 mb-2">
                              <a href={`/companies/${claim.company.id}`} class="text-black hover:underline">{claim.company.name}</a>
                            </div>
                          {/if}
                          <div class="text-xs text-base-content/60 text-right">{formatCurrencyGBP(claim.total_expenditure)}</div>
                        </div>
                      {/each}
                      {#if pipeline_data['in_progress'].count === 0}
                        <div class="text-center py-8 text-base-content/50">
                          <svg class="mx-auto h-8 w-8 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path></svg>
                          <p class="text-sm">No claims</p>
                        </div>
                      {/if}
                    </div>
                  </div>
                </div>
              {/if}
              {#if pipeline_data['finalised']}
                <div class="flex-shrink-0 w-80">
                  <div class="rounded-lg p-4 min-h-96 bg-blue-50 border border-blue-100 {getDropZoneClass('finalised')} text-base-content"
                       role="region"
                       aria-label="Drop zone for {formatStageName('finalised')}"
                       ondragover={(e) => handleDragOver(e, 'finalised')}
                       ondragleave={handleDragLeave}
                       ondrop={(e) => handleDrop(e, 'finalised')}>
                    <div class="flex items-center justify-between mb-3">
                      <h3 class="font-semibold text-base-content text-sm">{formatStageName('finalised')}</h3>
                      <div class="flex items-center gap-2">
                        <div class="text-blue-700 font-extrabold">{pipeline_data['finalised'].count}</div>
                        <div class="text-xs text-base-content/60">{formatCurrencyGBP(pipeline_data['finalised'].total_value)}</div>
                      </div>
                    </div>
                    <div class="space-y-3">
                      {#each pipeline_data['finalised'].claims as claim}
                        <div class="bg-base-100 rounded-lg p-4 shadow-sm border border-base-300 hover:shadow-md transition-shadow cursor-move focus:outline-none focus:ring-2 focus:ring-primary/40"
                             role="button"
                             tabindex="0"
                             draggable="true"
                             ondragstart={(e) => handleDragStart(e, claim, 'finalised')}
                             ondragend={handleDragEnd}
                             onclick={() => { if (!hasDragged) { router.visit(`/rnd_claims/${claim.id}`); } }}
                             onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); router.visit(`/rnd_claims/${claim.id}`); } }}>
                          <div class="flex items-start justify-between mb-2">
                            <div class="flex items-start space-x-2 flex-1">
                              <div class="text-base-content/30 mt-1 cursor-move" title="Drag to move">
                                <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 24 24"><path d="M11 18c0 1.1-.9 2-2 2s-2-.9-2-2 .9-2 2-2 2 .9 2 2zm-2-8c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm6 4c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/></svg>
                              </div>
                              <h4 class="font-medium text-sm text-base-content line-clamp-2 flex-1">{claim.title}</h4>
                            </div>
                          </div>
                          {#if claim.company}
                            <div class="text-xs text-base-content/70 mb-2">
                              <a href={`/companies/${claim.company.id}`} class="text-black hover:underline">{claim.company.name}</a>
                            </div>
                          {/if}
                          <div class="text-xs text-base-content/60 text-right">{formatCurrencyGBP(claim.total_expenditure)}</div>
                        </div>
                      {/each}
                      {#if pipeline_data['finalised'].count === 0}
                        <div class="text-center py-8 text-base-content/50">
                          <svg class="mx-auto h-8 w-8 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path></svg>
                          <p class="text-sm">No claims</p>
                        </div>
                      {/if}
                    </div>
                  </div>
                </div>
              {/if}
            </div>
          </div>
        </div>
      {/if}
      {#if pipeline_data && (pipeline_data['filed_awaiting_hmrc'] || pipeline_data['claim_processed'] || pipeline_data['client_invoiced'] || pipeline_data['paid'])}
        <div class="flex-shrink-0 snap-start">
          <div class="rounded-lg p-4 min-h-96 bg-purple-100 border border-purple-400 text-purple-900">
            <div class="flex space-x-6">
              {#each ['filed_awaiting_hmrc','claim_processed','client_invoiced','paid'] as stage}
                {#if pipeline_data[stage]}
        <div class="flex-shrink-0 w-80">
                    <div class="rounded-lg p-4 min-h-96 bg-purple-50 border border-purple-100 {getDropZoneClass(stage)} text-base-content"
               role="region"
               aria-label="Drop zone for {formatStageName(stage)}"
               ondragover={(e) => handleDragOver(e, stage)}
               ondragleave={handleDragLeave}
               ondrop={(e) => handleDrop(e, stage)}>
                      <div class="flex items-center justify-between mb-3">
                        <h3 class="font-semibold text-base-content text-sm">{formatStageName(stage)}</h3>
                        <div class="flex items-center gap-2">
                          <div class="text-purple-700 font-extrabold">{pipeline_data[stage].count}</div>
                          <div class="text-xs text-base-content/60">{formatCurrencyGBP(pipeline_data[stage].total_value)}</div>
                        </div>
            </div>
            <div class="space-y-3">
                        {#each pipeline_data[stage].claims as claim}
                          <div class="bg-base-100 rounded-lg p-4 shadow-sm border border-base-300 hover:shadow-md transition-shadow cursor-move focus:outline-none focus:ring-2 focus:ring-primary/40"
                     role="button"
                     tabindex="0"
                     draggable="true"
                     ondragstart={(e) => handleDragStart(e, claim, stage)}
                     ondragend={handleDragEnd}
                     onclick={() => { if (!hasDragged) { router.visit(`/rnd_claims/${claim.id}`); } }}
                     onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); router.visit(`/rnd_claims/${claim.id}`); } }}>
                  <div class="flex items-start justify-between mb-2">
                    <div class="flex items-start space-x-2 flex-1">
                      <div class="text-base-content/30 mt-1 cursor-move" title="Drag to move">
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M11 18c0 1.1-.9 2-2 2s-2-.9-2-2 .9-2 2-2 2 .9 2 2zm-2-8c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm6 4c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/>
                        </svg>
                      </div>
                                <h4 class="font-medium text-sm text-base-content line-clamp-2 flex-1">{claim.title}</h4>
                    </div>
                  </div>
                  {#if claim.company}
                    <div class="text-xs text-base-content/70 mb-2">
                                <a href={`/companies/${claim.company.id}`} class="text-black hover:underline">{claim.company.name}</a>
                    </div>
                  {/if}
                            <div class="text-xs text-base-content/60 text-right">{formatCurrencyGBP(claim.total_expenditure)}</div>
                </div>
              {/each}
                        {#if pipeline_data[stage].count === 0}
                <div class="text-center py-8 text-base-content/50">
                  <svg class="mx-auto h-8 w-8 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                  </svg>
                  <p class="text-sm">No claims</p>
                </div>
              {/if}
            </div>
          </div>
        </div>
                {/if}
      {/each}
            </div>
          </div>
        </div>
      {/if}
    </div>
  </div>
</div>
