<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../../stores/toast.js';
  import Layout from '../../../components/Layout.svelte';
  import Button from '../../../components/forms/Button.svelte';
  
  let { user, feature_flags } = $props();
  
  function toggleFeature(featureId, enabled) {
    router.patch(`/admin/feature_flags/${featureId}`, {
      feature_flag: { enabled: !enabled }
    }, {
      onSuccess: () => {
        toast.success('Feature flag updated successfully!');
      },
      onError: () => {
        toast.error('Failed to update feature flag.');
      }
    });
  }
  
  function deleteFeature(featureId, featureName) {
    if (confirm(`Are you sure you want to delete "${featureName}"? This action cannot be undone.`)) {
      router.delete(`/admin/feature_flags/${featureId}`, {
        onSuccess: () => {
          toast.success('Feature flag deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete feature flag.');
        }
      });
    }
  }
  
  function navigateTo(path) {
    router.visit(path, {
      onSuccess: () => {
        window.location.reload();
      }
    });
  }
  
  function getStatusBadgeClass(enabled) {
    return enabled ? 'badge-success' : 'badge-neutral';
  }
</script>

<svelte:head>
  <title>Feature Flags - RSID App</title>
</svelte:head>

<Layout {user}>
  <!-- Header -->
  <div class="mb-8">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-3xl font-bold text-base-content mb-2">Feature Flags</h1>
        <p class="text-base-content/70">Manage feature access for different user roles</p>
      </div>
      <Button variant="primary" onclick={() => navigateTo('/admin/feature_flags/new')}>
        <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
        </svg>
        New Feature Flag
      </Button>
    </div>
  </div>
  
  <!-- Feature Flags List -->
  <div class="grid gap-4">
    {#each feature_flags as flag}
      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <div class="flex justify-between items-center">
            <div class="flex-1">
              <div class="flex items-center gap-3 mb-2">
                <h3 class="card-title">{flag.display_name}</h3>
                <div class="badge {getStatusBadgeClass(flag.enabled)}">
                  {flag.enabled ? 'Enabled' : 'Disabled'}
                </div>
              </div>
              <p class="text-base-content/70 mb-2">{flag.description}</p>
              <div class="text-sm text-base-content/50">
                <span class="mr-4">Created: {flag.created_at}</span>
                <span>Updated: {flag.updated_at}</span>
              </div>
            </div>
            
            <div class="flex gap-2">
              <label class="swap swap-flip">
                <input 
                  type="checkbox" 
                  checked={flag.enabled}
                  onchange={() => toggleFeature(flag.id, flag.enabled)}
                />
                <div class="swap-on">ON</div>
                <div class="swap-off">OFF</div>
              </label>
              
              <Button 
                variant="secondary" 
                size="sm"
                onclick={() => navigateTo(`/admin/feature_flags/${flag.id}/edit`)}
              >
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                </svg>
                Manage Access
              </Button>
              
              <Button 
                variant="error" 
                size="sm"
                onclick={() => deleteFeature(flag.id, flag.display_name)}
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                </svg>
              </Button>
            </div>
          </div>
        </div>
      </div>
    {/each}
    
    {#if feature_flags.length === 0}
      <div class="card bg-base-100 shadow">
        <div class="card-body text-center">
          <h3 class="text-lg font-semibold text-base-content mb-2">No Feature Flags</h3>
          <p class="text-base-content/70 mb-4">Create your first feature flag to start controlling feature access.</p>
          <Button variant="primary" onclick={() => navigateTo('/admin/feature_flags/new')}>
            Create Feature Flag
          </Button>
        </div>
      </div>
    {/if}
  </div>
</Layout>
