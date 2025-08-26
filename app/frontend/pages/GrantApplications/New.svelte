<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Input from '../../components/forms/Input.svelte';
  
  let { user, errors = {}, grant_application = {} } = $props();
  
  let title = $state(grant_application.title || '');
  let description = $state(grant_application.description || '');
  let deadlineDate = $state('');
  let deadlineTime = $state('12:00');
  let loading = $state(false);
  
  function handleSubmit() {
    console.log('Form values:', { title, description, deadlineDate, deadlineTime });
    console.log('Title type:', typeof title);
    console.log('Title value:', title);
    console.log('Title length:', title ? title.length : 0);
    console.log('Title trimmed:', title ? title.trim() : '');
    console.log('DeadlineDate type:', typeof deadlineDate);
    console.log('DeadlineDate value:', deadlineDate);
    console.log('DeadlineDate length:', deadlineDate ? deadlineDate.length : 0);
    
    // Enhanced validation with better error messages
    if (!title.trim()) {
      toast.error('Please enter an application title.');
      return;
    }
    
    if (!description.trim()) {
      toast.error('Please enter a description.');
      return;
    }
    
    if (!deadlineDate) {
      toast.error('Please select a deadline date.');
      return;
    }
    
    // Validate date format
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(deadlineDate)) {
      toast.error('Please enter a valid date in YYYY-MM-DD format.');
      return;
    }
    
    // Validate that the date is not in the past
    const selectedDate = new Date(`${deadlineDate}T${deadlineTime}`);
    const now = new Date();
    if (selectedDate <= now) {
      toast.error('Deadline must be in the future.');
      return;
    }
    
    const deadline = new Date(`${deadlineDate}T${deadlineTime}`);
    console.log('Deadline object:', deadline);
    
    loading = true;
    router.post('/grant_applications', {
      grant_application: {
        title: title.trim(),
        description: description.trim(),
        deadline: deadline.toISOString(),
        status: 'draft'
      }
    }, {
      onSuccess: () => {
        toast.success('Grant application created successfully!');
        loading = false;
      },
      onError: (errors) => {
        console.log('Server errors:', errors);
        if (errors && errors.grant_application) {
          // Show specific validation errors
          const errorMessages = Object.values(errors.grant_application).flat();
          errorMessages.forEach(message => toast.error(message));
        } else if (errors && typeof errors === 'object') {
          // Handle other error formats
          Object.values(errors).flat().forEach(message => toast.error(message));
        } else {
          toast.error('Failed to create grant application.');
        }
        loading = false;
      }
    });
  }
  
  function goBack() {
    router.visit('/grant_applications', {
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
          ← Back to Grant Applications
        </Button>
        
        <h1 class="text-3xl font-bold text-base-content mb-2">New Grant Application</h1>
        <p class="text-base-content/70">Create a new grant application to track from start to finish</p>
      </div>
      
      <!-- Form -->
      <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
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
                onchange={() => console.log('Title changed to:', title)}
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
                  min={new Date().toISOString().split('T')[0]}
                  onchange={() => console.log('Date changed to:', deadlineDate)}
                />
                <label class="label">
                  <span class="label-text-alt text-base-content/50">Select a future date for the deadline</span>
                </label>
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
                <h3 class="font-medium">Application Status</h3>
                <div class="text-sm">
                  New applications are created as <span class="badge badge-neutral">Draft</span> by default. 
                  You can edit and submit them when ready.
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
                  Creating...
                {:else}
                  Create Application
                {/if}
              </Button>
            </div>
          </div>
        </form>
      </div>
    </div>
</Layout> 