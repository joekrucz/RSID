<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Input from '../../components/forms/Input.svelte';
  import CompanySelector from '../../components/forms/CompanySelector.svelte';
  import CompetitionSelector from '../../components/forms/CompetitionSelector.svelte';
  
  let { user, grant_application, companies = [], competitions = [], errors = {} } = $props();
  
  let title = $state(grant_application.title || '');
  let description = $state(grant_application.description || '');
  let selectedCompany = $state(grant_application.company || null);
  let selectedCompetition = $state(grant_application.grant_competition || null);
  let loading = $state(false);
  
  function handleSubmit() {
    if (!title.trim() || !description.trim()) {
      toast.error('Please fill in all required fields.');
      return;
    }
    
    loading = true;
    router.put(`/grant_applications/${grant_application.id}`, {
      grant_application: {
        title: title.trim(),
        description: description.trim(),
        company_id: selectedCompany?.id || null,
        grant_competition_id: selectedCompetition?.id || null
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
    router.visit(`/grant_applications/${grant_application.id}`);
  }
</script>

<Layout {user}>
    <div class="max-w-2xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <Button variant="secondary" onclick={goBack} class="mb-4">
          ← Back to Application
        </Button>
        
        <h1 class="text-3xl font-bold text-base-content mb-2">Edit Grant Application</h1>
        <p class="text-base-content/70">Update your grant application details</p>
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
            
            
            <!-- Company Selection -->
            <div class="form-control">
              <CompanySelector
                {companies}
                bind:selectedCompany
                placeholder="Search for a company to associate with this application..."
                error={errors.company_id}
              />
              <label class="label">
                <span class="label-text-alt text-base-content/50">Optional: Associate this application with a company</span>
              </label>
            </div>
            
            <!-- Competition Selection -->
            <div class="form-control">
              <CompetitionSelector
                {competitions}
                bind:selectedCompetition
                placeholder="Search for a grant competition to associate with this application..."
                error={errors.grant_competition_id}
              />
              <label class="label">
                <span class="label-text-alt text-base-content/50">Optional: Associate this application with a grant competition</span>
              </label>
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