<script>
  import { onMount } from 'svelte';
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Select from '../../components/forms/Select.svelte';
  import PipelineView from '../../components/PipelineView.svelte';
  
  let { user, grant_applications, pipeline_data, filters, stats, view_mode = 'list' } = $props();
  
  let search = $state(filters.search || '');
  let showFilters = $state(false);
  let currentView = $state(view_mode);
  
  // Check localStorage on mount if no explicit view parameter in URL
  onMount(() => {
    if (!window.location.search.includes('view=')) {
      const savedView = localStorage.getItem('grant_applications_view');
      if (savedView && savedView !== view_mode) {
        currentView = savedView;
        // Update the URL to reflect the saved preference
        router.get('/grant_applications', { 
          search: search || undefined,
          view: currentView
        }, {
          preserveState: true,
          preserveScroll: true,
          replace: true // Replace current history entry instead of adding new one
        });
      }
    }
  });
  
  function handleSearch() {
    router.get('/grant_applications', { 
      search: search || undefined,
      view: currentView
    }, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  function switchView(view) {
    currentView = view;
    
    // Save view preference to localStorage
    if (typeof window !== 'undefined') {
      localStorage.setItem('grant_applications_view', view);
    }
    
    router.get('/grant_applications', { 
      search: search || undefined,
      view: currentView
    }, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  function clearFilters() {
    search = '';
    router.get('/grant_applications', {}, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  function handleSubmit(applicationId) {
    if (confirm('Are you sure you want to submit this grant application? This action cannot be undone.')) {
      router.patch(`/grant_applications/${applicationId}/submit`, {}, {
        onSuccess: () => {
          toast.success('Grant application submitted successfully!');
        },
        onError: () => {
          toast.error('Failed to submit grant application.');
        }
      });
    }
  }
  
  function handleDelete(applicationId) {
    if (confirm('Are you sure you want to delete this grant application? This action cannot be undone.')) {
      router.delete(`/grant_applications/${applicationId}`, {
        onSuccess: () => {
          toast.success('Grant application deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete grant application.');
        }
      });
    }
  }
  

  
  function navigateTo(path) {
    router.visit(path);
  }

  function displayLabel(value) {
    return (value || '').replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
  }
</script>

<Layout {user}>
    <!-- Header -->
    <div class="mb-6">
      <div class="flex justify-between items-center mb-4">
        <div>
                <h1 class="text-3xl font-bold text-base-content mb-2">Grant Applications</h1>
      <p class="text-base-content/70">Track and manage your grant applications from start to finish</p>
        </div>
        <Button variant="primary" onclick={() => router.visit('/grant_applications/new')}>
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
          </svg>
          New Application
        </Button>
      </div>
      
      <!-- View Toggle -->
      <div class="flex justify-between items-center mb-4">
        <div class="flex items-center space-x-2">
          <span class="text-sm font-medium text-base-content">View:</span>
          <div class="btn-group">
            <button 
              class="btn btn-sm {currentView === 'list' ? 'btn-primary' : 'btn-outline'}"
              onclick={() => switchView('list')}
            >
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16"></path>
              </svg>
              List
            </button>
            <button 
              class="btn btn-sm {currentView === 'pipeline' ? 'btn-primary' : 'btn-outline'}"
              onclick={() => switchView('pipeline')}
            >
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2"></path>
              </svg>
              Pipeline
            </button>
          </div>
        </div>
      </div>
      
      <!-- Stats Cards -->
      <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4 mb-6">
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Total</div>
          <div class="stat-value text-primary">{stats.total}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Overdue</div>
          <div class="stat-value text-error">{stats.overdue}</div>
        </div>
      </div>
    </div>
    
    <!-- Filters -->
    <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6 mb-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-base-content">Filters</h3>
        <button 
          class="btn btn-ghost btn-sm"
          onclick={() => showFilters = !showFilters}
        >
          {showFilters ? 'Hide' : 'Show'} Filters
        </button>
      </div>
      
      {#if showFilters}
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="form-control">
            <label class="label">
              <span class="label-text">Search</span>
            </label>
            <input
              type="text"
              placeholder="Search by title or description..."
              class="input input-bordered w-full"
              bind:value={search}
              onkeyup={(e) => e.key === 'Enter' && handleSearch()}
            />
          </div>
          
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">&nbsp;</span>
            </label>
            <div class="flex space-x-2">
              <Button variant="primary" onclick={handleSearch} class="flex-1">
                Search
              </Button>
              <Button variant="secondary" onclick={clearFilters} class="flex-1">
                Clear
              </Button>
            </div>
          </div>
        </div>
      {/if}
    </div>
    
    <!-- Applications Content -->
    {#if currentView === 'list'}
      <!-- List View -->
      <div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
      {#if grant_applications.length > 0}
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Title</th>
                <th>Company</th>
                <th>Stage</th>
                <th>Deadline</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {#each grant_applications as application}
                <tr class={application.overdue ? 'bg-error/10' : ''}>
                  <td>
                    <div class="flex items-center space-x-3">
                      <div>
                        <div class="font-bold">
                          <a 
                            href="/grant_applications/{application.id}" 
                            class="link link-primary hover:link-primary-focus"
                          >
                            {application.title}
                          </a>
                        </div>
                        <div class="text-sm opacity-50 line-clamp-2">
                          {application.description}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td>
                    {#if application.company}
                      <div class="text-sm font-medium">
                        <a 
                          href="/companies/{application.company.id}" 
                          class="link link-primary hover:link-primary-focus"
                        >
                          {application.company.name}
                        </a>
                      </div>
                    {:else}
                      <div class="text-sm opacity-50">
                        No company
                      </div>
                    {/if}
                  </td>
                  <td>
                    <div class={`badge ${application.stage_badge_class || 'badge-neutral'}`} title={displayLabel(application.stage)}>
                      {displayLabel(application.stage)}
                    </div>
                  </td>
                  <td>
                    <div class="text-sm">
                      {application.deadline || 'No deadline set'}
                    </div>
                    {#if application.days_until_deadline !== null}
                      <div class="text-xs opacity-50">
                        {application.days_until_deadline > 0 
                          ? `${application.days_until_deadline} days left`
                          : application.days_until_deadline < 0 
                            ? `${Math.abs(application.days_until_deadline)} days overdue`
                            : 'Due today'
                        }
                      </div>
                    {/if}
                  </td>
                  <td>
                    <div class="flex items-center space-x-2">
                      <button 
                        onclick={() => navigateTo(`/grant_applications/${application.id}`)}
                        class="btn btn-sm btn-ghost"
                        title="View Details"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                        </svg>
                      </button>
                      {#if application.can_edit}
                        <button 
                          onclick={() => navigateTo(`/grant_applications/${application.id}/edit`)}
                          class="btn btn-sm btn-ghost"
                          title="Edit Application"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          </svg>
                        </button>
                      {/if}
                      {#if application.can_submit}
                        <button 
                          onclick={() => handleSubmit(application.id)}
                          class="btn btn-sm btn-ghost"
                          title="Submit Application"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
                          </svg>
                        </button>
                      {/if}
                      {#if application.can_edit}
                        <button 
                          onclick={() => handleDelete(application.id)}
                          class="btn btn-sm btn-ghost text-error"
                          title="Delete Application"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                          </svg>
                        </button>
                      {/if}
                    </div>
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      {:else}
        <div class="text-center py-12">
          <div class="text-base-content/50 mb-4">
            <svg class="w-16 h-16 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            <h3 class="text-lg font-medium text-base-content mb-2">No grant applications yet</h3>
            <p class="text-base-content/70 mb-6">
              Get started by creating your first grant application
            </p>
            <Button variant="primary" onclick={() => router.visit('/grant_applications/new')}>
              Create Your First Application
            </Button>
          </div>
        </div>
      {/if}
      </div>
    {:else}
      <!-- Pipeline View -->
      <PipelineView {pipeline_data} />
    {/if}
</Layout> 