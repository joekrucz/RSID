<script>
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import { router } from '@inertiajs/svelte';
  
  let { user, app_state, database_stats, sample_data, controller_info, feature_flags } = $props();
  
  let activeTab = $state('app-state');
  
  function refreshData() {
    router.reload();
  }
  
  function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
</script>

<Layout {user}>
  <div class="mb-6">
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-3xl font-bold text-gray-900 mb-2">
          🔍 App Inspector
        </h1>
        <p class="text-gray-600">
          Behind-the-scenes view of the RSID application architecture and data flow
        </p>
      </div>
      <Button on:click={refreshData} variant="secondary">
        🔄 Refresh Data
      </Button>
    </div>
    
    <!-- Tab Navigation -->
    <div class="border-b border-gray-200 mb-6">
      <nav class="-mb-px flex space-x-8">
        {#each [
          { id: 'app-state', label: 'App State', icon: '⚙️' },
          { id: 'database', label: 'Database', icon: '🗄️' },
          { id: 'sample-data', label: 'Sample Data', icon: '📊' },
          { id: 'controller', label: 'Controller', icon: '🎮' },
          { id: 'features', label: 'Feature Flags', icon: '🚩' }
        ] as tab}
          <button
            class="py-2 px-1 border-b-2 font-medium text-sm {activeTab === tab.id 
              ? 'border-blue-500 text-blue-600' 
              : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
            on:click={() => activeTab = tab.id}
          >
            {tab.icon} {tab.label}
          </button>
        {/each}
      </nav>
    </div>
    
    <!-- Tab Content -->
    <div class="space-y-6">
      
      <!-- App State Tab -->
      {#if activeTab === 'app-state'}
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">⚙️ Application State</h2>
          
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Current User -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-gray-900 mb-3">👤 Current User</h3>
              <div class="space-y-2 text-sm">
                <div><strong>ID:</strong> {app_state.current_user.id}</div>
                <div><strong>Name:</strong> {app_state.current_user.name}</div>
                <div><strong>Email:</strong> {app_state.current_user.email}</div>
                <div><strong>Role:</strong> <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded text-xs">{app_state.current_user.role}</span></div>
                <div><strong>Session ID:</strong> <code class="text-xs">{app_state.current_user.session_id}</code></div>
              </div>
              
              <h4 class="text-md font-medium text-gray-900 mt-4 mb-2">🔐 Permissions</h4>
              <div class="space-y-1 text-sm">
                {#each Object.entries(app_state.current_user.permissions) as [key, value]}
                  <div class="flex items-center">
                    <span class="w-4 h-4 mr-2 {value ? 'text-green-500' : 'text-red-500'}">
                      {value ? '✓' : '✗'}
                    </span>
                    <span class="font-mono text-xs">{key}</span>
                  </div>
                {/each}
              </div>
              
              <h4 class="text-md font-medium text-gray-900 mt-4 mb-2">🚀 Available Features</h4>
              <div class="flex flex-wrap gap-1">
                {#each app_state.current_user.available_features as feature}
                  <span class="px-2 py-1 bg-green-100 text-green-800 rounded text-xs">{feature}</span>
                {/each}
              </div>
            </div>
            
            <!-- Environment -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-gray-900 mb-3">🌍 Environment</h3>
              <div class="space-y-2 text-sm">
                <div><strong>Rails Environment:</strong> <span class="px-2 py-1 bg-purple-100 text-purple-800 rounded text-xs">{app_state.environment.rails_env}</span></div>
                <div><strong>Database:</strong> <span class="px-2 py-1 bg-orange-100 text-orange-800 rounded text-xs">{app_state.environment.database}</span></div>
                <div><strong>Timezone:</strong> {app_state.environment.timezone}</div>
              </div>
              
              <h4 class="text-md font-medium text-gray-900 mt-4 mb-2">📋 Session Keys</h4>
              <div class="space-y-1">
                {#each app_state.current_user.session_keys as key}
                  <div class="text-xs font-mono bg-gray-100 px-2 py-1 rounded">{key}</div>
                {/each}
              </div>
            </div>
          </div>
        </div>
      {/if}
      
      <!-- Database Tab -->
      {#if activeTab === 'database'}
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">🗄️ Database Statistics</h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <!-- Users -->
            <div class="bg-blue-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-blue-900 mb-3">👥 Users</h3>
              <div class="text-3xl font-bold text-blue-600 mb-2">{database_stats.users.total}</div>
              <div class="space-y-1 text-sm">
                <div>Clients: {database_stats.users.by_role.clients}</div>
                <div>Employees: {database_stats.users.by_role.employees}</div>
                <div>Admins: {database_stats.users.by_role.admins}</div>
              </div>
            </div>
            
            <!-- R&D Claims -->
            <div class="bg-green-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-green-900 mb-3">🔬 R&D Claims</h3>
              <div class="text-3xl font-bold text-green-600 mb-2">{database_stats.rnd_claims.total}</div>
            </div>
            
            <!-- Expenditures -->
            <div class="bg-yellow-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-yellow-900 mb-3">💰 Expenditures</h3>
              <div class="text-3xl font-bold text-yellow-600 mb-2">{database_stats.rnd_claim_expenditures.total}</div>
              <div class="text-sm">Total: £{database_stats.rnd_claim_expenditures.total_amount.toLocaleString()}</div>
            </div>
            
            <!-- Notes -->
            <div class="bg-purple-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-purple-900 mb-3">📝 Notes</h3>
              <div class="text-3xl font-bold text-purple-600">{database_stats.notes.total}</div>
            </div>
            
            <!-- Todos -->
            <div class="bg-red-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-red-900 mb-3">✅ Todos</h3>
              <div class="text-3xl font-bold text-red-600 mb-2">{database_stats.todos.total}</div>
              <div class="space-y-1 text-sm">
                <div>Completed: {database_stats.todos.completed}</div>
                <div>Pending: {database_stats.todos.pending}</div>
              </div>
            </div>
            
            <!-- Files -->
            <div class="bg-indigo-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-indigo-900 mb-3">📁 Files</h3>
              <div class="text-3xl font-bold text-indigo-600 mb-2">{database_stats.file_items.total}</div>
              <div class="text-sm">Size: {formatBytes(database_stats.file_items.total_size)}</div>
            </div>
          </div>
        </div>
      {/if}
      
      <!-- Sample Data Tab -->
      {#if activeTab === 'sample-data'}
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">📊 Sample Data</h2>
          
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Recent Users -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-gray-900 mb-3">👥 Recent Users</h3>
              <div class="space-y-3">
                {#each sample_data.recent_users as user}
                  <div class="bg-white rounded p-3 border">
                    <div class="font-medium">{user.name}</div>
                    <div class="text-sm text-gray-600">{user.email}</div>
                    <div class="flex items-center justify-between mt-2">
                      <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded text-xs">{user.role}</span>
                      <span class="text-xs text-gray-500">{user.created_at}</span>
                    </div>
                    <div class="text-xs text-gray-500 mt-1">
                      Notes: {user.associations_count.notes} | 
                      Todos: {user.associations_count.todos} | 
                      Claims: {user.associations_count.rnd_claims}
                    </div>
                  </div>
                {/each}
              </div>
            </div>
            
            <!-- Recent Projects -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-gray-900 mb-3">🔬 Recent R&D Claims</h3>
              <div class="space-y-3">
                {#each sample_data.recent_projects as project}
                  <div class="bg-white rounded p-3 border">
                    <div class="font-medium">{project.title}</div>
                    <div class="text-sm text-gray-600">Client: {project.client_name}</div>
                    <div class="flex items-center justify-between mt-2">
                      <span class="px-2 py-1 bg-green-100 text-green-800 rounded text-xs">{project.status}</span>
                      <span class="text-xs text-gray-500">{project.created_at}</span>
                    </div>
                    <div class="text-xs text-gray-500 mt-1">
                      Expenditure: £{project.total_expenditure.toLocaleString()} | 
                      Items: {project.expenditures_count}
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          </div>
        </div>
      {/if}
      
      <!-- Controller Tab -->
      {#if activeTab === 'controller'}
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">🎮 Controller Information</h2>
          
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Current Request -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-gray-900 mb-3">📡 Current Request</h3>
              <div class="space-y-2 text-sm">
                <div><strong>Controller:</strong> <code class="bg-gray-100 px-2 py-1 rounded">{controller_info.current_controller}</code></div>
                <div><strong>Action:</strong> <code class="bg-gray-100 px-2 py-1 rounded">{controller_info.current_action}</code></div>
                <div><strong>Method:</strong> <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded text-xs">{controller_info.request_method}</span></div>
                <div><strong>Path:</strong> <code class="bg-gray-100 px-2 py-1 rounded">{controller_info.request_path}</code></div>
              </div>
              
              <h4 class="text-md font-medium text-gray-900 mt-4 mb-2">📋 Request Parameters</h4>
              <div class="bg-gray-100 rounded p-2">
                <pre class="text-xs overflow-x-auto">{JSON.stringify(controller_info.request_params, null, 2)}</pre>
              </div>
            </div>
            
            <!-- Available Routes -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-gray-900 mb-3">🛣️ Available Routes</h3>
              <div class="max-h-64 overflow-y-auto">
                <div class="space-y-1">
                  {#each controller_info.available_routes.slice(0, 20) as route}
                    <div class="text-xs font-mono bg-gray-100 px-2 py-1 rounded">{route}</div>
                  {/each}
                  {#if controller_info.available_routes.length > 20}
                    <div class="text-xs text-gray-500 italic">... and {controller_info.available_routes.length - 20} more routes</div>
                  {/if}
                </div>
              </div>
            </div>
          </div>
        </div>
      {/if}
      
      <!-- Feature Flags Tab -->
      {#if activeTab === 'features'}
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">🚩 Feature Flags</h2>
          
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- All Flags -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-gray-900 mb-3">🎛️ All Feature Flags</h3>
              <div class="space-y-3">
                {#each feature_flags.all_flags as flag}
                  <div class="bg-white rounded p-3 border">
                    <div class="flex items-center justify-between">
                      <div class="font-medium">{flag.name}</div>
                      <span class="px-2 py-1 {flag.enabled ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'} rounded text-xs">
                        {flag.enabled ? 'Enabled' : 'Disabled'}
                      </span>
                    </div>
                    <div class="text-sm text-gray-600 mt-1">{flag.description}</div>
                    <div class="text-xs text-gray-500 mt-1">Users with access: {flag.users_with_access}</div>
                  </div>
                {/each}
              </div>
            </div>
            
            <!-- Enabled Flags -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="text-lg font-medium text-gray-900 mb-3">✅ Enabled Flags</h3>
              <div class="space-y-2">
                {#each feature_flags.enabled_flags as flag}
                  <span class="inline-block px-3 py-1 bg-green-100 text-green-800 rounded text-sm mr-2 mb-2">{flag}</span>
                {/each}
              </div>
              
              <h4 class="text-md font-medium text-gray-900 mt-6 mb-3">👤 User Enabled Flags</h4>
              <div class="space-y-2">
                {#each feature_flags.user_enabled_flags as flag}
                  <span class="inline-block px-3 py-1 bg-blue-100 text-blue-800 rounded text-sm mr-2 mb-2">{flag}</span>
                {/each}
              </div>
            </div>
          </div>
        </div>
      {/if}
    </div>
  </div>
</Layout>
