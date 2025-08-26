<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Input from '../../components/forms/Input.svelte';
  
  let { user, grant_application, errors = {} } = $props();
  
  let title = $state(grant_application.title || '');
  let description = $state(grant_application.description || '');
  let deadlineDate = $state(grant_application.deadline_date || '');
  let deadlineTime = $state(grant_application.deadline_time || '12:00');
  let loading = $state(false);
  
  function handleSubmit() {
    if (!title.trim() || !description.trim() || !deadlineDate) {
      toast.error('Please fill in all required fields.');
      return;
    }
    
    const deadline = new Date(`${deadlineDate}T${deadlineTime}`);
    
    loading = true;
    router.put(`/grant_applications/${grant_application.id}`, {
      grant_application: {
        title: title.trim(),
        description: description.trim(),
        deadline: deadline.toISOString(),
        status: grant_application.status
      }
    }, {
      onSuccess: () => {
        toast.success('Grant application updated successfully!');
        loading = false;
      },
      onError: () => {
        toast.error('Failed to update grant application.');
        loading = false;
      }
    });
  }
  
  function goBack() {
    router.visit(`/grant_applications/${grant_application.id}`, {
      onSuccess: () => {
        // Refresh the page after navigation
        window.location.reload();
      }
    });
  }
</script>

<Layout {user}>
    <div class="max-w-2xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <Button variant="secondary" onclick={goBack} class="mb-4">
          ← Back to Application
        </Button>
        
        <h1 class="text-3xl font-bold text-gray-900 mb-2">Edit Grant Application</h1>
        <p class="text-gray-600">Update your grant application details</p>
      </div>
      
      <!-- Form -->
      <div class="bg-white rounded-lg shadow-sm border p-6">
        <form onsubmit={(e) => { e.preventDefault(); handleSubmit(); }}>
          <div class="space-y-6">
            <!-- Title -->
            <div class="form-control">
              <label class="label">
                <span class="label-text">Application Title *</span>
              </label>
              <Input
                type="text"
                placeholder="Enter the grant application title..."
                bind:value={title}
                error={errors.title}
                required
              />
            </div>
            
            <!-- Description -->
            <div class="form-control">
              <label class="label">
                <span class="label-text">Description *</span>
              </label>
              <textarea
                placeholder="Describe your grant application..."
                class="textarea textarea-bordered w-full h-32"
                bind:value={description}
                required
              ></textarea>
              {#if errors.description}
                <label class="label">
                  <span class="label-text-alt text-error">{errors.description}</span>
                </label>
              {/if}
            </div>
            
            <!-- Deadline -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Deadline Date *</span>
                </label>
                <input
                  type="date"
                  class="input input-bordered w-full"
                  bind:value={deadlineDate}
                  required
                />
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Deadline Time</span>
                </label>
                <input
                  type="time"
                  class="input input-bordered w-full"
                  bind:value={deadlineTime}
                />
              </div>
            </div>
            
            <!-- Status Info -->
            <div class="alert alert-info">
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path>
              </svg>
              <div>
                <h3 class="font-medium">Current Status</h3>
                <div class="text-sm">
                  Status: <span class="badge badge-neutral">{grant_application.status}</span>
                </div>
              </div>
            </div>
            
            <!-- Submit Button -->
            <div class="flex justify-end space-x-4">
              <Button variant="secondary" onclick={goBack} type="button">
                Cancel
              </Button>
              <Button 
                variant="primary" 
                type="submit"
                disabled={loading}
              >
                {#if loading}
                  <span class="loading loading-spinner loading-sm"></span>
                  Updating...
                {:else}
                  Update Application
                {/if}
              </Button>
            </div>
          </div>
        </form>
      </div>
    </div>
</Layout> 