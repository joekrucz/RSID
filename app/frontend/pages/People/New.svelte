<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Input from '../../components/forms/Input.svelte';
  
  let { user, errors = [], person = {} } = $props();
  
  let formData = $state({
    name: person.name || '',
    email: person.email || '',
    password: '',
    password_confirmation: ''
  });
  
  let loading = $state(false);
  
  function goBack() {
    if (user) {
      router.visit('/people', {
        onSuccess: () => {
          // Refresh the page after navigation
          window.location.reload();
        }
      });
    } else {
      // For signup, go to login page
      router.visit('/login', {
        onSuccess: () => {
          // Refresh the page after navigation
          window.location.reload();
        }
      });
    }
  }
  
  function handleSubmit() {
    if (!formData.name.trim() || !formData.email.trim() || !formData.password.trim()) {
      toast.error('Please fill in all required fields');
      return;
    }
    
    if (formData.password !== formData.password_confirmation) {
      toast.error('Passwords do not match');
      return;
    }
    
    if (formData.password.length < 6) {
      toast.error('Password must be at least 6 characters long');
      return;
    }
    
    loading = true;
    router.post('/people', {
      person: formData
    }, {
      onSuccess: () => {
        toast.success('Person created successfully!');
        loading = false;
      },
      onError: (errors) => {
        toast.error('Failed to create person');
        loading = false;
      }
    });
  }
</script>

<svelte:head>
  <title>{user ? 'Add New Person' : 'Sign Up'} - RSID App</title>
</svelte:head>

<Layout {user}>
    <div class="max-w-2xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        {#if user}
          <Button variant="secondary" onclick={goBack} class="mb-4">
            ← Back to People
          </Button>
        {/if}
        
        <h1 class="text-3xl font-bold text-base-content mb-2">{user ? 'Add New Person' : 'Sign Up'}</h1>
        <p class="text-base-content/70">{user ? 'Create a new person account in the system' : 'Create your account to get started'}</p>
      </div>
      
      <!-- Form -->
      <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
        <form onsubmit={(e) => { e.preventDefault(); handleSubmit(); }}>
          <div class="space-y-6">
            <!-- Name -->
            <div class="form-control">
              <label class="label">
                <span class="label-text">Full Name *</span>
              </label>
              <Input
                type="text"
                placeholder="Enter the person's full name..."
                bind:value={formData.name}
                error={errors.name}
                required
              />
            </div>
            
            <!-- Email -->
            <div class="form-control">
              <label class="label">
                <span class="label-text">Email Address *</span>
              </label>
              <Input
                type="email"
                placeholder="Enter the person's email address..."
                bind:value={formData.email}
                error={errors.email}
                required
              />
            </div>
            
            <!-- Password -->
            <div class="form-control">
              <label class="label">
                <span class="label-text">Password *</span>
              </label>
              <Input
                type="password"
                placeholder="Enter a secure password..."
                bind:value={formData.password}
                error={errors.password}
                required
              />
              <label class="label">
                <span class="label-text-alt text-base-content/50">Minimum 6 characters</span>
              </label>
            </div>
            
            <!-- Password Confirmation -->
            <div class="form-control">
              <label class="label">
                <span class="label-text">Confirm Password *</span>
              </label>
              <Input
                type="password"
                placeholder="Confirm the password..."
                bind:value={formData.password_confirmation}
                error={errors.password_confirmation}
                required
              />
            </div>
            
            {#if user}
              <!-- Role Info -->
              <div class="alert alert-info">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path>
                </svg>
                <div>
                  <h3 class="font-medium">Default Role</h3>
                  <div class="text-sm">
                    New people are created as <span class="badge badge-info">Client</span> by default. 
                    Role can be changed later by administrators.
                  </div>
                </div>
              </div>
            {/if}
            
            <!-- Submit Button -->
            <div class="flex justify-end space-x-4">
              {#if user}
                <Button variant="secondary" onclick={goBack} type="button">
                  Cancel
                </Button>
              {/if}
              <Button variant="primary" type="submit" disabled={loading}>
                {loading ? (user ? 'Creating...' : 'Signing up...') : (user ? 'Create Person' : 'Sign Up')}
              </Button>
            </div>
          </div>
        </form>
      </div>
    </div>
</Layout> 