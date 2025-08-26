<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Input from '../../components/forms/Input.svelte';
  import Select from '../../components/forms/Select.svelte';
  
  let { user, rnd_project, expenditures, can_edit, can_add_expenditures } = $props();
  
  let showAddExpenditure = $state(false);
  let newExpenditure = $state({
    expenditure_type: '',
    amount: '',
    description: '',
    date: ''
  });
  let loading = $state(false);
  
  function goBack() {
    router.visit('/rnd_projects', {
      onSuccess: () => {
        // Refresh the page after navigation
        window.location.reload();
      }
    });
  }
  
  function handleAddExpenditure() {
    loading = true;
    
    router.post(`/rnd_projects/${rnd_project.id}/rnd_expenditures`, newExpenditure, {
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
      router.delete(`/rnd_projects/${rnd_project.id}/rnd_expenditures/${expenditureId}`, {
        onSuccess: () => {
          toast.success('Expenditure deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete expenditure.');
        }
      });
    }
  }
  
  function navigateTo(path) {
    router.visit(path, {
      onSuccess: () => {
        // Refresh the page after navigation
        window.location.reload();
      }
    });
  }
  
  function getStatusBadgeClass(status) {
    switch (status) {
      case 'draft':
        return 'badge-neutral';
      case 'active':
        return 'badge-info';
      case 'completed':
        return 'badge-success';
      case 'ready_for_claim':
        return 'badge-warning';
      default:
        return 'badge-neutral';
    }
  }
  
  function getStatusDisplayName(status) {
    return status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
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
  <title>{rnd_project.title} - R&D Project - RSID App</title>
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
            Back to R&D Projects
          </button>
          <div class="flex items-center space-x-4">
            <h1 class="text-3xl font-bold text-base-content">{rnd_project.title}</h1>
            <div class="badge {getStatusBadgeClass(rnd_project.status)} badge-lg">
              {getStatusDisplayName(rnd_project.status)}
            </div>
          </div>
          <p class="text-base-content/70 mt-2">R&D Project for {rnd_project.client.name}</p>
        </div>
        {#if can_edit}
          <div class="flex space-x-2">
            <Button variant="secondary" onclick={() => navigateTo(`/rnd_projects/${rnd_project.id}/edit`)}>
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
              </svg>
              Edit Project
            </Button>
          </div>
        {/if}
      </div>
    </div>
    
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Project Details -->
      <div class="lg:col-span-2 space-y-6">
        <!-- Project Overview -->
        <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
          <h3 class="text-lg font-semibold text-base-content mb-4">Project Overview</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h4 class="font-medium text-base-content mb-2">Description</h4>
              <p class="text-base-content/70 whitespace-pre-wrap">{rnd_project.description}</p>
            </div>
            
            <div>
              <h4 class="font-medium text-base-content mb-2">Timeline</h4>
              <div class="space-y-2">
                <div>
                  <span class="text-sm text-base-content/50">Start Date:</span>
                  <div class="font-medium">{rnd_project.start_date}</div>
                </div>
                <div>
                  <span class="text-sm text-base-content/50">End Date:</span>
                  <div class="font-medium">{rnd_project.end_date}</div>
                </div>
                <div>
                  <span class="text-sm text-base-content/50">Duration:</span>
                  <div class="font-medium">{rnd_project.duration_days} days</div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- R&D Activities -->
        <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
          <h3 class="text-lg font-semibold text-base-content mb-4">R&D Activities & Challenges</h3>
          
          <div class="space-y-6">
            <div>
              <h4 class="font-medium text-base-content mb-2">Qualifying R&D Activities</h4>
              <p class="text-base-content/70 whitespace-pre-wrap">{rnd_project.qualifying_activities}</p>
            </div>
            
            <div>
              <h4 class="font-medium text-base-content mb-2">Technical Challenges</h4>
              <p class="text-base-content/70 whitespace-pre-wrap">{rnd_project.technical_challenges}</p>
            </div>
          </div>
        </div>
        
        <!-- Expenditures -->
        <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
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
      </div>
      
      <!-- Sidebar -->
      <div class="space-y-6">
        <!-- Project Stats -->
        <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
          <h3 class="text-lg font-semibold text-base-content mb-4">Project Statistics</h3>
          
          <div class="space-y-4">
            <div class="stat bg-base-200 rounded-lg p-4">
              <div class="stat-title">Total Expenditure</div>
              <div class="stat-value text-primary">{formatCurrency(rnd_project.total_expenditure)}</div>
            </div>
            
            <div class="stat bg-base-200 rounded-lg p-4">
              <div class="stat-title">Qualifying Amount</div>
              <div class="stat-value text-success">{formatCurrency(calculateTotalQualifyingAmount())}</div>
            </div>
            
            <div class="stat bg-base-200 rounded-lg p-4">
              <div class="stat-title">Expenditure Count</div>
              <div class="stat-value text-info">{expenditures.length}</div>
            </div>
          </div>
        </div>
        
        <!-- Expenditure Breakdown -->
        {#if expenditures && expenditures.length > 0}
          <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
            <h3 class="text-lg font-semibold text-base-content mb-4">Expenditure Breakdown</h3>
            
            <div class="space-y-3">
              {#each Object.entries(calculateExpenditureByType()) as [type, amount]}
                <div class="flex justify-between items-center">
                  <span class="text-sm font-medium">{getExpenditureTypeDisplayName(type)}</span>
                  <span class="text-sm font-bold">{formatCurrency(amount)}</span>
                </div>
              {/each}
            </div>
          </div>
        {/if}
        
        <!-- Project Info -->
        <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
          <h3 class="text-lg font-semibold text-base-content mb-4">Project Information</h3>
          
          <div class="space-y-3">
            <div>
              <span class="text-sm text-base-content/50">Client</span>
              <div class="font-medium">{rnd_project.client.name}</div>
              <div class="text-sm text-base-content/70">{rnd_project.client.email}</div>
            </div>
            
            <div>
              <span class="text-sm text-base-content/50">Created</span>
              <div class="font-medium">{rnd_project.created_at}</div>
            </div>
            
            <div>
              <span class="text-sm text-base-content/50">Last Updated</span>
              <div class="font-medium">{rnd_project.updated_at}</div>
            </div>
          </div>
        </div>
        
        <!-- Claim Status -->
        {#if rnd_project.can_be_claimed}
          <div class="alert alert-success">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <div>
              <h3 class="font-bold">Ready for Claim</h3>
              <div class="text-sm">This project is ready for R&D tax credit submission.</div>
            </div>
          </div>
        {/if}
      </div>
    </div>
</Layout> 