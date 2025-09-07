<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../stores/toast.js';
  
  let { pipeline_data } = $props();
  
  let draggedApplication = $state(null);
  let draggedFromStage = $state(null);
  let dragOverStage = $state(null);
  let hasDragged = $state(false);
  
  function formatStageName(stage) {
    return stage.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
  }
  
  function handleDelete(applicationId) {
    if (confirm('Are you sure you want to delete this grant application? This action cannot be undone.')) {
      router.delete(`/grant_applications/${applicationId}`, {
        onSuccess: () => {
          toast.success('Grant application deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete grant application.');
        }
      });
    }
  }
  
  function handleDragStart(event, application, stage) {
    draggedApplication = application;
    draggedFromStage = stage;
    hasDragged = false; // Reset drag flag
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/html', event.target.outerHTML);
    
    // Add visual feedback
    event.target.style.opacity = '0.5';
  }
  
  function handleDragEnd(event) {
    event.target.style.opacity = '1';
    draggedApplication = null;
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
    
    if (draggedApplication && draggedFromStage !== targetStage) {
      hasDragged = true; // Mark that a drag operation occurred
      
      try {
        // Update the stage via PATCH request
        const response = await fetch(`/grant_applications/${draggedApplication.id}/change_stage`, {
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
</script>

<div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
  <div class="p-6">
    <div class="flex space-x-6 overflow-x-auto pb-4">
      {#each Object.entries(pipeline_data) as [stage, data]}
        <div class="flex-shrink-0 w-80">
          <div class="bg-base-200 rounded-lg p-4 min-h-96 {getDropZoneClass(stage)}"
               role="region"
               aria-label="Drop zone for {formatStageName(stage)}"
               ondragover={(e) => handleDragOver(e, stage)}
               ondragleave={handleDragLeave}
               ondrop={(e) => handleDrop(e, stage)}>
            <div class="flex items-center justify-between mb-4">
              <h3 class="font-semibold text-base-content">
                {formatStageName(stage)}
              </h3>
              <div class="badge badge-neutral">{data.count}</div>
            </div>
            
            <div class="space-y-3">
              {#each data.applications as application}
                <div class="bg-base-100 rounded-lg p-4 shadow-sm border border-base-300 hover:shadow-md transition-shadow cursor-move"
                     role="button"
                     tabindex="0"
                     draggable="true"
                     ondragstart={(e) => handleDragStart(e, application, stage)}
                     ondragend={handleDragEnd}
                     onclick={() => { if (!hasDragged) { router.visit(`/grant_applications/${application.id}`); } }}
                     onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); router.visit(`/grant_applications/${application.id}`); } }}>
                  <div class="flex items-start justify-between mb-2">
                    <div class="flex items-start space-x-2 flex-1">
                      <div class="text-base-content/30 mt-1 cursor-move" title="Drag to move">
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M11 18c0 1.1-.9 2-2 2s-2-.9-2-2 .9-2 2-2 2 .9 2 2zm-2-8c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0-6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm6 4c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/>
                        </svg>
                      </div>
                      <h4 class="font-medium text-sm text-base-content line-clamp-2 flex-1">
                        {application.title}
                      </h4>
                    </div>
                    {#if application.overdue}
                      <div class="badge badge-error badge-xs">Overdue</div>
                    {/if}
                  </div>
                  
                  {#if application.company}
                    <div class="text-xs text-base-content/70 mb-2">
                      <a href={`/companies/${application.company.id}`} class="link link-primary">
                        {application.company.name}
                      </a>
                    </div>
                  {/if}
                  
                  {#if application.grant_competition}
                    <div class="text-xs text-base-content/70 mb-2">
                      <a href={`/grant_competitions/${application.grant_competition.id}`} class="link link-primary">
                        {application.grant_competition.grant_name}
                      </a>
                    </div>
                  {/if}
                  
                  <div class="text-xs text-base-content/50 mb-2 line-clamp-2">
                    {application.description}
                  </div>
                  
                  <div class="flex items-center justify-between text-xs text-base-content/60">
                    <span>{application.deadline || 'No deadline'}</span>
                    <span>{application.documents_count} docs</span>
                  </div>
                  
                  <div class="flex items-center justify-between mt-3 pt-2 border-t border-base-300">
                    <div class="text-xs text-base-content/50">
                      {application.created_at}
                    </div>
                    <div class="flex space-x-1">
                      <button 
                        class="btn btn-xs btn-ghost"
                        onclick={(e) => { e.stopPropagation(); router.visit(`/grant_applications/${application.id}/edit`); }}
                        onmousedown={(e) => e.stopPropagation()}
                        title="Edit"
                        aria-label="Edit {application.title}"
                      >
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                        </svg>
                      </button>
                      <button 
                        class="btn btn-xs btn-ghost text-error"
                        onclick={(e) => { e.stopPropagation(); handleDelete(application.id); }}
                        onmousedown={(e) => e.stopPropagation()}
                        title="Delete"
                        aria-label="Delete {application.title}"
                      >
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              {/each}
              
              {#if data.count === 0}
                <div class="text-center py-8 text-base-content/50">
                  <svg class="mx-auto h-8 w-8 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                  </svg>
                  <p class="text-sm">No applications</p>
                </div>
              {/if}
            </div>
          </div>
        </div>
      {/each}
    </div>
  </div>
</div>
