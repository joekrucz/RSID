<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Select from '../../components/forms/Select.svelte';
  
  let { user, grant_applications, filters, stats } = $props();
  
  let search = $state(filters.search || '');
  let statusFilter = $state(filters.status || '');
  let showFilters = $state(false);
  
  function handleSearch() {
    router.get('/grant_applications', { 
      search: search || undefined,
      status: statusFilter || undefined
    }, {
      preserveState: true,
      preserveScroll: true
    });
  }
  
  function clearFilters() {
    search = '';
    statusFilter = '';
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
  
  function getStatusBadgeClass(status) {
    switch (status) {
      case 'draft':
        return 'badge-neutral';
      case 'submitted':
        return 'badge-info';
      case 'under_review':
        return 'badge-warning';
      case 'approved':
        return 'badge-success';
      case 'rejected':
        return 'badge-error';
      case 'completed':
        return 'badge-success';
      default:
        return 'badge-neutral';
    }
  }
  
  function getStatusDisplayName(status) {
    return status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
  }
  
  function formatDeadline(deadline) {
    if (!deadline) return 'No deadline set';
    return deadline;
  }
  
  function navigateTo(path) {
    router.visit(path);
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
      
      <!-- Stats Cards -->
      <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4 mb-6">
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Total</div>
          <div class="stat-value text-primary">{stats.total}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Draft</div>
          <div class="stat-value text-neutral">{stats.draft}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Submitted</div>
          <div class="stat-value text-info">{stats.submitted}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Under Review</div>
          <div class="stat-value text-warning">{stats.under_review}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Approved</div>
          <div class="stat-value text-success">{stats.approved}</div>
        </div>
        
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-title">Rejected</div>
          <div class="stat-value text-error">{stats.rejected}</div>
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
              <span class="label-text">Status</span>
            </label>
            <Select
              bind:value={statusFilter}
              options={[
                { value: '', label: 'All Statuses' },
                { value: 'draft', label: 'Draft' },
                { value: 'submitted', label: 'Submitted' },
                { value: 'under_review', label: 'Under Review' },
                { value: 'approved', label: 'Approved' },
                { value: 'rejected', label: 'Rejected' },
                { value: 'completed', label: 'Completed' }
              ]}
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
    
    <!-- Applications List -->
    <div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
      {#if grant_applications.length > 0}
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Title</th>
                <th>Status</th>
                <th>Deadline</th>
                <th>Documents</th>
                <th>Created</th>
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
                    <div class="badge {application.status_color}">
                      {getStatusDisplayName(application.status)}
                    </div>
                    {#if application.overdue}
                      <div class="badge badge-error badge-sm mt-1">Overdue</div>
                    {/if}
                  </td>
                  <td>
                    <div class="text-sm">
                      {formatDeadline(application.deadline)}
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
                    <div class="text-sm">
                      {application.documents_count} document{application.documents_count !== 1 ? 's' : ''}
                    </div>
                  </td>
                  <td>
                    <div class="text-sm">{application.created_at}</div>
                  </td>
                  <td>
                    <div class="dropdown dropdown-end">
                      <div tabindex="0" role="button" class="btn btn-sm btn-ghost">
                        Actions
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                        </svg>
                      </div>
                      <ul class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
                        <li>
                          <button onclick={() => navigateTo(`/grant_applications/${application.id}`)} class="w-full text-left">View Details</button>
                        </li>
                        {#if application.can_edit}
                          <li>
                            <button onclick={() => navigateTo(`/grant_applications/${application.id}/edit`)} class="w-full text-left">Edit</button>
                          </li>
                        {/if}
                        {#if application.can_submit}
                          <li>
                            <button 
                              onclick={() => handleSubmit(application.id)}
                              class="w-full text-left"
                            >
                              Submit
                            </button>
                          </li>
                        {/if}
                        {#if application.can_edit}
                          <li>
                            <button 
                              onclick={() => handleDelete(application.id)}
                              class="w-full text-left text-error"
                            >
                              Delete
                            </button>
                          </li>
                        {/if}
                      </ul>
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
</Layout> 