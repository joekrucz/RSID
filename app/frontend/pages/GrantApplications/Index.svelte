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

  function formatDateToDay(value) {
    if (!value) return '';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '';
    return date.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
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
                class="btn btn-sm {currentView === 'list' ? 'bg-gray-200 text-gray-900 border-gray-200' : 'btn-outline border-gray-300 text-gray-700'}"
                onclick={() => switchView('list')}
              >
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16"></path>
                </svg>
                List
              </button>
              <button 
                class="btn btn-sm {currentView === 'pipeline' ? 'bg-gray-200 text-gray-900 border-gray-200' : 'btn-outline border-gray-300 text-gray-700'}"
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
      
    </div>
    
    <!-- Applications Content -->
    {#if currentView === 'list'}
      <!-- List View -->
      
      <!-- Top Pagination Controls -->
      {#if pagination && pagination.total_pages > 1}
        <div class="flex flex-col sm:flex-row justify-between items-center gap-4 mb-6 p-4 bg-base-100 rounded-lg border border-base-300">
          <!-- Pagination Info -->
          <div class="text-sm text-base-content/70">
            Showing {((pagination.current_page - 1) * pagination.per_page) + 1} to {Math.min(pagination.current_page * pagination.per_page, pagination.total_count)} of {pagination.total_count} applications
          </div>
          
          <!-- Pagination Navigation -->
          <div class="flex items-center space-x-2">
            <!-- Previous Button -->
            <button 
              class="btn btn-sm btn-outline border-gray-300 text-gray-700"
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
                  class="btn btn-sm {page === pagination.current_page ? 'bg-gray-200 text-gray-900 border-gray-200' : 'btn-outline border-gray-300 text-gray-700'}"
                  onclick={() => goToPage(page)}
                >
                  {page}
                </button>
              {/each}
            </div>
            
            <!-- Next Button -->
            <button 
              class="btn btn-sm btn-outline border-gray-300 text-gray-700"
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
                            class="text-base-content hover:underline"
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
                          class="text-base-content hover:underline"
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
                          class="text-base-content hover:underline"
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
                    <span class="text-sm" title={formatStageLabel(application.stage)}>
                      {formatStageLabel(application.stage)}
                    </span>
                  </td>
                  <td>
                    <div class="text-sm">
                      {application.grant_competition?.deadline ? formatDateToDay(application.grant_competition.deadline) : 'No deadline set'}
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
              class="btn btn-sm btn-outline border-gray-300 text-gray-700"
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
                  class="btn btn-sm {page === pagination.current_page ? 'bg-gray-200 text-gray-900 border-gray-200' : 'btn-outline border-gray-300 text-gray-700'}"
                  onclick={() => goToPage(page)}
                >
                  {page}
                </button>
              {/each}
            </div>
            
            <!-- Next Button -->
            <button 
              class="btn btn-sm btn-outline border-gray-300 text-gray-700"
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