<script>
  import Layout from '../../components/Layout.svelte';
  import { router } from '@inertiajs/svelte';
  
  let { user, stats, recent_activity, content_summaries, storage_overview } = $props();
  
  function getFileIcon(fileType) {
    switch (fileType) {
      case 'image': return '🖼️';
      case 'document': return '📄';
      case 'spreadsheet': return '📊';
      case 'presentation': return '📈';
      case 'archive': return '📦';
      case 'video': return '🎥';
      case 'audio': return '🎵';
      case 'code': return '💻';
      default: return '📁';
    }
  }
  
  function getPriorityColor(priority) {
    switch (priority) {
      case 'high': return 'badge-error';
      case 'medium': return 'badge-warning';
      case 'low': return 'badge-success';
      default: return 'badge-neutral';
    }
  }
  
  function getCategoryColor(category) {
    switch (category) {
      case 'personal': return 'badge-primary';
      case 'work': return 'badge-secondary';
      case 'projects': return 'badge-accent';
      default: return 'badge-neutral';
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
</script>

<svelte:head>
  <title>Dashboard - RSID App</title>
</svelte:head>

<Layout {user} currentPage="dashboard">
  {#snippet children()}
    <!-- Welcome Section -->
    <div class="mb-8">
      <h1 class="text-4xl font-bold text-base-content mb-2">Welcome back, {user.name}! 👋</h1>
      <p class="text-base-content/70">Here's what's happening with your productivity today.</p>
    </div>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-primary">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
          </svg>
        </div>
        <div class="stat-title">Notes</div>
        <div class="stat-value text-primary">{stats.notes}</div>
        <div class="stat-desc">Total notes created</div>
      </div>
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-secondary">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path>
          </svg>
        </div>
        <div class="stat-title">Todos</div>
        <div class="stat-value text-secondary">{stats.todos}</div>
        <div class="stat-desc">{stats.active_todos} active, {stats.completed_todos} completed</div>
      </div>
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-accent">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path>
          </svg>
        </div>
        <div class="stat-title">Files</div>
        <div class="stat-value text-accent">{stats.files}</div>
        <div class="stat-desc">{storage_overview.total_storage} used</div>
      </div>
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-info">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
          </svg>
        </div>
        <div class="stat-title">Progress</div>
        <div class="stat-value text-info">{stats.completion_rate}%</div>
        <div class="stat-desc">Todo completion rate</div>
      </div>
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-success">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
          </svg>
        </div>
        <div class="stat-title">Clients</div>
        <div class="stat-value text-success">{stats.clients}</div>
        <div class="stat-desc">Total clients</div>
      </div>
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-warning">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
          </svg>
        </div>
        <div class="stat-title">Grant Applications</div>
        <div class="stat-value text-warning">{stats.grant_applications}</div>
        <div class="stat-desc">{stats.grant_applications_draft} draft, {stats.grant_applications_submitted} submitted</div>
      </div>
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-error">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"></path>
          </svg>
        </div>
        <div class="stat-title">R&D Projects</div>
        <div class="stat-value text-error">{stats.rnd_projects}</div>
        <div class="stat-desc">{stats.rnd_projects_draft} draft, {stats.rnd_projects_ready_for_claim} ready</div>
      </div>
    </div>

    <!-- Content Summaries -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
      <!-- Notes Summary -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            Notes Summary
          </h2>
          
          <div class="stats stats-vertical shadow">
            <div class="stat">
              <div class="stat-title">Total Notes</div>
              <div class="stat-value text-primary">{content_summaries.notes.total}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">This Week</div>
              <div class="stat-value text-secondary">{content_summaries.notes.created_this_week}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Most Recent</div>
              <div class="stat-value text-accent text-lg">{content_summaries.notes.recent}</div>
            </div>
          </div>
          
          <div class="card-actions justify-end">
            <button onclick={() => navigateTo('/notes')} class="btn btn-primary btn-sm">View All Notes</button>
          </div>
        </div>
      </div>

      <!-- Todos Summary -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path>
            </svg>
            Todos Summary
          </h2>
          
          <div class="stats stats-vertical shadow">
            <div class="stat">
              <div class="stat-title">Active</div>
              <div class="stat-value text-warning">{content_summaries.todos.active}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Completed Today</div>
              <div class="stat-value text-success">{content_summaries.todos.completed_today}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Overdue</div>
              <div class="stat-value text-error">{content_summaries.todos.overdue}</div>
            </div>
          </div>
          
          <div class="card-actions justify-end">
            <button onclick={() => navigateTo('/todos')} class="btn btn-primary btn-sm">View All Todos</button>
          </div>
        </div>
      </div>

      <!-- Files Summary -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path>
            </svg>
            Files Summary
          </h2>
          
          <div class="stats stats-vertical shadow">
            <div class="stat">
              <div class="stat-title">Total Files</div>
              <div class="stat-value text-primary">{content_summaries.files.total}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Storage Used</div>
              <div class="stat-value text-secondary">{content_summaries.files.storage_used}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Categories</div>
              <div class="stat-value text-accent text-lg">
                {#each Object.entries(content_summaries.files.by_category) as [category, count]}
                  <span class="badge {getCategoryColor(category)} mr-1">{category}: {count}</span>
                {/each}
              </div>
            </div>
          </div>
          
          <div class="card-actions justify-end">
            <button onclick={() => navigateTo('/file_items')} class="btn btn-primary btn-sm">View All Files</button>
          </div>
        </div>
      </div>

      <!-- Grant Applications Summary -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            Grant Applications Summary
          </h2>
          
          <div class="stats stats-vertical shadow">
            <div class="stat">
              <div class="stat-title">Total Applications</div>
              <div class="stat-value text-primary">{stats.grant_applications}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Draft</div>
              <div class="stat-value text-warning">{stats.grant_applications_draft}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Overdue</div>
              <div class="stat-value text-error">{stats.grant_applications_overdue}</div>
            </div>
          </div>
          
          <div class="card-actions justify-end">
            <button onclick={() => navigateTo('/grant_applications')} class="btn btn-primary btn-sm">View All Applications</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Activity -->
    <div class="card bg-base-100 shadow-xl mb-8">
      <div class="card-body">
        <h2 class="card-title">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
          </svg>
          Recent Activity
        </h2>
        
        <div class="space-y-4">
          <!-- Recent Notes -->
          {#if recent_activity.notes.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">📝 Recent Notes</h3>
              <div class="space-y-2">
                {#each recent_activity.notes as note}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div>
                      <div class="font-medium">{note.title}</div>
                      <div class="text-sm text-base-content/70">{note.content}</div>
                      <div class="text-xs text-base-content/50">{note.created_at}</div>
                    </div>
                    <button onclick={() => navigateTo('/notes')} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          <!-- Recent Todos -->
          {#if recent_activity.todos.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">✅ Recent Todos</h3>
              <div class="space-y-2">
                {#each recent_activity.todos as todo}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div class="flex items-center gap-3">
                      <input type="checkbox" checked={todo.completed} disabled class="checkbox checkbox-sm" />
                      <div>
                        <div class="font-medium {todo.completed ? 'line-through opacity-60' : ''}">{todo.title}</div>
                        <div class="text-sm text-base-content/70">
                          {#if todo.priority}
                            <span class="badge {getPriorityColor(todo.priority)} mr-2">{todo.priority}</span>
                          {/if}
                          {#if todo.due_date}
                            <span class="text-xs">Due: {todo.due_date}</span>
                          {/if}
                        </div>
                      </div>
                    </div>
                    <button onclick={() => navigateTo('/todos')} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          <!-- Recent Files -->
          {#if recent_activity.files.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">📁 Recent Files</h3>
              <div class="space-y-2">
                {#each recent_activity.files as file}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div class="flex items-center gap-3">
                      <div class="text-2xl">{getFileIcon(file.file_type)}</div>
                      <div>
                        <div class="font-medium">{file.name}</div>
                        <div class="text-sm text-base-content/70">
                          <span class="badge {getCategoryColor(file.category)} mr-2">{file.category}</span>
                          {file.file_size} • {file.file_type}
                        </div>
                      </div>
                    </div>
                    <button onclick={() => navigateTo('/file_items')} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          <!-- Recent Grant Applications -->
          {#if recent_activity.grant_applications && recent_activity.grant_applications.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">📋 Recent Grant Applications</h3>
              <div class="space-y-2">
                {#each recent_activity.grant_applications as application}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div class="flex items-center gap-3">
                      <div class="text-2xl">📄</div>
                      <div>
                        <div class="font-medium">{application.title}</div>
                        <div class="text-sm text-base-content/70">
                          <span class="badge {application.status_color} mr-2">{application.status}</span>
                          {#if application.deadline}
                            <span class="text-xs">Deadline: {application.deadline}</span>
                          {/if}
                        </div>
                      </div>
                    </div>
                    <button onclick={() => navigateTo(`/grant_applications/${application.id}`)} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          <!-- Recent R&D Projects -->
          {#if recent_activity.rnd_projects && recent_activity.rnd_projects.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">🔬 Recent R&D Projects</h3>
              <div class="space-y-2">
                {#each recent_activity.rnd_projects as project}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div class="flex items-center gap-3">
                      <div class="text-2xl">🧪</div>
                      <div>
                        <div class="font-medium">{project.title}</div>
                        <div class="text-sm text-base-content/70">
                          <span class="badge {project.status_color} mr-2">{project.status}</span>
                          <span class="text-xs">£{project.total_expenditure}</span>
                        </div>
                      </div>
                    </div>
                    <button onclick={() => navigateTo(`/rnd_projects/${project.id}`)} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          <!-- Recent Clients -->
          {#if recent_activity.clients && recent_activity.clients.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">👥 Recent Clients</h3>
              <div class="space-y-2">
                {#each recent_activity.clients as client}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div class="flex items-center gap-3">
                      <div class="text-2xl">👤</div>
                      <div>
                        <div class="font-medium">{client.name}</div>
                        <div class="text-sm text-base-content/70">
                          <span class="badge badge-outline mr-2">{client.sector}</span>
                          {client.company}
                        </div>
                      </div>
                    </div>
                    <button onclick={() => navigateTo('/people')} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          {#if recent_activity.notes.length === 0 && recent_activity.todos.length === 0 && recent_activity.files.length === 0 && (!recent_activity.clients || recent_activity.clients.length === 0) && (!recent_activity.grant_applications || recent_activity.grant_applications.length === 0)}
            <div class="text-center py-8">
              <div class="text-4xl mb-4">🚀</div>
              <h3 class="text-lg font-semibold mb-2">No recent activity</h3>
              <p class="text-base-content/70">Start creating notes, todos, uploading files, and managing grant applications to see your activity here!</p>
            </div>
          {/if}
        </div>
      </div>
    </div>

    <!-- Storage Overview -->
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4"></path>
          </svg>
          Storage Overview
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Storage Stats -->
          <div>
            <h3 class="text-lg font-semibold mb-4">Storage Statistics</h3>
            <div class="stats stats-vertical shadow">
              <div class="stat">
                <div class="stat-title">Total Files</div>
                <div class="stat-value text-primary">{storage_overview.total_files}</div>
              </div>
              
              <div class="stat">
                <div class="stat-title">Total Storage</div>
                <div class="stat-value text-secondary">{storage_overview.total_storage}</div>
              </div>
            </div>
          </div>

          <!-- Files by Category -->
          <div>
            <h3 class="text-lg font-semibold mb-4">Files by Category</h3>
            <div class="space-y-2">
              {#each Object.entries(storage_overview.by_category) as [category, count]}
                <div class="flex items-center justify-between p-2 bg-base-200 rounded">
                  <span class="badge {getCategoryColor(category)}">{category}</span>
                  <span class="font-medium">{count} files</span>
                </div>
              {/each}
              {#if Object.keys(storage_overview.by_category).length === 0}
                <p class="text-base-content/70 text-center py-4">No files uploaded yet</p>
              {/if}
            </div>
          </div>
        </div>

        <!-- Recent Uploads -->
        {#if storage_overview.recent_uploads.length > 0}
          <div class="mt-6">
            <h3 class="text-lg font-semibold mb-4">Recent Uploads</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {#each storage_overview.recent_uploads as file}
                <div class="card bg-base-200">
                  <div class="card-body p-4">
                    <div class="flex items-center gap-3">
                      <div class="text-2xl">{getFileIcon(file.file_type)}</div>
                      <div class="flex-1">
                        <div class="font-medium text-sm">{file.name}</div>
                        <div class="text-xs text-base-content/70">{file.file_size}</div>
                      </div>
                    </div>
                  </div>
                </div>
              {/each}
            </div>
          </div>
        {/if}

        <div class="card-actions justify-end">
                      <button onclick={() => navigateTo('/file_items')} class="btn btn-primary">Manage Files</button>
        </div>
      </div>
    </div>
  {/snippet}
</Layout> 