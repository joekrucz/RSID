<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Toast from '../../components/Toast.svelte';
  
  let { errors = [], user = {} } = $props();
  
  // Watch for prop changes to handle server errors
  $effect(() => {
    if (errors && errors.length > 0) {
      // Convert array errors to field errors for consistency
      const fieldErrorMap = {};
      errors.forEach(error => {
        if (error.includes('Email')) {
          fieldErrorMap.email = error;
        } else if (error.includes('Password')) {
          fieldErrorMap.password = error;
        } else if (error.includes('Name')) {
          fieldErrorMap.name = error;
        }
      });
      fieldErrors = fieldErrorMap;
      
      // Show error toast for signup failures
      if (errors.length > 0) {
        toast.error(errors[0]); // Show first error as toast
      }
    }
  });
  
  let formData = $state({
    name: user.name || '',
    email: user.email || '',
    password: '',
    password_confirmation: ''
  });
  
  let loading = $state(false);
  let fieldErrors = $state({});
  
  function handleSubmit() {
    loading = true;
    fieldErrors = {};
    
    // Basic client-side validation
    const validationErrors = {};
    
    if (!formData.name) {
      validationErrors.name = 'Name is required';
    } else if (formData.name.length < 2) {
      validationErrors.name = 'Name must be at least 2 characters long';
    }
    
    if (!formData.email) {
      validationErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      validationErrors.email = 'Please enter a valid email address';
    }
    
    if (!formData.password) {
      validationErrors.password = 'Password is required';
    } else if (formData.password.length < 6) {
      validationErrors.password = 'Password must be at least 6 characters long';
    }
    
    if (!formData.password_confirmation) {
      validationErrors.password_confirmation = 'Password confirmation is required';
    } else if (formData.password !== formData.password_confirmation) {
      validationErrors.password_confirmation = 'Passwords do not match';
    }
    
    if (Object.keys(validationErrors).length > 0) {
      fieldErrors = validationErrors;
      loading = false;
      return;
    }
    
    router.post('/signup', { user: formData }, {
      preserveState: true,
      onFinish: () => {
        loading = false;
      }
    });
  }
</script>

<svelte:head>
  <title>Sign Up - RSID App</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-success/10 to-accent/10 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
  <div class="max-w-md w-full space-y-8">
    <div>
      <h2 class="mt-6 text-center text-3xl font-extrabold text-base-content">
        Create your account
      </h2>
      <p class="mt-2 text-center text-sm text-base-content/70">
        Or
        <a href="/login" class="font-medium text-primary hover:text-primary-focus">
          sign in to your existing account
        </a>
      </p>
      <div class="mt-4 text-center">
        <div class="badge badge-info">Client Registration</div>
        <p class="mt-1 text-xs text-base-content/50">You'll be registered as a client account</p>
      </div>
    </div>
    
    <!-- Global Error Alert -->
    {#if errors.length > 0}
      <div class="alert alert-error">
        <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div>
          <h3 class="font-bold">There were errors with your submission:</h3>
          <div class="text-xs">
            {#each errors as error}
              <div>{error}</div>
            {/each}
          </div>
        </div>
      </div>
    {/if}
    
    <form class="mt-8 space-y-6" onsubmit={handleSubmit}>
      <div class="space-y-4">
        <div class="form-control">
          <label for="name" class="label">
            <span class="label-text">Full Name</span>
          </label>
          <input
            id="name"
            name="name"
            type="text"
            required
            class="input input-bordered w-full {fieldErrors.name ? 'input-error' : ''}"
            placeholder="Enter your full name"
            bind:value={formData.name}
          />
          {#if fieldErrors.name}
            <label class="label">
              <span class="label-text-alt text-error">{fieldErrors.name}</span>
            </label>
          {/if}
        </div>
        
        <div class="form-control">
          <label for="email" class="label">
            <span class="label-text">Email address</span>
          </label>
          <input
            id="email"
            name="email"
            type="email"
            required
            class="input input-bordered w-full {fieldErrors.email ? 'input-error' : ''}"
            placeholder="Enter your email"
            bind:value={formData.email}
          />
          {#if fieldErrors.email}
            <label class="label">
              <span class="label-text-alt text-error">{fieldErrors.email}</span>
            </label>
          {/if}
        </div>
        
        <div class="form-control">
          <label for="password" class="label">
            <span class="label-text">Password</span>
          </label>
          <input
            id="password"
            name="password"
            type="password"
            required
            class="input input-bordered w-full {fieldErrors.password ? 'input-error' : ''}"
            placeholder="Enter your password"
            bind:value={formData.password}
          />
          {#if fieldErrors.password}
            <label class="label">
              <span class="label-text-alt text-error">{fieldErrors.password}</span>
            </label>
          {/if}
        </div>
        
        <div class="form-control">
          <label for="password_confirmation" class="label">
            <span class="label-text">Confirm Password</span>
          </label>
          <input
            id="password_confirmation"
            name="password_confirmation"
            type="password"
            required
            class="input input-bordered w-full {fieldErrors.password_confirmation ? 'input-error' : ''}"
            placeholder="Confirm your password"
            bind:value={formData.password_confirmation}
          />
          {#if fieldErrors.password_confirmation}
            <label class="label">
              <span class="label-text-alt text-error">{fieldErrors.password_confirmation}</span>
            </label>
          {/if}
        </div>
      </div>

      <div>
        <button
          type="submit"
          disabled={loading}
          class="btn btn-success w-full"
        >
          {#if loading}
            <span class="loading loading-spinner loading-sm"></span>
            Creating account...
          {:else}
            Create account
          {/if}
        </button>
      </div>
    </form>
  </div>
</div>

<!-- Toast Component -->
<Toast /> 