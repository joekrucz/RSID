<script>
  import { onMount } from 'svelte';
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import PipelineView from '../../components/PipelineView.svelte';
  
  let { user, grant_applications, pipeline_data, filters, stats, pagination, view_mode = 'list' } = $props();
  
  let search = $state(filters.search || '');
  let currentView = $state(view_mode);
  let currentPage = $state(pagination?.current_page || 1);
  let perPage = $state(Number(filters.per_page) || 25);
  
  // Use server-side pagination and search
  let filteredApplications = $state(grant_applications);
  let filteredPipelineData = $state(pipeline_data);
  
  // Update data when props change
  $effect(() => {
    filteredApplications = grant_applications;
    filteredPipelineData = pipeline_data;
  });
  
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
  
  function switchView(view) {
    currentView = view;
    
    // Save view preference to localStorage
    if (typeof window !== 'undefined') {
      localStorage.setItem('grant_applications_view', view);
    }
    
    // Reload with new view
    loadPage(1);
  }
  
  function loadPage(page) {
    const params = new URLSearchParams();
    if (search.trim()) params.set('search', search);
    if (perPage !== 25) params.set('per_page', String(perPage));
    if (currentView !== 'list') params.set('view', currentView);
    if (page > 1) params.set('page', page);
    
    const queryString = params.toString();
    const url = queryString ? `/grant_applications?${queryString}` : '/grant_applications';
    
    router.get(url, {}, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  let searchTimeout;
  
  function handleSearch() {
    // Clear existing timeout
    if (searchTimeout) {
      clearTimeout(searchTimeout);
    }
    
    // Debounce search to avoid too many requests
    searchTimeout = setTimeout(() => {
      loadPage(1); // Reset to first page when searching
    }, 300);
  }
  
  function handlePerPageChange(newPerPage) {
    perPage = newPerPage;
    loadPage(1); // Reset to first page when changing per page
  }
  
  function goToPage(page) {
    loadPage(page);
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

  function formatStageLabel(stage) {
    switch (stage) {
      case 'client_acquisition_project_qualification':
        return 'Client Acquisition';
      case 'client_invoiced':
        return 'Client invoiced';
      case 'invoice_paid':
        return 'Invoice paid';
      case 'preparing_for_kick_off_aml_resourcing':
        return 'KO Prep';
      case 'kicked_off_in_progress':
        return 'Kicked off';
      case 'submitted':
        return 'Submitted';
      case 'awaiting_funding_decision':
        return 'Awaiting funding decision';
      case 'application_successful_or_not_successful':
        return 'Funding Decision';
      case 'resub_due':
        return 'Resub Due';
      case 'success_fee_invoiced':
        return 'Success fee invoiced';
      case 'success_fee_paid':
        return 'Success fee paid';
      default:
        return displayLabel(stage);
    }
  }
</script>

<Layout {user}>
  <div class="max-w-7xl mx-auto">
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
      
      <!-- Search and View Toggle -->
      <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-4">
        <!-- Search Bar -->
        <div class="flex-1 max-w-md">
          <div class="flex gap-2">
            <div class="relative flex-1">
              <input
                type="text"
                placeholder="Search applications, companies, or descriptions..."
                class="input input-bordered w-full pl-10"
                bind:value={search}
                onkeyup={(e) => e.key === 'Enter' && handleSearch()}
                oninput={() => handleSearch()}
              />
              <svg class="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-base-content/50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
              </svg>
            </div>
            <button 
              class="btn btn-primary"
              onclick={handleSearch}
            >
              Search
            </button>
            {#if search.trim()}
              <button 
                class="btn btn-outline"
                onclick={() => {
                  search = '';
                  handleSearch();
                }}
                title="Clear search"
              >
                Clear
              </button>
            {/if}
          </div>
        </div>
        
        <!-- View Toggle and Per Page Selector -->
        <div class="flex items-center space-x-4">
          <!-- Per Page Selector -->
          <div class="flex items-center space-x-2">
            <span class="text-sm font-medium text-base-content">Show:</span>
            <select 
              class="select select-bordered select-sm"
              bind:value={perPage}
              onchange={() => handlePerPageChange(perPage)}
            >
              <option value={25}>25</option>
              <option value={50}>50</option>
              <option value={100}>100</option>
            </select>
          </div>
          
          <!-- View Toggle -->
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
    
    <!-- Applications Content -->
    {#if currentView === 'list'}
      <!-- List View -->
      <div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
      {#if filteredApplications.length > 0}
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Title</th>
                <th>Company</th>
                <th>Competition</th>
                <th>Stage</th>
                <th>Deadline</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {#each filteredApplications as application}
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
                    {#if application.grant_competition}
                      <div class="text-sm font-medium">
                        <a 
                          href="/grant_competitions/{application.grant_competition.id}" 
                          class="link link-primary hover:link-primary-focus"
                        >
                          {application.grant_competition.grant_name}
                        </a>
                      </div>
                      <div class="text-xs opacity-70">
                        {application.grant_competition.funding_body}
                      </div>
                    {:else}
                      <div class="text-sm opacity-50">
                        No competition
                      </div>
                    {/if}
                  </td>
                  <td>
                    <div class={`badge ${application.stage_badge_class || 'badge-neutral'} whitespace-normal min-h-6 h-auto py-1`} title={formatStageLabel(application.stage)}>
                      {formatStageLabel(application.stage)}
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
            <h3 class="text-lg font-medium text-base-content mb-2">
              {search.trim() ? 'No applications found' : 'No grant applications yet'}
            </h3>
            <p class="text-base-content/70 mb-6">
              {search.trim() 
                ? `No applications match "${search}". Try adjusting your search terms.`
                : 'Get started by creating your first grant application'
              }
            </p>
            {#if !search.trim()}
              <Button variant="primary" onclick={() => router.visit('/grant_applications/new')}>
                Create Your First Application
              </Button>
            {/if}
          </div>
        </div>
      {/if}
      </div>
      
      <!-- Pagination Controls (only for list view) -->
      {#if currentView === 'list' && pagination && pagination.total_pages > 1}
        <div class="flex flex-col sm:flex-row justify-between items-center gap-4 mt-6 p-4 bg-base-100 rounded-lg border border-base-300">
          <!-- Pagination Info -->
          <div class="text-sm text-base-content/70">
            Showing {((pagination.current_page - 1) * pagination.per_page) + 1} to {Math.min(pagination.current_page * pagination.per_page, pagination.total_count)} of {pagination.total_count} applications
          </div>
          
          <!-- Pagination Navigation -->
          <div class="flex items-center space-x-2">
            <!-- Previous Button -->
            <button 
              class="btn btn-sm btn-outline"
              disabled={!pagination.has_prev_page}
              onclick={() => goToPage(pagination.current_page - 1)}
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
              </svg>
              Previous
            </button>
            
            <!-- Page Numbers -->
            <div class="flex items-center space-x-1">
              {#each Array.from({length: Math.min(5, pagination.total_pages)}, (_, i) => {
                const startPage = Math.max(1, pagination.current_page - 2);
                const endPage = Math.min(pagination.total_pages, startPage + 4);
                const adjustedStartPage = Math.max(1, endPage - 4);
                return adjustedStartPage + i;
              }).filter(page => page <= pagination.total_pages) as page}
                <button 
                  class="btn btn-sm {page === pagination.current_page ? 'btn-primary' : 'btn-outline'}"
                  onclick={() => goToPage(page)}
                >
                  {page}
                </button>
              {/each}
            </div>
            
            <!-- Next Button -->
            <button 
              class="btn btn-sm btn-outline"
              disabled={!pagination.has_next_page}
              onclick={() => goToPage(pagination.current_page + 1)}
            >
              Next
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
              </svg>
            </button>
          </div>
        </div>
      {/if}
    {:else}
      <!-- Pipeline View -->
      <PipelineView pipeline_data={filteredPipelineData} />
    {/if}
  </div>
</Layout> 