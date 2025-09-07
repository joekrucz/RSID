<script>
  import { router } from '@inertiajs/svelte';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  
  let { user, query = '', filters = {}, results, total_results = 0 } = $props();
  
  let searchQuery = $state(query);
  let searchFilters = $state({
    projects: true,
    notes: true,
    todos: true,
    messages: true,
    users: user.isEmployee || user.isAdmin
  });
  
  function performSearch() {
    console.log('Search button clicked!');
    console.log('Search query:', searchQuery);
    console.log('Search filters:', searchFilters);
    
    const params = new URLSearchParams();
    if (searchQuery.trim()) {
      params.set('q', searchQuery.trim());
    }
    
    // Add filters
    Object.entries(searchFilters).forEach(([key, value]) => {
      if (value) {
        params.set(`filters[${key}]`, 'true');
      }
    });
    
    const searchUrl = `/search?${params.toString()}`;
    console.log('Navigating to:', searchUrl);
    
    router.visit(searchUrl);
  }
  
  function handleKeyPress(event) {
    if (event.key === 'Enter') {
      performSearch();
    }
  }
  
  function toggleFilter(filter) {
    searchFilters[filter] = !searchFilters[filter];
  }
  
  function clearSearch() {
    searchQuery = '';
    router.visit('/search');
  }
</script>

