<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../../stores/toast.js';
  import Layout from '../../../components/Layout.svelte';
  import Button from '../../../components/forms/Button.svelte';
  import Input from '../../../components/forms/Input.svelte';
  
  let { user, errors = [], feature_flag = {} } = $props();
  
  let formData = $state({
    name: feature_flag.name || '',
    description: feature_flag.description || '',
    enabled: feature_flag.enabled || false,
    employee_enabled: feature_flag.settings?.employee_enabled || false,
    client_enabled: feature_flag.settings?.client_enabled || false
  });
  
  let loading = $state(false);
  
  function handleSubmit() {
    loading = true;
    
    const data = {
      feature_flag: {
        name: formData.name,
        description: formData.description,
        enabled: formData.enabled,
        settings: {
          employee_enabled: formData.employee_enabled,
          client_enabled: formData.client_enabled
        }
      }
    };
    
    router.post('/admin/feature_flags', data, {
      onSuccess: () => {
        toast.success('Feature flag created successfully!');
        loading = false;
      },
      onError: () => {
        toast.error('Failed to create feature flag. Please check the form and try again.');
        loading = false;
      }
    });
  }
  
  function goBack() {
    router.visit('/admin/feature_flags');
  }
</script>

<svelte:head>
  <title>New Feature Flag - RSID App</title>
</svelte:head>

<Layout {user}>
  <!-- Header -->
  <div class="mb-8">
    <div class="flex items-center justify-between mb-4">
      <div>
        <button onclick={goBack} class="btn btn-ghost btn-sm mb-2">
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
          </svg>
          Back to Feature Flags
        </button>
        <h1 class="text-3xl font-bold text-base-content mb-2">New Feature Flag</h1>
        <p class="text-base-content/70">Create a new feature flag to control access to application features</p>
      </div>
    </div>
  </div>
  
  <!-- Form -->
  <div class="max-w-2xl mx-auto">
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <form onsubmit={(e) => { e.preventDefault(); handleSubmit(); }}>
          <!-- Basic Information -->
          <div class="mb-6">
            <h3 class="text-lg font-semibold text-base-content mb-4">Basic Information</h3>
            
            <div class="grid grid-cols-1 gap-6">
              <div class="form-control">
                <div class="label">
                  <span class="label-text font-medium">Feature Name *</span>
                </div>
                <Input
                  type="text"
                  placeholder="e.g., rnd_projects, grant_applications"
                  bind:value={formData.name}
                  error={errors.find(e => e.includes('Name'))}
                  required
                />
                <div class="label">
                  <span class="label-text-alt">Use snake_case format (e.g., rnd_projects)</span>
                </div>
              </div>
              
              <div class="form-control">
                <div class="label">
                  <span class="label-text font-medium">Description</span>
                </div>
                <textarea
                  class="textarea textarea-bordered h-24"
                  placeholder="Describe what this feature does..."
                  bind:value={formData.description}
                ></textarea>
                <div class="label">
                  <span class="label-text-alt">Provide a clear description of the feature</span>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Global Settings -->
          <div class="mb-6">
            <h3 class="text-lg font-semibold text-base-content mb-4">Global Settings</h3>
            
            <div class="form-control">
              <label class="label cursor-pointer">
                <span class="label-text font-medium">Enable Feature Globally</span>
                <input 
                  type="checkbox" 
                  class="toggle toggle-primary" 
                  bind:checked={formData.enabled}
                />
              </label>
              <label class="label">
                <span class="label-text-alt">When disabled, the feature is hidden from all users</span>
              </label>
            </div>
          </div>
          
          <!-- Role-based Access -->
          <div class="mb-6">
            <h3 class="text-lg font-semibold text-base-content mb-4">Role-based Access</h3>
            <p class="text-base-content/70 mb-4">Configure which user roles can access this feature by default</p>
            
            <div class="space-y-4">
              <div class="form-control">
                <label class="label cursor-pointer">
                  <span class="label-text font-medium">Available to Employees</span>
                  <input 
                    type="checkbox" 
                    class="toggle toggle-info" 
                    bind:checked={formData.employee_enabled}
                  />
                </label>
                <label class="label">
                  <span class="label-text-alt">Employees and admins can access this feature</span>
                </label>
              </div>
              
              <div class="form-control">
                <label class="label cursor-pointer">
                  <span class="label-text font-medium">Available to Clients</span>
                  <input 
                    type="checkbox" 
                    class="toggle toggle-warning" 
                    bind:checked={formData.client_enabled}
                  />
                </label>
                <label class="label">
                  <span class="label-text-alt">Clients can access this feature</span>
                </label>
              </div>
            </div>
          </div>
          
          <!-- Submit -->
          <div class="flex justify-end gap-4">
            <Button variant="ghost" onclick={goBack} disabled={loading}>
              Cancel
            </Button>
            <Button variant="primary" type="submit" loading={loading}>
              Create Feature Flag
            </Button>
          </div>
        </form>
      </div>
    </div>
  </div>
</Layout>
