<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Input from '../../components/forms/Input.svelte';
  import Select from '../../components/forms/Select.svelte';
  import Checklist from '../../components/Checklist.svelte';
  
  let { user, rnd_claim, expenditures, projects = [], can_edit, can_add_expenditures, can_add_projects } = $props();
  
  const stages = [
    'upcoming',
    'readying_for_delivery',
    'in_progress',
    'finalised',
    'filed_awaiting_hmrc',
    'claim_processed',
    'client_invoiced',
    'paid'
  ];
  
  let activeTab = $state('overview');
  let currentStage = $state(rnd_claim.stage || 'upcoming');
  let stageLoading = $state(false);
  let showAddExpenditure = $state(false);
  let newExpenditure = $state({
    expenditure_type: '',
    amount: '',
    description: '',
    date: ''
  });
  let showAddProject = $state(false);
  let newProject = $state({
    name: '',
    qualification_status: 'qualified',
    narrative_status: 'skip'
  });
  let loading = $state(false);
  const idxCurrent = $derived(stages.indexOf(currentStage));

  const stageStyles = {
    upcoming: { inactive: 'bg-secondary/20 text-secondary', active: 'bg-secondary text-secondary-content', complete: 'bg-secondary text-secondary-content', fillInactive: 'fill-secondary/20', fillActive: 'fill-secondary', fillComplete: 'fill-secondary' },
    readying_for_delivery: { inactive: 'bg-warning/20 text-warning', active: 'bg-warning text-warning-content', complete: 'bg-warning text-warning-content', fillInactive: 'fill-warning/20', fillActive: 'fill-warning', fillComplete: 'fill-warning' },
    in_progress: { inactive: 'bg-info/20 text-info', active: 'bg-info text-info-content', complete: 'bg-info text-info-content', fillInactive: 'fill-info/20', fillActive: 'fill-info', fillComplete: 'fill-info' },
    finalised: { inactive: 'bg-primary/20 text-primary', active: 'bg-primary text-primary-content', complete: 'bg-primary text-primary-content', fillInactive: 'fill-primary/20', fillActive: 'fill-primary', fillComplete: 'fill-primary' },
    filed_awaiting_hmrc: { inactive: 'bg-accent/20 text-accent', active: 'bg-accent text-accent-content', complete: 'bg-accent text-accent-content', fillInactive: 'fill-accent/20', fillActive: 'fill-accent', fillComplete: 'fill-accent' },
    claim_processed: { inactive: 'bg-neutral/20 text-neutral', active: 'bg-neutral text-neutral-content', complete: 'bg-neutral text-neutral-content', fillInactive: 'fill-neutral/20', fillActive: 'fill-neutral', fillComplete: 'fill-neutral' },
    client_invoiced: { inactive: 'bg-base-content/20 text-base-content', active: 'bg-base-content text-base-100', complete: 'bg-base-content text-base-100', fillInactive: 'fill-base-content/20', fillActive: 'fill-base-content', fillComplete: 'fill-base-content' },
    paid: { inactive: 'bg-success/20 text-success', active: 'bg-success text-success-content', complete: 'bg-success text-success-content', fillInactive: 'fill-success/20', fillActive: 'fill-success', fillComplete: 'fill-success' }
  };
  
  function handleStageChange(targetStage) {
    if (targetStage === currentStage) return;
    stageLoading = true;
    
    fetch(`/rnd_claims/${rnd_claim.id}/change_stage`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ stage: targetStage })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        currentStage = targetStage;
        toast.success(data.message || 'Stage updated successfully!');
        // Reload the page to get updated data
        router.reload();
      } else {
        toast.error(data.message || 'Failed to update stage.');
      }
    })
    .catch(error => {
      console.error('Error updating stage:', error);
      toast.error('Failed to update stage.');
    })
    .finally(() => {
      stageLoading = false;
    });
  }
  
  function goBack() {
    router.visit('/rnd_claims');
  }
  
  function handleAddExpenditure() {
    loading = true;
    
    router.post(`/rnd_claims/${rnd_claim.id}/rnd_claim_expenditures`, newExpenditure, {
      onSuccess: () => {
        toast.success('Expenditure added successfully!');
        showAddExpenditure = false;
        newExpenditure = { expenditure_type: '', amount: '', description: '', date: '' };
        loading = false;
      },
      onError: () => {
        toast.error('Failed to add expenditure. Please check the form and try again.');
        loading = false;
      }
    });
  }
  
  function deleteExpenditure(expenditureId) {
    if (confirm('Are you sure you want to delete this expenditure? This action cannot be undone.')) {
      router.delete(`/rnd_claims/${rnd_claim.id}/rnd_claim_expenditures/${expenditureId}`, {
        onSuccess: () => {
          toast.success('Expenditure deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete expenditure.');
        }
      });
    }
  }
  
  function handleAddProject() {
    loading = true;
    
    router.post(`/rnd_claims/${rnd_claim.id}/rnd_claim_projects`, newProject, {
      onSuccess: () => {
        toast.success('Project added successfully!');
        showAddProject = false;
        newProject = { name: '', qualification_status: 'qualified', narrative_status: 'skip' };
        loading = false;
      },
      onError: () => {
        toast.error('Failed to add project. Please check the form and try again.');
        loading = false;
      }
    });
  }
  
  function deleteProject(projectId) {
    if (confirm('Are you sure you want to delete this project? This action cannot be undone.')) {
      router.delete(`/rnd_claims/${rnd_claim.id}/rnd_claim_projects/${projectId}`, {
        onSuccess: () => {
          toast.success('Project deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete project.');
        }
      });
    }
  }
  
  function navigateTo(path) {
    router.visit(path);
  }
  
  
  function getExpenditureTypeDisplayName(type) {
    return type.replace(/\b\w/g, l => l.toUpperCase());
  }
  
  function formatCurrency(amount) {
    return new Intl.NumberFormat('en-GB', {
      style: 'currency',
      currency: 'GBP'
    }).format(amount || 0);
  }
  
  function calculateTotalQualifyingAmount() {
    return expenditures.reduce((total, exp) => total + exp.qualifying_amount, 0);
  }
  
  function calculateExpenditureByType() {
    const byType = {};
    expenditures.forEach(exp => {
      if (!byType[exp.expenditure_type]) {
        byType[exp.expenditure_type] = 0;
      }
      byType[exp.expenditure_type] += exp.amount;
    });
    return byType;
  }
