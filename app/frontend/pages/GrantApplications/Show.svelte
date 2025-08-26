<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Select from '../../components/forms/Select.svelte';
  
  let { user, grant_application, documents } = $props();
  
  let newStatus = $state(grant_application.status);
  let loading = $state(false);
  
  function handleStatusChange() {
    if (confirm(`Are you sure you want to change the status to ${newStatus.replace('_', ' ')}?`)) {
      loading = true;
      router.patch(`/grant_applications/${grant_application.id}/change_status`, { status: newStatus }, {
        onSuccess: () => {
          toast.success('Status updated successfully!');
          loading = false;
        },
        onError: () => {
          toast.error('Failed to update status.');
          loading = false;
        }
      });
    }
  }
  
  function handleSubmit() {
    if (confirm('Are you sure you want to submit this grant application? This action cannot be undone.')) {
      loading = true;
      router.patch(`/grant_applications/${grant_application.id}/submit`, {}, {
        onSuccess: () => {
          toast.success('Grant application submitted successfully!');
          loading = false;
        },
        onError: () => {
          toast.error('Failed to submit grant application.');
          loading = false;
        }
      });
    }
  }
  
  function handleDelete() {
    if (confirm('Are you sure you want to delete this grant application? This action cannot be undone.')) {
      router.delete(`/grant_applications/${grant_application.id}`, {
        onSuccess: () => {
          toast.success('Grant application deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete grant application.');
        }
      });
    }
  }
  
  function goBack() {
    router.visit('/grant_applications', {
      onSuccess: () => {
        // Refresh the page after navigation
        window.location.reload();
      }
    });
  }
  
  function getStatusDisplayName(status) {
    return status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
  }
  
  function formatDeadline(deadline) {
    if (!deadline) return 'No deadline set';
    return deadline;
  }
</script>

<Layout {user}>
    <div class="max-w-4xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <Button variant="secondary" onclick={goBack} class="mb-4">
          ← Back to Grant Applications
        </Button>
        
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 mb-2">{grant_application.title}</h1>
            <p class="text-gray-600 mb-4">{grant_application.description}</p>
          </div>
          
          <div class="flex space-x-2">
            {#if grant_application.can_edit}
              <Button variant="secondary" onclick={() => router.visit(`/grant_applications/${grant_application.id}/edit`, {
                onSuccess: () => {
                  // Refresh the page after navigation
                  window.location.reload();
                }
              })}>
                Edit
              </Button>
            {/if}
            {#if grant_application.can_submit}
              <Button variant="primary" onclick={handleSubmit} disabled={loading}>
                Submit Application
              </Button>
            {/if}
            {#if grant_application.can_edit}
              <Button variant="error" onclick={handleDelete} disabled={loading}>
                Delete
              </Button>
            {/if}
          </div>
        </div>
      </div>
      
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main Content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Application Details -->
          <div class="bg-white rounded-lg shadow-sm border p-6">
            <h2 class="text-xl font-semibold text-gray-900 mb-4">Application Details</h2>
            
            <div class="space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="label">
                    <span class="label-text font-medium">Status</span>
                  </label>
                  <div class="badge {grant_application.status_color} badge-lg">
                    {getStatusDisplayName(grant_application.status)}
                  </div>
                  {#if grant_application.overdue}
                    <div class="badge badge-error badge-sm mt-2">Overdue</div>
                  {/if}
                </div>
                
                <div>
                  <label class="label">
                    <span class="label-text font-medium">Deadline</span>
                  </label>
                  <div class="text-sm">
                    {formatDeadline(grant_application.deadline)}
                  </div>
                  {#if grant_application.days_until_deadline !== null}
                    <div class="text-xs opacity-50 mt-1">
                      {grant_application.days_until_deadline > 0 
                        ? `${grant_application.days_until_deadline} days left`
                        : grant_application.days_until_deadline < 0 
                          ? `${Math.abs(grant_application.days_until_deadline)} days overdue`
                          : 'Due today'
                      }
                    </div>
                  {/if}
                </div>
              </div>
              
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="label">
                    <span class="label-text font-medium">Created</span>
                  </label>
                  <div class="text-sm">{grant_application.created_at}</div>
                </div>
                
                <div>
                  <label class="label">
                    <span class="label-text font-medium">Last Updated</span>
                  </label>
                  <div class="text-sm">{grant_application.updated_at}</div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Documents -->
          <div class="bg-white rounded-lg shadow-sm border p-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-semibold text-gray-900">Documents</h2>
              <Button variant="secondary" size="sm">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                </svg>
                Add Document
              </Button>
            </div>
            
            {#if documents.length > 0}
              <div class="space-y-3">
                {#each documents as document}
                  <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <div class="flex items-center space-x-3">
                      <i class="{document.icon_class} text-xl"></i>
                      <div>
                        <div class="font-medium">{document.name}</div>
                        <div class="text-sm text-gray-500">
                          {document.file_type.toUpperCase()} • {document.file_size} • {document.created_at}
                        </div>
                      </div>
                    </div>
                    <div class="flex space-x-2">
                      <button class="btn btn-ghost btn-sm">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                        </svg>
                      </button>
                      <button class="btn btn-ghost btn-sm">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path>
                        </svg>
                      </button>
                    </div>
                  </div>
                {/each}
              </div>
            {:else}
              <div class="text-center py-8">
                <svg class="w-12 h-12 mx-auto mb-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                </svg>
                <h3 class="text-lg font-medium text-gray-900 mb-2">No documents yet</h3>
                <p class="text-gray-500 mb-4">
                  Add documents to support your grant application
                </p>
                <Button variant="primary" size="sm">
                  Add Your First Document
                </Button>
              </div>
            {/if}
          </div>
        </div>
        
        <!-- Sidebar -->
        <div class="lg:col-span-1 space-y-6">
          <!-- Status Management -->
          <div class="bg-white rounded-lg shadow-sm border p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Status Management</h3>
            
            <div class="space-y-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Current Status</span>
                </label>
                <div class="badge {grant_application.status_color} badge-lg">
                  {getStatusDisplayName(grant_application.status)}
                </div>
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Change Status</span>
                </label>
                <Select
                  bind:value={newStatus}
                  options={[
                    { value: 'draft', label: 'Draft' },
                    { value: 'submitted', label: 'Submitted' },
                    { value: 'under_review', label: 'Under Review' },
                    { value: 'approved', label: 'Approved' },
                    { value: 'rejected', label: 'Rejected' },
                    { value: 'completed', label: 'Completed' }
                  ]}
                />
              </div>
              
              <Button
                variant="primary"
                onclick={handleStatusChange}
                disabled={loading || newStatus === grant_application.status}
                class="w-full"
              >
                {#if loading}
                  <span class="loading loading-spinner loading-sm"></span>
                  Updating...
                {:else}
                  Update Status
                {/if}
              </Button>
            </div>
          </div>
          
          <!-- Quick Actions -->
          <div class="bg-white rounded-lg shadow-sm border p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
            
            <div class="space-y-3">
              <Button variant="secondary" class="w-full justify-start">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                </svg>
                Add Document
              </Button>
              
              <Button variant="secondary" class="w-full justify-start">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                </svg>
                Set Reminder
              </Button>
              
              <Button variant="secondary" class="w-full justify-start">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z"></path>
                </svg>
                Share Application
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
</Layout> 