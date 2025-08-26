<script>
  import Layout from '../../components/Layout.svelte';
  import { toast } from '../../stores/toast.js';
  import { router } from '@inertiajs/svelte';
  
  let { user, notes = [], errors = [], success_message, editing_note, search = '', sort_by = 'created_at', sort_order = 'desc' } = $props();
  
  let newNote = $state({
    title: '',
    content: ''
  });
  
  let showNewNoteForm = $state(false);
  let searchQuery = $state(search);
  let currentSortBy = $state(sort_by);
  let currentSortOrder = $state(sort_order);
  
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
  
  function addNote() {
    if (!newNote.title.trim() || !newNote.content.trim()) {
      toast.error('Please fill in both title and content');
      return;
    }
    
    router.post('/notes', {
      note: newNote
    }, {
      preserveState: true,
      onSuccess: () => {
        newNote = { title: '', content: '' };
        showNewNoteForm = false;
      }
    });
  }
  
  function editNote(note) {
    router.get(`/notes/${note.id}/edit`, {
      search: searchQuery,
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true
    });
  }
  
  function saveNote(note) {
    if (!note.title.trim() || !note.content.trim()) {
      toast.error('Please fill in both title and content');
      return;
    }
    
    router.put(`/notes/${note.id}`, {
      note: {
        title: note.title,
        content: note.content
      }
    }, {
      preserveState: true
    });
  }
  
  function cancelEdit() {
    // Reset editing state by refreshing the page
    router.visit('/notes', { 
      preserveState: false,
      onSuccess: () => {
        // Refresh the page after navigation
        window.location.reload();
      }
    });
  }
  
  function deleteNote(id) {
    if (confirm('Are you sure you want to delete this note?')) {
      router.delete(`/notes/${id}`, {
        preserveState: true
      });
    }
  }
  
  function toggleNewNoteForm() {
    showNewNoteForm = !showNewNoteForm;
    if (!showNewNoteForm) {
      newNote = { title: '', content: '' };
    }
  }
  
  function isEditing(noteId) {
    return editing_note && editing_note.id === noteId;
  }
  
  function handleSearch() {
    router.get('/notes', {
      search: searchQuery,
      sort_by: currentSortBy,
      sort_order: currentSortOrder
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
    
    router.get('/notes', {
      search: searchQuery,
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      replace: true
    });
  }
  
  function clearSearch() {
    searchQuery = '';
    router.get('/notes', {
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      replace: true
    });
  }
  
  function getSortIcon(sortBy) {
    if (currentSortBy !== sortBy) return '↕️';
    return currentSortOrder === 'desc' ? '↓' : '↑';
  }
</script>

<svelte:head>
  <title>Notes - RSID App</title>
</svelte:head>

<Layout {user} currentPage="notes">
  {#snippet children()}
    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-4xl font-bold text-base-content mb-2">Notes</h1>
      <p class="text-base-content/70">Create, edit, and manage your personal notes.</p>
    </div>

    <!-- Search and Controls -->
    <div class="flex flex-wrap gap-4 mb-6">
      <button 
        class="btn btn-primary"
        onclick={toggleNewNoteForm}
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
        </svg>
        {showNewNoteForm ? 'Cancel' : 'New Note'}
      </button>
      
      <!-- Search Bar -->
      <div class="join">
        <input 
          type="text" 
          class="input input-bordered join-item" 
          placeholder="Search notes..."
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
      
      <!-- Sort Options -->
      <div class="dropdown dropdown-end">
        <div tabindex="0" role="button" class="btn btn-outline">
          Sort: {currentSortBy.replace('_', ' ').charAt(0).toUpperCase() + currentSortBy.replace('_', ' ').slice(1)} {getSortIcon(currentSortBy)}
        </div>
        <ul class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52 z-[1]">
          <li><button onclick={() => handleSort('created_at')}>Date Created {getSortIcon('created_at')}</button></li>
          <li><button onclick={() => handleSort('updated_at')}>Date Updated {getSortIcon('updated_at')}</button></li>
          <li><button onclick={() => handleSort('title')}>Title {getSortIcon('title')}</button></li>
        </ul>
      </div>
    </div>

    <!-- Search Results Info -->
    {#if searchQuery}
      <div class="alert alert-info mb-6">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
        </svg>
        <span>Searching for "{searchQuery}" - Found {notes.length} note{notes.length !== 1 ? 's' : ''}</span>
      </div>
    {/if}

    <!-- New Note Form -->
    {#if showNewNoteForm}
      <div class="card bg-base-100 shadow-xl mb-6">
        <div class="card-body">
          <h2 class="card-title">Create New Note</h2>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Title</span>
            </label>
            <input 
              type="text" 
              class="input input-bordered" 
              placeholder="Enter note title"
              bind:value={newNote.title}
            />
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Content</span>
            </label>
            <textarea 
              class="textarea textarea-bordered h-32" 
              placeholder="Enter note content"
              bind:value={newNote.content}
            ></textarea>
          </div>
          
          <div class="card-actions justify-end">
            <button 
              class="btn btn-primary"
              onclick={addNote}
            >
              Create Note
            </button>
          </div>
        </div>
      </div>
    {/if}

    <!-- Notes Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {#each notes as note (note.id)}
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            {#if isEditing(note.id)}
              <!-- Edit Mode -->
              <div class="form-control">
                <input 
                  type="text" 
                  class="input input-bordered font-bold text-lg" 
                  bind:value={editing_note.title}
                />
              </div>
              
              <div class="form-control">
                <textarea 
                  class="textarea textarea-bordered h-32" 
                  bind:value={editing_note.content}
                ></textarea>
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
                  onclick={() => saveNote(editing_note)}
                >
                  Save
                </button>
              </div>
            {:else}
              <!-- View Mode -->
              <h2 class="card-title">{note.title}</h2>
              <p class="text-base-content/70 whitespace-pre-wrap">{note.content}</p>
              
              <div class="flex justify-between items-center mt-4 text-sm text-base-content/50">
                <span>Created: {note.created_at}</span>
                {#if note.updated_at !== note.created_at}
                  <span>Updated: {note.updated_at}</span>
                {/if}
              </div>
              
              <div class="card-actions justify-end mt-4">
                <button 
                  class="btn btn-sm btn-ghost"
                  onclick={() => editNote(note)}
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                  </svg>
                  Edit
                </button>
                <button 
                  class="btn btn-sm btn-error"
                  onclick={() => deleteNote(note.id)}
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                  </svg>
                  Delete
                </button>
              </div>
            {/if}
          </div>
        </div>
      {/each}
    </div>

    <!-- Empty State -->
    {#if notes.length === 0}
      <div class="text-center py-12">
        <div class="text-6xl mb-4">📝</div>
        <h3 class="text-xl font-semibold mb-2">
          {searchQuery ? 'No notes found' : 'No notes yet'}
        </h3>
        <p class="text-base-content/70 mb-4">
          {searchQuery 
            ? `No notes match your search for "${searchQuery}"` 
            : 'Create your first note to get started!'}
        </p>
        {#if !searchQuery}
          <button 
            class="btn btn-primary"
            onclick={toggleNewNoteForm}
          >
            Create Your First Note
          </button>
        {/if}
      </div>
    {/if}
  {/snippet}
</Layout> 