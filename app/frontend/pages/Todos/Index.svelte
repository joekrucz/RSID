<script>
  import Layout from '../../components/Layout.svelte';
  import { toast } from '../../stores/toast.js';
  import { router } from '@inertiajs/svelte';
  
  let { user, todos = [], errors = [], success_message, editing_todo, search = '', sort_by = 'created_at', sort_order = 'desc', filter = 'all' } = $props();
  
  let newTodo = $state({
    title: '',
    description: '',
    priority: 'medium',
    due_date: ''
  });
  
  let showNewTodoForm = $state(false);
  let searchQuery = $state(search);
  let currentSortBy = $state(sort_by);
  let currentSortOrder = $state(sort_order);
  let currentFilter = $state(filter);
  
  // Watch for success messages from server
  $effect(() => {
    if (success_message) {
      toast.success(success_message);
    }
  });
  
  // Watch for errors from server
  $effect(() => {
    if (errors && errors.length > 0) {
      errors.forEach(error => toast.error(error));
    }
  });
  
  function addTodo() {
    if (!newTodo.title.trim()) {
      toast.error('Please enter a todo title');
      return;
    }
    
    router.post('/todos', {
      todo: newTodo
    }, {
      preserveState: true,
      onSuccess: () => {
        newTodo = { title: '', description: '', priority: 'medium', due_date: '' };
        showNewTodoForm = false;
      }
    });
  }
  
  function toggleTodo(id) {
    router.patch(`/todos/${id}/toggle`, {}, {
      preserveState: true
    });
  }
  
  function editTodo(todo) {
    router.get(`/todos/${todo.id}/edit`, {
      search: searchQuery,
      sort_by: currentSortBy,
      sort_order: currentSortOrder,
      filter: currentFilter
    }, {
      preserveState: true
    });
  }
  
  function saveTodo(todo) {
    if (!todo.title.trim()) {
      toast.error('Please enter a todo title');
      return;
    }
    
    router.put(`/todos/${todo.id}`, {
      todo: {
        title: todo.title,
        description: todo.description,
        priority: todo.priority,
        due_date: todo.due_date
      }
    }, {
      preserveState: true
    });
  }
  
  function cancelEdit() {
    // Reset editing state by refreshing the page
    router.visit('/todos', { 
      preserveState: false
    });
  }
  
  function deleteTodo(id) {
    if (confirm('Are you sure you want to delete this todo?')) {
      router.delete(`/todos/${id}`, {
        preserveState: true
      });
    }
  }
  
  function toggleNewTodoForm() {
    showNewTodoForm = !showNewTodoForm;
    if (!showNewTodoForm) {
      newTodo = { title: '', description: '', priority: 'medium', due_date: '' };
    }
  }
  
  function clearCompleted() {
    if (confirm('Are you sure you want to clear all completed todos?')) {
      router.delete('/todos/clear_completed', {
        preserveState: true
      });
    }
  }
  
  function getPriorityColor(priority) {
    switch (priority) {
      case 'high': return 'badge-error';
      case 'medium': return 'badge-warning';
      case 'low': return 'badge-success';
      default: return 'badge-warning';
    }
  }
  
  function getPriorityText(priority) {
    return priority.charAt(0).toUpperCase() + priority.slice(1);
  }
  
  function getStats() {
    const total = todos.length;
    const completed = todos.filter(todo => todo.completed).length;
    const active = total - completed;
    const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;
    
    return { total, completed, active, completionRate };
  }
  
  function isEditing(todoId) {
    return editing_todo && editing_todo.id === todoId;
  }
  
  function handleSearch() {
    router.get('/todos', {
      search: searchQuery,
      sort_by: currentSortBy,
      sort_order: currentSortOrder,
      filter: currentFilter
    }, {
      preserveState: true,
      replace: true
    });
  }
  
  function handleSort(sortBy) {
    let newSortOrder = 'desc';
    if (currentSortBy === sortBy) {
      newSortOrder = currentSortOrder === 'desc' ? 'asc' : 'desc';
    }
    
    currentSortBy = sortBy;
    currentSortOrder = newSortOrder;
    
    router.get('/todos', {
      search: searchQuery,
      sort_by: currentSortBy,
      sort_order: currentSortOrder,
      filter: currentFilter
    }, {
      preserveState: true,
      replace: true
    });
  }
  
  function handleFilter(newFilter) {
    currentFilter = newFilter;
    
    router.get('/todos', {
      search: searchQuery,
      sort_by: currentSortBy,
      sort_order: currentSortOrder,
      filter: currentFilter
    }, {
      preserveState: true,
      replace: true
    });
  }
  
  function clearSearch() {
    searchQuery = '';
    router.get('/todos', {
      sort_by: currentSortBy,
      sort_order: currentSortOrder,
      filter: currentFilter
    }, {
      preserveState: true,
      replace: true
    });
  }
  
  function getSortIcon(sortBy) {
    if (currentSortBy !== sortBy) return '↕️';
    return currentSortOrder === 'desc' ? '↓' : '↑';
  }
  
  const stats = $derived(getStats());