<Layout {user}>
  <div class="mb-6">
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">
        🔍 Advanced Search
      </h1>
      <p class="text-gray-600">
        Search across all your data with powerful filters
      </p>
    </div>
    
    <!-- Search Form -->
    <div class="bg-white rounded-lg shadow-sm border p-6 mb-6">
      <div class="flex gap-4 mb-4">
        <div class="flex-1">
          <input
            type="text"
            bind:value={searchQuery}
            on:keypress={handleKeyPress}
            placeholder="Search for projects, notes, todos, messages, or users..."
            class="input input-bordered w-full"
          />
        </div>
        <Button onclick={performSearch} variant="primary">
          Search
        </Button>
        {#if query}
          <Button onclick={clearSearch} variant="secondary">
            Clear
          </Button>
        {/if}
      </div>
      
      <!-- Filters -->
      <div class="flex flex-wrap gap-4">
        <label class="flex items-center gap-2">
          <input
            type="checkbox"
            bind:checked={searchFilters.claims}
            class="checkbox checkbox-sm"
          />
          <span class="text-sm">R&D Claims</span>
        </label>
        
        <label class="flex items-center gap-2">
          <input
            type="checkbox"
            bind:checked={searchFilters.notes}
            class="checkbox checkbox-sm"
          />
          <span class="text-sm">Notes</span>
        </label>
        
        <label class="flex items-center gap-2">
          <input
            type="checkbox"
            bind:checked={searchFilters.todos}
            class="checkbox checkbox-sm"
          />
          <span class="text-sm">Todos</span>
        </label>
        
        <label class="flex items-center gap-2">
          <input
            type="checkbox"
            bind:checked={searchFilters.messages}
            class="checkbox checkbox-sm"
          />
          <span class="text-sm">Messages</span>
        </label>
        
        {#if user.isEmployee || user.isAdmin}
          <label class="flex items-center gap-2">
            <input
              type="checkbox"
              bind:checked={searchFilters.users}
              class="checkbox checkbox-sm"
            />
            <span class="text-sm">Users</span>
          </label>
        {/if}
      </div>
    </div>
    
    <!-- Results -->
    {#if query}
      <div class="mb-4">
        <h2 class="text-xl font-semibold text-gray-900 mb-2">
          Search Results for "{query}"
        </h2>
        <p class="text-gray-600">
          Found {total_results} result{total_results !== 1 ? 's' : ''}
        </p>
      </div>
      
      <!-- R&D Claims -->
      {#if results.claims && results.claims.length > 0}
        <div class="bg-white rounded-lg shadow-sm border p-6 mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            🔬 R&D Claims ({results.claims.length})
          </h3>
          <div class="space-y-4">
            {#each results.claims as claim}
              <div class="border rounded-lg p-4 hover:bg-gray-50">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <h4 class="font-medium text-gray-900">{claim.title}</h4>
                    <p class="text-sm text-gray-600 mt-1">{claim.qualifying_activities}</p>
                    <div class="flex items-center gap-4 mt-2 text-xs text-gray-500">
                      {#if claim.company}
                        <span>Company: {claim.company.name}</span>
                      {/if}
                      <span>Created: {claim.created_at}</span>
                    </div>
                  </div>
                                     <Button 
                     variant="secondary" 
                     size="sm"
                     onclick={() => router.visit(`/rnd_claims/${claim.id}`)}
                   >
                    View
                  </Button>
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/if}
      
      <!-- Notes -->
      {#if results.notes && results.notes.length > 0}
        <div class="bg-white rounded-lg shadow-sm border p-6 mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            📝 Notes ({results.notes.length})
          </h3>
          <div class="space-y-4">
            {#each results.notes as note}
              <div class="border rounded-lg p-4 hover:bg-gray-50">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <h4 class="font-medium text-gray-900">{note.title}</h4>
                    <p class="text-sm text-gray-600 mt-1">{note.content}</p>
                    <div class="text-xs text-gray-500 mt-2">Created: {note.created_at}</div>
                  </div>
                                     <Button 
                     variant="secondary" 
                     size="sm"
                     onclick={() => router.visit(`/notes/${note.id}`)}
                   >
                    View
                  </Button>
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/if}
      
      <!-- Todos -->
      {#if results.todos && results.todos.length > 0}
        <div class="bg-white rounded-lg shadow-sm border p-6 mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            ✅ Todos ({results.todos.length})
          </h3>
          <div class="space-y-4">
            {#each results.todos as todo}
              <div class="border rounded-lg p-4 hover:bg-gray-50">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <h4 class="font-medium text-gray-900 flex items-center gap-2">
                      {todo.title}
                      {#if todo.completed}
                        <span class="badge badge-success badge-sm">Completed</span>
                      {:else if todo.overdue}
                        <span class="badge badge-error badge-sm">Overdue</span>
                      {:else if todo.due_soon}
                        <span class="badge badge-warning badge-sm">Due Soon</span>
                      {/if}
                    </h4>
                    <p class="text-sm text-gray-600 mt-1">{todo.description}</p>
                    <div class="flex items-center gap-4 mt-2 text-xs text-gray-500">
                      <span>Priority: {todo.priority}</span>
                      {#if todo.due_date}
                        <span>Due: {todo.due_date_formatted}</span>
                      {/if}
                      <span>Created: {todo.created_at}</span>
                    </div>
                  </div>
                                     <Button 
                     variant="secondary" 
                     size="sm"
                     onclick={() => router.visit(`/todos/${todo.id}`)}
                   >
                    View
                  </Button>
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/if}
      
      <!-- Messages -->
      {#if results.messages && results.messages.length > 0}
        <div class="bg-white rounded-lg shadow-sm border p-6 mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            💬 Messages ({results.messages.length})
          </h3>
          <div class="space-y-4">
            {#each results.messages as message}
              <div class="border rounded-lg p-4 hover:bg-gray-50">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <h4 class="font-medium text-gray-900">{message.subject}</h4>
                    <p class="text-sm text-gray-600 mt-1">{message.content}</p>
                    <div class="flex items-center gap-4 mt-2 text-xs text-gray-500">
                      <span>From: {message.sender_name}</span>
                      <span>To: {message.recipient_name}</span>
                      <span>Created: {message.created_at}</span>
                    </div>
                  </div>
                                     <Button 
                     variant="secondary" 
                     size="sm"
                     onclick={() => router.visit(`/messages/${message.id}`)}
                   >
                    View
                  </Button>
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/if}
      
      <!-- Users -->
      {#if results.users && results.users.length > 0}
        <div class="bg-white rounded-lg shadow-sm border p-6 mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            👥 Users ({results.users.length})
          </h3>
          <div class="space-y-4">
            {#each results.users as user_result}
              <div class="border rounded-lg p-4 hover:bg-gray-50">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <h4 class="font-medium text-gray-900">{user_result.name}</h4>
                    <p class="text-sm text-gray-600 mt-1">{user_result.email}</p>
                    <div class="flex items-center gap-4 mt-2 text-xs text-gray-500">
                      <span>Role: {user_result.role}</span>
                    </div>
                  </div>
                                     <Button 
                     variant="secondary" 
                     size="sm"
                     onclick={() => router.visit(`/people/${user_result.id}`)}
                   >
                    View
                  </Button>
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/if}
      
      <!-- No Results -->
      {#if total_results === 0}
        <div class="bg-white rounded-lg shadow-sm border p-12 text-center">
          <div class="text-6xl mb-4">🔍</div>
          <h3 class="text-xl font-semibold text-gray-900 mb-2">No results found</h3>
          <p class="text-gray-600 mb-4">
            Try adjusting your search terms or filters
          </p>
          <Button onclick={clearSearch} variant="primary">
            Start New Search
          </Button>
        </div>
      {/if}
    {:else}
      <!-- Search Tips -->
      <div class="bg-white rounded-lg shadow-sm border p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">💡 Search Tips</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <h4 class="font-medium text-gray-900 mb-2">What you can search:</h4>
            <ul class="text-sm text-gray-600 space-y-1">
              <li>• R&D project titles and descriptions</li>
              <li>• Note titles and content</li>
              <li>• Todo titles and descriptions</li>
              <li>• Message subjects and content</li>
              <li>• User names and emails (admin/employee only)</li>
            </ul>
          </div>
          <div>
            <h4 class="font-medium text-gray-900 mb-2">Search features:</h4>
            <ul class="text-sm text-gray-600 space-y-1">
              <li>• Use filters to narrow results</li>
              <li>• Search is case-insensitive</li>
              <li>• Results respect your permissions</li>
              <li>• Click any result to view details</li>
            </ul>
          </div>
        </div>
      </div>
    {/if}
  </div>
</Layout>
