<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Input from '../../components/forms/Input.svelte';
  import Select from '../../components/forms/Select.svelte';
  
  let { user, rnd_project, clients, errors = [] } = $props();
  
  let formData = $state({
    title: rnd_project.title || '',
    description: rnd_project.description || '',
    client_id: rnd_project.client_id?.toString() || '',
    start_date: rnd_project.start_date || '',
    end_date: rnd_project.end_date || '',
    status: rnd_project.status || 'draft',
    qualifying_activities: rnd_project.qualifying_activities || '',
    technical_challenges: rnd_project.technical_challenges || ''
  });
  
  let loading = $state(false);
  
  function handleSubmit() {
    // For clients, ensure their own ID is set as the client_id
    if (user.role === 'client') {
      formData.client_id = user.id.toString();
    }
    
    // Client-side validation
    if ((user.role === 'employee' || user.role === 'admin') && !formData.client_id) {
      toast.error('Please select a client for this R&D project.');
      return;
    }
    
    loading = true;
    
    router.put(`/rnd_projects/${rnd_project.id}`, formData, {
      onSuccess: () => {
        toast.success('R&D Project updated successfully!');
        loading = false;
      },
      onError: () => {
        toast.error('Failed to update R&D Project. Please check the form and try again.');
        loading = false;
      }
    });
  }
  
  function goBack() {
    router.visit(`/rnd_projects/${rnd_project.id}`);
  }
  
  function formatCurrency(amount) {
    return new Intl.NumberFormat('en-GB', {
      style: 'currency',
      currency: 'GBP'
    }).format(amount || 0);
  }
</script>

<svelte:head>
  <title>Edit R&D Project - RSID App</title>
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
          Back to Project Details
        </button>
        <h1 class="text-3xl font-bold text-base-content mb-2">Edit R&D Project</h1>
        <p class="text-base-content/70">Update the research and development project details</p>
      </div>
    </div>
  </div>
    
  <!-- Form -->
  <div class="max-w-4xl mx-auto">
    <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit(); }}>
        <!-- Project Details -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold text-base-content mb-4">Project Details</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Project Title *</span>
              </label>
              <Input
                type="text"
                placeholder="e.g., AI-Powered Customer Analytics Platform"
                bind:value={formData.title}
                error={errors.find(e => e.includes('Title'))}
                required
              />
              <label class="label">
                <span class="label-text-alt">A clear, descriptive title for the R&D project</span>
              </label>
            </div>
            
            {#if user.role === 'employee' || user.role === 'admin'}
              <div class="form-control">
                <label class="label">
                  <span class="label-text font-medium">Client *</span>
                </label>
                <Select
                  bind:value={formData.client_id}
                  options={[
                    { value: '', label: 'Select a client...' },
                    ...clients.map(client => ({ value: client.id.toString(), label: client.name }))
                  ]}
                  error={errors.find(e => e.includes('Client'))}
                  required
                />
              </div>
            {:else}
              <div class="form-control">
                <label class="label">
                  <span class="label-text font-medium">Client</span>
                </label>
                <input
                  type="text"
                  class="input input-bordered"
                  value={user.name}
                  disabled
                />
                <label class="label">
                  <span class="label-text-alt">This project belongs to your account</span>
                </label>
              </div>
            {/if}
          </div>
          
          <div class="form-control mt-6">
            <label class="label">
              <span class="label-text font-medium">Project Description *</span>
            </label>
            <textarea
              class="textarea textarea-bordered h-24"
              placeholder="Describe the overall project, its objectives, and expected outcomes..."
              bind:value={formData.description}
              required
            ></textarea>
            <label class="label">
              <span class="label-text-alt">Provide a comprehensive description of the R&D project</span>
            </label>
            {#if errors.find(e => e.includes('Description'))}
              <label class="label">
                <span class="label-text-alt text-error">{errors.find(e => e.includes('Description'))}</span>
              </label>
            {/if}
          </div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Start Date *</span>
              </label>
              <Input
                type="date"
                bind:value={formData.start_date}
                error={errors.find(e => e.includes('Start date'))}
                required
              />
            </div>
            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">End Date *</span>
              </label>
              <Input
                type="date"
                bind:value={formData.end_date}
                error={errors.find(e => e.includes('End date'))}
                required
              />
              <label class="label">
                <span class="label-text-alt">End date must be after start date</span>
              </label>
            </div>
          </div>
          
          <div class="form-control mt-6">
            <label class="label">
              <span class="label-text font-medium">Project Status</span>
            </label>
            <Select
              bind:value={formData.status}
              options={[
                { value: 'draft', label: 'Draft' },
                { value: 'active', label: 'Active' },
                { value: 'completed', label: 'Completed' },
                { value: 'ready_for_claim', label: 'Ready for Claim' }
              ]}
            />
            <label class="label">
              <span class="label-text-alt">Current status of the R&D project</span>
            </label>
          </div>
        </div>
        
        <!-- R&D Activities -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold text-base-content mb-4">R&D Activities & Challenges</h3>
          
          <div class="form-control mb-6">
            <label class="label">
              <span class="label-text font-medium">Qualifying R&D Activities *</span>
            </label>
            <textarea
              class="textarea textarea-bordered h-32"
              placeholder="Describe the specific R&D activities that qualify for tax credits. Include:
• Scientific or technological uncertainty
• Systematic investigation
• Advancement in science or technology
• Resolution of technical challenges..."
              bind:value={formData.qualifying_activities}
              required
            ></textarea>
            <label class="label">
              <span class="label-text-alt">Detail the qualifying R&D activities that meet HMRC criteria</span>
            </label>
            {#if errors.find(e => e.includes('Qualifying activities'))}
              <label class="label">
                <span class="label-text-alt text-error">{errors.find(e => e.includes('Qualifying activities'))}</span>
              </label>
            {/if}
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text font-medium">Technical Challenges *</span>
            </label>
            <textarea
              class="textarea textarea-bordered h-32"
              placeholder="Describe the technical challenges and uncertainties faced during the project:

• What technical problems needed to be solved?
• What scientific or technological uncertainties existed?
• How were these challenges addressed?
• What was the outcome of the R&D work?..."
              bind:value={formData.technical_challenges}
              required
            ></textarea>
            <label class="label">
              <span class="label-text-alt">Explain the technical challenges and how they were resolved</span>
            </label>
            {#if errors.find(e => e.includes('Technical challenges'))}
              <label class="label">
                <span class="label-text-alt text-error">{errors.find(e => e.includes('Technical challenges'))}</span>
              </label>
            {/if}
          </div>
        </div>
        
        <!-- R&D Tax Credit Information -->
        <div class="mb-8">
          <div class="alert alert-info">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <div>
              <h3 class="font-bold">R&D Tax Credit Eligibility</h3>
              <div class="text-sm">
                <p class="mb-2">To qualify for R&D tax credits, your project must:</p>
                <ul class="list-disc list-inside space-y-1">
                  <li>Address scientific or technological uncertainty</li>
                  <li>Involve systematic investigation</li>
                  <li>Advance science or technology</li>
                  <li>Resolve technical challenges</li>
                </ul>
                <p class="mt-2">Expenditures can be managed from the project details page.</p>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Form Actions -->
        <div class="flex justify-end space-x-4">
          <Button variant="outline" onclick={goBack} type="button">
            Cancel
          </Button>
          <Button variant="primary" type="submit" disabled={loading}>
            {#if loading}
              <span class="loading loading-spinner loading-sm"></span>
              Updating...
            {:else}
              Update R&D Project
            {/if}
          </Button>
        </div>
      </form>
    </div>
  </div>
</Layout> 