</script>

<svelte:head>
  <title>Todo List - RSID App</title>
</svelte:head>

<Layout {user} currentPage="todos">
  {#snippet children()}
    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-4xl font-bold text-base-content mb-2">Todo List</h1>
      <p class="text-base-content/70">Organize your tasks and boost your productivity.</p>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-title">Total Tasks</div>
        <div class="stat-value text-primary">{stats.total}</div>
      </div>
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-title">Active</div>
        <div class="stat-value text-warning">{stats.active}</div>
      </div>
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-title">Completed</div>
        <div class="stat-value text-success">{stats.completed}</div>
      </div>
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-title">Progress</div>
        <div class="stat-value text-info">{stats.completionRate}%</div>
      </div>
    </div>

    <!-- Search and Controls -->
    <div class="flex flex-wrap gap-4 mb-6">
      <button 
        class="btn btn-primary"
        onclick={toggleNewTodoForm}
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
        </svg>
        {showNewTodoForm ? 'Cancel' : 'Add Todo'}
      </button>
      
      <!-- Search Bar -->
      <div class="join">
        <input 
          type="text" 
          class="input input-bordered join-item" 
          placeholder="Search todos..."
          bind:value={searchQuery}
          onkeydown={(e) => e.key === 'Enter' && handleSearch()}
        />
        <button 
          class="btn btn-outline join-item"
          onclick={handleSearch}
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
          </svg>
        </button>
        {#if searchQuery}
          <button 
            class="btn btn-outline join-item"
            onclick={clearSearch}
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        {/if}
      </div>
      
      <!-- Filter Buttons -->
      <div class="join">
        <button 
          class="join-item btn btn-sm" 
          class:btn-active={currentFilter === 'all'}
          onclick={() => handleFilter('all')}
        >
          All ({stats.total})
        </button>
        <button 
          class="join-item btn btn-sm" 
          class:btn-active={currentFilter === 'active'}
          onclick={() => handleFilter('active')}
        >
          Active ({stats.active})
        </button>
        <button 
          class="join-item btn btn-sm" 
          class:btn-active={currentFilter === 'completed'}
          onclick={() => handleFilter('completed')}
        >
          Completed ({stats.completed})
        </button>
      </div>
      
      <!-- Sort Options -->
      <div class="dropdown dropdown-end">
        <div tabindex="0" role="button" class="btn btn-outline btn-sm">
          Sort: {currentSortBy.replace('_', ' ').charAt(0).toUpperCase() + currentSortBy.replace('_', ' ').slice(1)} {getSortIcon(currentSortBy)}
        </div>
        <ul class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52 z-[1]">
          <li><button onclick={() => handleSort('created_at')}>Date Created {getSortIcon('created_at')}</button></li>
          <li><button onclick={() => handleSort('updated_at')}>Date Updated {getSortIcon('updated_at')}</button></li>
          <li><button onclick={() => handleSort('title')}>Title {getSortIcon('title')}</button></li>
          <li><button onclick={() => handleSort('priority')}>Priority {getSortIcon('priority')}</button></li>
          <li><button onclick={() => handleSort('due_date')}>Due Date {getSortIcon('due_date')}</button></li>
          <li><button onclick={() => handleSort('completed')}>Status {getSortIcon('completed')}</button></li>
        </ul>
      </div>
      
      {#if stats.completed > 0}
        <button 
          class="btn btn-outline btn-sm btn-error"
          onclick={clearCompleted}
        >
          Clear Completed
        </button>
      {/if}
    </div>

    <!-- Search Results Info -->
    {#if searchQuery}
      <div class="alert alert-info mb-6">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
        </svg>
        <span>Searching for "{searchQuery}" - Found {todos.length} todo{todos.length !== 1 ? 's' : ''}</span>
      </div>
    {/if}

    <!-- New Todo Form -->
    {#if showNewTodoForm}
      <div class="card bg-base-100 shadow-xl mb-6">
        <div class="card-body">
          <h2 class="card-title">Add New Todo</h2>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Title *</span>
            </label>
            <input 
              type="text" 
              class="input input-bordered" 
              placeholder="Enter todo title"
              bind:value={newTodo.title}
            />
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Description</span>
            </label>
            <textarea 
              class="textarea textarea-bordered h-20" 
              placeholder="Enter todo description (optional)"
              bind:value={newTodo.description}
            ></textarea>
          </div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="form-control">
              <label class="label">
                <span class="label-text">Priority</span>
              </label>
              <select class="select select-bordered" bind:value={newTodo.priority}>
                <option value="low">Low</option>
                <option value="medium">Medium</option>
                <option value="high">High</option>
              </select>
            </div>
            
            <div class="form-control">
              <label class="label">
                <span class="label-text">Due Date</span>
              </label>
              <input 
                type="date" 
                class="input input-bordered" 
                bind:value={newTodo.due_date}
              />
            </div>
          </div>
          
          <div class="card-actions justify-end">
            <button 
              class="btn btn-primary"
              onclick={addTodo}
            >
              Add Todo
            </button>
          </div>
        </div>
      </div>
    {/if}

    <!-- Todo List -->
    <div class="space-y-4">
      {#each todos as todo (todo.id)}
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            {#if isEditing(todo.id)}
              <!-- Edit Mode -->
              <div class="form-control">
                <input 
                  type="text" 
                  class="input input-bordered font-bold text-lg" 
                  bind:value={editing_todo.title}
                />
              </div>
              
              <div class="form-control">
                <textarea 
                  class="textarea textarea-bordered h-20" 
                  bind:value={editing_todo.description}
                ></textarea>
              </div>
              
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="form-control">
                  <select class="select select-bordered" bind:value={editing_todo.priority}>
                    <option value="low">Low</option>
                    <option value="medium">Medium</option>
                    <option value="high">High</option>
                  </select>
                </div>
                
                <div class="form-control">
                  <input 
                    type="date" 
                    class="input input-bordered" 
                    bind:value={editing_todo.due_date}
                  />
                </div>
              </div>
              
              <div class="card-actions justify-end">
                <button 
                  class="btn btn-sm btn-ghost"
                  onclick={cancelEdit}
                >
                  Cancel
                </button>
                <button 
                  class="btn btn-sm btn-primary"
                  onclick={() => saveTodo(editing_todo)}
                >
                  Save
                </button>
              </div>
            {:else}
              <!-- View Mode -->
              <div class="flex items-start gap-4">
                <input 
                  type="checkbox" 
                  class="checkbox checkbox-primary mt-1" 
                  checked={todo.completed}
                  onchange={() => toggleTodo(todo.id)}
                />
                
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-2">
                    <h3 class="text-lg font-semibold" class:line-through={todo.completed}>
                      {todo.title}
                    </h3>
                    <span class="badge {getPriorityColor(todo.priority)}">
                      {getPriorityText(todo.priority)}
                    </span>
                  </div>
                  
                  {#if todo.description}
                    <p class="text-base-content/70 mb-2" class:line-through={todo.completed}>
                      {todo.description}
                    </p>
                  {/if}
                  
                  <div class="flex items-center gap-4 text-sm text-base-content/50">
                    <span>Created: {todo.created_at}</span>
                    {#if todo.due_date_formatted}
                      <span>Due: {todo.due_date_formatted}</span>
                    {/if}
                  </div>
                </div>
                
                <div class="flex gap-2">
                  <button 
                    class="btn btn-sm btn-ghost"
                    onclick={() => editTodo(todo)}
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                    </svg>
                  </button>
                  <button 
                    class="btn btn-sm btn-error"
                    onclick={() => deleteTodo(todo.id)}
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                    </svg>
                  </button>
                </div>
              </div>
            {/if}
          </div>
        </div>
      {/each}
    </div>

    <!-- Empty State -->
    {#if todos.length === 0}
      <div class="text-center py-12">
        <div class="text-6xl mb-4">📋</div>
        <h3 class="text-xl font-semibold mb-2">
          {searchQuery 
            ? 'No todos found' 
            : currentFilter === 'all' 
              ? 'No todos yet' 
              : currentFilter === 'active' 
                ? 'No active todos' 
                : 'No completed todos'}
        </h3>
        <p class="text-base-content/70 mb-4">
          {searchQuery 
            ? `No todos match your search for "${searchQuery}"` 
            : currentFilter === 'all' 
              ? 'Create your first todo to get started!' 
              : currentFilter === 'active' 
                ? 'All todos are completed! Great job! 🎉' 
                : 'Complete some todos to see them here!'}
        </p>
        {#if currentFilter === 'all' && !searchQuery}
          <button 
            class="btn btn-primary"
            onclick={toggleNewTodoForm}
          >
            Create Your First Todo
          </button>
        {/if}
      </div>
    {/if}
  {/snippet}
</Layout> 