</script>

<svelte:head>
  <title>{rnd_claim.title} - R&D Project - RSID App</title>
</svelte:head>

<Layout {user}>
  <!-- Sticky Header Section -->
  <div class="sticky top-0 z-10 bg-base-200/95 backdrop-blur-sm border-b border-base-300 pb-4">
    <!-- Header -->
    <div class="mb-8">
      <div class="flex items-center justify-between mb-4">
        <div>
          <button onclick={goBack} class="btn btn-ghost btn-sm mb-2">
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
            </svg>
            Back to R&D Claims
          </button>
          <div class="flex items-center space-x-4">
            <h1 class="text-3xl font-bold text-base-content">{rnd_claim.title}</h1>
          </div>
          <p class="text-base-content/70 mt-2">R&D Project for {rnd_claim.company?.name || 'No Company'}</p>
        </div>
        {#if can_edit}
          <div class="flex space-x-2">
            <Button variant="secondary" onclick={() => navigateTo(`/rnd_claims/${rnd_claim.id}/edit`)}>
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
              </svg>
              Edit Project
            </Button>
          </div>
        {/if}
      </div>
    </div>
    
    <!-- Stages -->
    {#key currentStage}
    <div class="mt-2 w-full">
      <ul class="flex items-stretch w-full gap-0">
        {#each stages as s, i}
          {@const isComplete = idxCurrent > i}
          {@const isActive = idxCurrent === i}
          {@const palette = stageStyles[s] || { inactive: 'bg-base-300 text-base-content', active: 'bg-base-content text-base-100', complete: 'bg-base-content text-base-100', fillInactive: 'fill-base-300', fillActive: 'fill-base-content', fillComplete: 'fill-base-content' }}
          <li class="relative flex items-stretch flex-1 min-w-0">
            <button
              class={`h-6 px-2 rounded-l-md w-full ${isComplete ? palette.complete : isActive ? palette.active : palette.inactive}`}
              disabled={stageLoading}
              onclick={() => handleStageChange(s)}
              title={s.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
              aria-current={currentStage === s ? 'step' : undefined}
            >
              <span class="sr-only">{s.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}</span>
            </button>
            {#if i < stages.length - 1}
              <svg class="h-6 w-2 -ml-px" viewBox="0 0 14 32" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                <polygon points="0,0 14,16 0,32" class={isComplete ? palette.fillComplete : isActive ? palette.fillActive : palette.fillInactive} />
              </svg>
            {/if}
          </li>
        {/each}
      </ul>
      {#if stageLoading}
        <span class="loading loading-spinner loading-xs align-middle ml-2"></span>
      {/if}
    </div>
    {/key}
    
    <!-- Tabs -->
    <div class="bg-base-100 rounded-lg shadow border border-base-300 mb-6">
      <div class="tabs tabs-boxed p-2">
        <button 
          class="tab {activeTab === 'overview' ? 'tab-active' : ''}"
          onclick={() => activeTab = 'overview'}
        >
          Overview
        </button>
        <button 
          class="tab {activeTab === 'checklist' ? 'tab-active' : ''}"
          onclick={() => activeTab = 'checklist'}
        >
          Checklist
        </button>
        <button 
          class="tab {activeTab === 'projects' ? 'tab-active' : ''}"
          onclick={() => activeTab = 'projects'}
        >
          Projects
        </button>
        <button 
          class="tab {activeTab === 'narrative' ? 'tab-active' : ''}"
          onclick={() => activeTab = 'narrative'}
        >
          Narrative
        </button>
        <button 
          class="tab {activeTab === 'expenditure' ? 'tab-active' : ''}"
          onclick={() => activeTab = 'expenditure'}
        >
          Expenditure
        </button>
      </div>
    </div>
  </div>

  <!-- Tab Content -->
    <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
      {#if activeTab === 'overview'}
        <div class="space-y-6">
          <!-- Project Overview -->
          <div>
            <h3 class="text-lg font-semibold text-base-content mb-4">Project Overview</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h4 class="font-medium text-base-content mb-2">Description</h4>
                <p class="text-base-content/70 whitespace-pre-wrap">{rnd_claim.description}</p>
              </div>
              
              <div>
                <h4 class="font-medium text-base-content mb-2">Timeline</h4>
                <div class="space-y-2">
                  <div>
                    <span class="text-sm text-base-content/50">Start Date:</span>
                    <div class="font-medium">{rnd_claim.start_date}</div>
                  </div>
                  <div>
                    <span class="text-sm text-base-content/50">End Date:</span>
                    <div class="font-medium">{rnd_claim.end_date}</div>
                  </div>
                  <div>
                    <span class="text-sm text-base-content/50">Duration:</span>
                    <div class="font-medium">{rnd_claim.duration_days} days</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- R&D Activities & Challenges -->
          <div>
            <h3 class="text-lg font-semibold text-base-content mb-4">R&D Activities & Challenges</h3>
            
            <div class="space-y-6">
              <div>
                <h4 class="font-medium text-base-content mb-2">Qualifying R&D Activities</h4>
                <p class="text-base-content/70 whitespace-pre-wrap">{rnd_claim.qualifying_activities}</p>
              </div>
              
              <div>
                <h4 class="font-medium text-base-content mb-2">Technical Challenges</h4>
                <p class="text-base-content/70 whitespace-pre-wrap">{rnd_claim.technical_challenges}</p>
              </div>
            </div>
          </div>
        </div>
      {:else if activeTab === 'checklist'}
        <div>
          <h3 class="text-lg font-semibold text-base-content mb-4">R&D Claim Checklist</h3>
          <Checklist sections={[
            {
              title: 'General (CSM)',
              items: [
                { title: 'Kick off completed' },
                { title: 'Tax account access established' },
                { title: 'AML check completed' },
                { title: 'Letter of authority signed' }
              ]
            },
            {
              title: 'Financials (FC)',
              items: [
                { title: 'Org structure compiled and confirmed by client' },
                { title: 'Financial information received' },
                { title: 'Pipedrive updated with latest claim details' }
              ]
            },
            {
              title: 'Technicals (TC)',
              items: [
                { title: 'Project list completed' },
                { title: 'Technical narrative completed' }
              ]
            },
            {
              title: 'Finalising and filing (FC)',
              items: [
                { title: 'Apportionments completed' },
                { title: 'Calculations done' },
                { title: 'Claim report compiled' },
                { title: 'Signoff statements compiled' },
                { title: 'Amended tax docs created (Delete if N/A)' },
                { title: 'Ready for verification?' },
                { title: 'Claim verified' },
                { title: 'Claim finalised' },
                { title: 'AIF submitted' },
                { title: 'Submission pack sent to client for signoff' },
                { title: 'Claim filed' }
              ]
            }
          ]} />
        </div>
      {:else if activeTab === 'projects'}
        <div>
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-semibold text-base-content">Projects</h3>
            {#if can_add_projects}
              <Button variant="primary" onclick={() => showAddProject = !showAddProject}>
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                </svg>
                Add Project
              </Button>
            {/if}
          </div>
          
          {#if showAddProject}
            <div class="bg-base-200 rounded-lg p-4 mb-6">
              <h4 class="font-medium text-base-content mb-4">Add New Project</h4>
              
              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Project Name</span>
                  </label>
                  <Input
                    type="text"
                    placeholder="Enter project name..."
                    bind:value={newProject.name}
                  />
                </div>
                
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Qualification Status</span>
                  </label>
                  <Select
                    bind:value={newProject.qualification_status}
                    options={[
                      { value: 'qualified', label: 'Qualified' },
                      { value: 'disqualified', label: 'Disqualified' }
                    ]}
                  />
                </div>
                
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Narrative Status</span>
                  </label>
                  <Select
                    bind:value={newProject.narrative_status}
                    options={[
                      { value: 'skip', label: 'Skip' },
                      { value: 'drafting', label: 'Drafting' },
                      { value: 'drafted', label: 'Drafted' },
                      { value: 'signed_off', label: 'Signed Off' }
                    ]}
                  />
                </div>
              </div>
              
              <div class="flex justify-end space-x-2 mt-4">
                <Button variant="outline" onclick={() => showAddProject = false}>
                  Cancel
                </Button>
                <Button variant="primary" onclick={handleAddProject} disabled={loading || !newProject.name.trim()}>
                  {#if loading}
                    <span class="loading loading-spinner loading-sm"></span>
                    Adding...
                  {:else}
                    Add Project
                  {/if}
                </Button>
              </div>
            </div>
          {/if}
          
          {#if projects && projects.length > 0}
            <div class="overflow-x-auto">
              <table class="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>Project Name</th>
                    <th>Qualification Status</th>
                    <th>Narrative Status</th>
                    <th>Created</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {#each projects as project}
                    <tr>
                      <td>
                        <div class="font-medium">{project.name}</div>
                      </td>
                      <td>
                        <div class={`badge ${project.qualification_status === 'qualified' ? 'badge-success' : 'badge-error'}`}>
                          {project.qualification_status_display}
                        </div>
                      </td>
                      <td>
                        <div class={`badge ${
                          project.narrative_status === 'skip' ? 'badge-neutral' :
                          project.narrative_status === 'drafting' ? 'badge-warning' :
                          project.narrative_status === 'drafted' ? 'badge-info' :
                          'badge-success'
                        }`}>
                          {project.narrative_status_display}
                        </div>
                      </td>
                      <td class="text-sm text-base-content/70">{project.created_at}</td>
                      <td>
                        {#if can_add_projects}
                          <button
                            onclick={() => deleteProject(project.id)}
                            class="btn btn-ghost btn-sm text-error"
                          >
                            Delete
                          </button>
                        {/if}
                      </td>
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
          {:else}
            <div class="text-center py-8">
              <div class="text-base-content/50">
                <svg class="w-12 h-12 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
                </svg>
                <h4 class="text-lg font-medium text-base-content mb-2">No projects yet</h4>
                <p class="text-base-content/70">Add projects to track individual R&D initiatives for this claim.</p>
              </div>
            </div>
          {/if}
        </div>
      {:else if activeTab === 'narrative'}
        <div class="text-center py-12">
          <div class="text-base-content/50">
            <svg class="w-16 h-16 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            <h3 class="text-lg font-medium text-base-content mb-2">Narrative</h3>
            <p class="text-base-content/70">Narrative functionality coming soon.</p>
          </div>
        </div>
      {:else if activeTab === 'expenditure'}
        <div>
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-semibold text-base-content">Expenditures</h3>
            {#if can_add_expenditures}
              <Button variant="primary" onclick={() => showAddExpenditure = !showAddExpenditure}>
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                </svg>
                Add Expenditure
              </Button>
            {/if}
          </div>
          
          {#if showAddExpenditure}
            <div class="bg-base-200 rounded-lg p-4 mb-6">
              <h4 class="font-medium text-base-content mb-4">Add New Expenditure</h4>
              
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Type</span>
                  </label>
                  <Select
                    bind:value={newExpenditure.expenditure_type}
                    options={[
                      { value: '', label: 'Select type...' },
                      { value: 'staff', label: 'Staff' },
                      { value: 'materials', label: 'Materials' },
                      { value: 'subcontractors', label: 'Subcontractors' },
                      { value: 'software', label: 'Software' },
                      { value: 'equipment', label: 'Equipment' },
                      { value: 'utilities', label: 'Utilities' }
                    ]}
                  />
                </div>
                
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Amount (£)</span>
                  </label>
                  <Input
                    type="number"
                    step="0.01"
                    min="0"
                    placeholder="0.00"
                    bind:value={newExpenditure.amount}
                  />
                </div>
                
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Date</span>
                  </label>
                  <Input
                    type="date"
                    bind:value={newExpenditure.date}
                  />
                </div>
                
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Description</span>
                  </label>
                  <Input
                    type="text"
                    placeholder="Description of the expenditure..."
                    bind:value={newExpenditure.description}
                  />
                </div>
              </div>
              
              <div class="flex justify-end space-x-2 mt-4">
                <Button variant="outline" onclick={() => showAddExpenditure = false}>
                  Cancel
                </Button>
                <Button variant="primary" onclick={handleAddExpenditure} disabled={loading}>
                  {#if loading}
                    <span class="loading loading-spinner loading-sm"></span>
                    Adding...
                  {:else}
                    Add Expenditure
                  {/if}
                </Button>
              </div>
            </div>
          {/if}
          
          {#if expenditures && expenditures.length > 0}
            <div class="overflow-x-auto">
              <table class="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>Type</th>
                    <th>Description</th>
                    <th>Date</th>
                    <th>Amount</th>
                    <th>Qualifying</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {#each expenditures as expenditure}
                    <tr>
                      <td>
                        <div class="badge badge-outline">
                          {getExpenditureTypeDisplayName(expenditure.expenditure_type)}
                        </div>
                      </td>
                      <td>{expenditure.description}</td>
                      <td>{expenditure.date}</td>
                      <td class="font-medium">{expenditure.formatted_amount}</td>
                      <td>
                        <div class="font-medium">{expenditure.formatted_qualifying_amount}</div>
                        {#if expenditure.is_qualifying}
                          <div class="text-xs text-success">Qualifying</div>
                        {/if}
                      </td>
                      <td>
                        {#if can_add_expenditures}
                          <button
                            onclick={() => deleteExpenditure(expenditure.id)}
                            class="btn btn-ghost btn-sm text-error"
                          >
                            Delete
                          </button>
                        {/if}
                      </td>
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
          {:else}
            <div class="text-center py-8">
              <div class="text-base-content/50">
                <svg class="w-12 h-12 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"></path>
                </svg>
                <h4 class="text-lg font-medium text-base-content mb-2">No expenditures yet</h4>
                <p class="text-base-content/70">Add expenditures to track R&D costs for this project.</p>
              </div>
            </div>
          {/if}
        </div>
      {/if}
    </div>
</Layout> 