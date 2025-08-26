<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Toast from '../../components/Toast.svelte';
  
  let { errors = {}, email = '' } = $props();
  
  // Watch for prop changes to handle server errors
  $effect(() => {
    if (errors && Object.keys(errors).length > 0) {
      fieldErrors = errors;
      // Show error toast for login failures
      if (errors.email) {
        toast.error(errors.email);
      }
    }
  });
  
  let formData = $state({
    email: email,
    password: ''
  });
  
  let loading = $state(false);
  let fieldErrors = $state({});
  
  function handleSubmit() {
    console.log('Form submitted with:', formData);
    
    loading = true;
    fieldErrors = {};
    
    // Basic client-side validation
    const validationErrors = {};
    
    if (!formData.email) {
      validationErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      validationErrors.email = 'Please enter a valid email address';
    }
    
    if (!formData.password) {
      validationErrors.password = 'Password is required';
    }
    
    if (Object.keys(validationErrors).length > 0) {
      fieldErrors = validationErrors;
      loading = false;
      return;
    }
    
    console.log('Sending POST to /login with:', formData);
    router.post('/login', formData, {
      preserveState: false,
      onSuccess: () => {
        loading = false;
      },
      onError: (errors) => {
        loading = false;
        fieldErrors = errors;
      },
      onFinish: () => {
        loading = false;
      }
    });
  }
  
  function handleKeyPress(event) {
    // Check if Enter key was pressed
    if (event.key === 'Enter') {
      // Only attempt login if both fields have content
      if (formData.email.trim() && formData.password.trim()) {
        handleSubmit();
      }
    }
  }
</script>

<svelte:head>
  <title>Login - RSID App</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-primary/10 to-secondary/10 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
  <div class="max-w-md w-full space-y-8">
    <div>
      <h2 class="mt-6 text-center text-3xl font-extrabold text-base-content">
        Sign in to your account
      </h2>
      <p class="mt-2 text-center text-sm text-base-content/70">
        Or
        <a href="/signup" class="font-medium text-primary hover:text-primary-focus">
          create a new account
        </a>
      </p>
    </div>
    
    <!-- Global Error Alert -->
    {#if errors.email}
      <div class="alert alert-error">
        <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span>{errors.email}</span>
      </div>
    {/if}
    
    <div class="mt-8 space-y-6">
      <div class="space-y-4">
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
            onkeypress={handleKeyPress}
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
            onkeypress={handleKeyPress}
          />
          {#if fieldErrors.password}
            <label class="label">
              <span class="label-text-alt text-error">{fieldErrors.password}</span>
            </label>
          {/if}
        </div>
      </div>

      <div>
        <button
          type="button"
          disabled={loading}
          class="btn btn-primary w-full"
          onclick={handleSubmit}
        >
          {#if loading}
            <span class="loading loading-spinner loading-sm"></span>
            Signing in...
          {:else}
            Sign in
          {/if}
        </button>
      </div>
    </div>
  </div>
</div>

<!-- Toast Component -->
<Toast /> 