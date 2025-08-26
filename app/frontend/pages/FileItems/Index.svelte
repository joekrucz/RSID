<script>
  import Layout from '../../components/Layout.svelte';
  import { toast } from '../../stores/toast.js';
  import { router } from '@inertiajs/svelte';
  
  let { 
    user, 
    files = [], 
    errors = [], 
    success_message, 
    search = '', 
    category = '', 
    file_type = '', 
    sort_by = 'created_at', 
    sort_order = 'desc',
    categories = [],
    file_types = []
  } = $props();
  
  let searchQuery = $state(search);
  let currentCategory = $state(category);
  let currentFileType = $state(file_type);
  let currentSortBy = $state(sort_by);
  let currentSortOrder = $state(sort_order);
  let showUploadForm = $state(false);
  let uploading = $state(false);
  
  let newFile = $state({
    name: '',
    description: '',
    category: 'personal'
  });
  
  let selectedFile = $state(null);
  
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
  
  function handleFileSelect(event) {
    const file = event.target.files[0];
    if (file) {
      selectedFile = file;
      // Auto-fill name if empty
      if (!newFile.name.trim()) {
        newFile.name = file.name.split('.').slice(0, -1).join('.');
      }
    }
  }
  
  function uploadFile() {
    if (!selectedFile) {
      toast.error('Please select a file to upload');
      return;
    }
    
    if (!newFile.name.trim()) {
      toast.error('Please enter a file name');
      return;
    }
    
    uploading = true;
    
    const formData = new FormData();
    formData.append('file', selectedFile);
    formData.append('file_item[name]', newFile.name);
    formData.append('file_item[description]', newFile.description);
    formData.append('file_item[category]', newFile.category);
    
    router.post('/file_items', formData, {
      preserveState: true,
      onSuccess: () => {
        newFile = { name: '', description: '', category: 'personal' };
        selectedFile = null;
        showUploadForm = false;
        uploading = false;
      },
      onError: () => {
        uploading = false;
      }
    });
  }
  
  function handleSearch() {
    router.get('/file_items', {
      search: searchQuery,
      category: currentCategory,
      file_type: currentFileType,
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      replace: true
    });
  }
  
  function handleFilter(filterType, value) {
    switch (filterType) {
      case 'category':
        currentCategory = value;
        break;
      case 'file_type':
        currentFileType = value;
        break;
    }
    
    router.get('/file_items', {
      search: searchQuery,
      category: currentCategory,
      file_type: currentFileType,
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
    
    router.get('/file_items', {
      search: searchQuery,
      category: currentCategory,
      file_type: currentFileType,
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      replace: true
    });
  }
  
  function clearFilters() {
    searchQuery = '';
    currentCategory = '';
    currentFileType = '';
    
    router.get('/file_items', {
      sort_by: currentSortBy,
      sort_order: currentSortOrder
    }, {
      preserveState: true,
      replace: true
    });
  }
  
  function deleteFile(id) {
    if (confirm('Are you sure you want to delete this file?')) {
      router.delete(`/file_items/${id}`, {
        preserveState: true
      });
    }
  }
  
  function downloadFile(id) {
    window.open(`/file_items/${id}/download`, '_blank');
  }
  
  function previewFile(id) {
    window.open(`/file_items/${id}/preview`, '_blank');
  }
  
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
  
  function getCategoryColor(category) {
    switch (category) {
      case 'personal': return 'badge-primary';
      case 'work': return 'badge-secondary';
      case 'projects': return 'badge-accent';
      default: return 'badge-neutral';
    }
  }
  
  function getSortIcon(sortBy) {
    if (currentSortBy !== sortBy) return '↕️';
    return currentSortOrder === 'desc' ? '↓' : '↑';
  }
  
  function getStats() {
    const total = files.length;
    const byCategory = {
      personal: files.filter(f => f.category === 'personal').length,
      work: files.filter(f => f.category === 'work').length,
      projects: files.filter(f => f.category === 'projects').length
    };
    const byType = {};
    file_types.forEach(type => {
      byType[type] = files.filter(f => f.file_type === type).length;
    });
    
    return { total, byCategory, byType };
  }
  
  const stats = $derived(getStats());
</script>

<svelte:head>
  <title>File Management - RSID App</title>
</svelte:head>

<Layout {user} currentPage="files">
  {#snippet children()}
    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-4xl font-bold text-base-content mb-2">File Management</h1>
      <p class="text-base-content/70">Upload, organize, and manage your files securely.</p>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-title">Total Files</div>
        <div class="stat-value text-primary">{stats.total}</div>
      </div>
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-title">Personal</div>
        <div class="stat-value text-secondary">{stats.byCategory.personal}</div>
      </div>
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-title">Work</div>
        <div class="stat-value text-accent">{stats.byCategory.work}</div>
      </div>
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-title">Projects</div>
        <div class="stat-value text-info">{stats.byCategory.projects}</div>
      </div>
    </div>

    <!-- Controls -->
    <div class="flex flex-wrap gap-4 mb-6">
      <button 
        class="btn btn-primary"
        onclick={() => showUploadForm = !showUploadForm}
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path>
        </svg>
        {showUploadForm ? 'Cancel Upload' : 'Upload File'}
      </button>
      
      <!-- Search Bar -->
      <div class="join">
        <input 
          type="text" 
          class="input input-bordered join-item" 
          placeholder="Search files..."
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
      </div>
      
      <!-- Category Filter -->
      <div class="dropdown dropdown-end">
        <div tabindex="0" role="button" class="btn btn-outline">
          Category: {currentCategory || 'All'}
        </div>
        <ul class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52 z-[1]">
          <li><button onclick={() => handleFilter('category', '')}>All Categories</button></li>
          {#each categories as cat}
            <li><button onclick={() => handleFilter('category', cat)}>{cat.charAt(0).toUpperCase() + cat.slice(1)}</button></li>
          {/each}
        </ul>
      </div>
      
      <!-- File Type Filter -->
      <div class="dropdown dropdown-end">
        <div tabindex="0" role="button" class="btn btn-outline">
          Type: {currentFileType || 'All'}
        </div>
        <ul class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52 z-[1]">
          <li><button onclick={() => handleFilter('file_type', '')}>All Types</button></li>
          {#each file_types as type}
            <li><button onclick={() => handleFilter('file_type', type)}>{type.charAt(0).toUpperCase() + type.slice(1)}</button></li>
          {/each}
        </ul>
      </div>
      
      <!-- Sort Options -->
      <div class="dropdown dropdown-end">
        <div tabindex="0" role="button" class="btn btn-outline">
          Sort: {currentSortBy.replace('_', ' ').charAt(0).toUpperCase() + currentSortBy.replace('_', ' ').slice(1)} {getSortIcon(currentSortBy)}
        </div>
        <ul class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52 z-[1]">
          <li><button onclick={() => handleSort('created_at')}>Date Created {getSortIcon('created_at')}</button></li>
          <li><button onclick={() => handleSort('updated_at')}>Date Updated {getSortIcon('updated_at')}</button></li>
          <li><button onclick={() => handleSort('name')}>Name {getSortIcon('name')}</button></li>
          <li><button onclick={() => handleSort('file_size')}>Size {getSortIcon('file_size')}</button></li>
        </ul>
      </div>
      
      {#if searchQuery || currentCategory || currentFileType}
        <button 
          class="btn btn-outline btn-sm"
          onclick={clearFilters}
        >
          Clear Filters
        </button>
      {/if}
    </div>

    <!-- Upload Form -->
    {#if showUploadForm}
      <div class="card bg-base-100 shadow-xl mb-6">
        <div class="card-body">
          <h2 class="card-title">Upload New File</h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="form-control">
              <label class="label">
                <span class="label-text">File</span>
              </label>
              <input 
                type="file" 
                class="file-input file-input-bordered w-full" 
                onchange={handleFileSelect}
                accept="*/*"
              />
              {#if selectedFile}
                <label class="label">
                  <span class="label-text-alt">Selected: {selectedFile.name} ({(selectedFile.size / 1024).toFixed(1)} KB)</span>
                </label>
              {/if}
            </div>
            
            <div class="form-control">
              <label class="label">
                <span class="label-text">Category</span>
              </label>
              <select class="select select-bordered" bind:value={newFile.category}>
                {#each categories as cat}
                  <option value={cat}>{cat.charAt(0).toUpperCase() + cat.slice(1)}</option>
                {/each}
              </select>
            </div>
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Name</span>
            </label>
            <input 
              type="text" 
              class="input input-bordered" 
              placeholder="Enter file name"
              bind:value={newFile.name}
            />
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Description</span>
            </label>
            <textarea 
              class="textarea textarea-bordered h-20" 
              placeholder="Enter file description (optional)"
              bind:value={newFile.description}
            ></textarea>
          </div>
          
          <div class="card-actions justify-end">
            <button 
              class="btn btn-primary"
              disabled={uploading}
              onclick={uploadFile}
            >
              {#if uploading}
                <span class="loading loading-spinner loading-sm"></span>
                Uploading...
              {:else}
                Upload File
              {/if}
            </button>
          </div>
        </div>
      </div>
    {/if}

    <!-- Search Results Info -->
    {#if searchQuery || currentCategory || currentFileType}
      <div class="alert alert-info mb-6">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
        </svg>
        <span>
          {#if searchQuery}
            Searching for "{searchQuery}"
          {/if}
          {#if currentCategory}
            {#if searchQuery} • {/if}Category: {currentCategory}
          {/if}
          {#if currentFileType}
            {#if searchQuery || currentCategory} • {/if}Type: {currentFileType}
          {/if}
          - Found {files.length} file{files.length !== 1 ? 's' : ''}
        </span>
      </div>
    {/if}

    <!-- Files Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {#each files as file (file.id)}
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="flex items-start justify-between mb-2">
              <div class="text-3xl">{getFileIcon(file.file_type)}</div>
              <span class="badge {getCategoryColor(file.category)}">
                {file.category.charAt(0).toUpperCase() + file.category.slice(1)}
              </span>
            </div>
            
            <h3 class="card-title text-lg">{file.name}</h3>
            <p class="text-sm text-base-content/70 mb-2">{file.original_filename}</p>
            
            {#if file.description}
              <p class="text-base-content/70 text-sm mb-3">{file.description}</p>
            {/if}
            
            <div class="text-xs text-base-content/50 space-y-1 mb-4">
              <div>Type: {file.file_type.charAt(0).toUpperCase() + file.file_type.slice(1)}</div>
              <div>Size: {file.file_size}</div>
              <div>Uploaded: {file.created_at}</div>
            </div>
            
            <div class="card-actions justify-end">
              {#if file.previewable}
                <button 
                  class="btn btn-sm btn-ghost"
                  onclick={() => previewFile(file.id)}
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                  </svg>
                  Preview
                </button>
              {/if}
              
              <button 
                class="btn btn-sm btn-ghost"
                onclick={() => downloadFile(file.id)}
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                </svg>
                Download
              </button>
              
              <button 
                class="btn btn-sm btn-error"
                onclick={() => deleteFile(file.id)}
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                </svg>
                Delete
              </button>
            </div>
          </div>
        </div>
      {/each}
    </div>

    <!-- Empty State -->
    {#if files.length === 0}
      <div class="text-center py-12">
        <div class="text-6xl mb-4">📁</div>
        <h3 class="text-xl font-semibold mb-2">
          {searchQuery || currentCategory || currentFileType ? 'No files found' : 'No files uploaded yet'}
        </h3>
        <p class="text-base-content/70 mb-4">
          {searchQuery || currentCategory || currentFileType 
            ? 'Try adjusting your search or filters' 
            : 'Upload your first file to get started!'}
        </p>
        {#if !searchQuery && !currentCategory && !currentFileType}
          <button 
            class="btn btn-primary"
            onclick={() => showUploadForm = true}
          >
            Upload Your First File
          </button>
        {/if}
      </div>
    {/if}
  {/snippet}
</Layout> 