<script>
  let { companies = [], selectedCompany = null, onSelect, placeholder = "Search for a company...", error = null } = $props();
  
  let searchTerm = $state('');
  let filteredCompanies = $state([]);
  let showDropdown = $state(false);
  let highlightedIndex = $state(-1);
  let inputElement;
  
  // Initialize search term when selectedCompany changes
  $effect(() => {
    if (selectedCompany) {
      searchTerm = selectedCompany.name;
    }
  });
  
  function filterCompanies() {
    if (searchTerm.length > 0) {
      filteredCompanies = companies.filter(company => 
        company.name.toLowerCase().includes(searchTerm.toLowerCase())
      );
      showDropdown = filteredCompanies.length > 0;
    } else {
      filteredCompanies = [];
      showDropdown = false;
    }
    highlightedIndex = -1;
  }
  
  function handleInput() {
    if (selectedCompany && searchTerm !== selectedCompany.name) {
      selectedCompany = null;
    }
    filterCompanies();
  }
  
  function selectCompany(company) {
    selectedCompany = company;
    searchTerm = company.name;
    showDropdown = false;
    highlightedIndex = -1;
    onSelect?.(company);
  }
  
  function handleKeydown(event) {
    if (!showDropdown) return;
    
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        highlightedIndex = Math.min(highlightedIndex + 1, filteredCompanies.length - 1);
        break;
      case 'ArrowUp':
        event.preventDefault();
        highlightedIndex = Math.max(highlightedIndex - 1, -1);
        break;
      case 'Enter':
        event.preventDefault();
        if (highlightedIndex >= 0 && highlightedIndex < filteredCompanies.length) {
          selectCompany(filteredCompanies[highlightedIndex]);
        }
        break;
      case 'Escape':
        showDropdown = false;
        highlightedIndex = -1;
        break;
    }
  }
  
  function handleFocus() {
    if (searchTerm.length > 0) {
      filterCompanies();
    }
  }
  
  function handleBlur() {
    // Delay hiding dropdown to allow for clicks
    setTimeout(() => {
      showDropdown = false;
      highlightedIndex = -1;
    }, 150);
  }
  
  function clearSelection() {
    selectedCompany = null;
    searchTerm = '';
    showDropdown = false;
    highlightedIndex = -1;
    onSelect?.(null);
  }
</script>

  <div class="form-control relative">
  <label for="company-selector" class="label">
    <span class="label-text">Company</span>
  </label>
  
  <div class="relative">
    <input
      id="company-selector"
      bind:this={inputElement}
      type="text"
      placeholder={placeholder}
      class="input input-bordered w-full pr-10 {error ? 'input-error' : ''}"
      bind:value={searchTerm}
      oninput={handleInput}
      onkeydown={handleKeydown}
      onfocus={handleFocus}
      onblur={handleBlur}
    />
    
    {#if selectedCompany}
      <button
        type="button"
        class="absolute right-2 top-1/2 transform -translate-y-1/2 text-base-content/50 hover:text-base-content"
        onclick={clearSelection}
        title="Clear selection"
        aria-label="Clear company selection"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </button>
    {:else}
      <div class="absolute right-2 top-1/2 transform -translate-y-1/2 text-base-content/50">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
        </svg>
      </div>
    {/if}
  </div>
  
  {#if showDropdown && filteredCompanies.length > 0}
    <div class="absolute z-50 w-full mt-1 bg-base-100 border border-base-300 rounded-lg shadow-lg max-h-60 overflow-y-auto">
      {#each filteredCompanies as company, index}
        <button
          type="button"
          class="w-full px-4 py-2 text-left hover:bg-base-200 focus:bg-base-200 focus:outline-none {highlightedIndex === index ? 'bg-base-200' : ''}"
          onclick={() => selectCompany(company)}
          onmouseenter={() => highlightedIndex = index}
        >
          <div class="font-medium">{company.name}</div>
          {#if company.website}
            <div class="text-sm text-base-content/60">{company.website}</div>
          {/if}
        </button>
      {/each}
    </div>
  {/if}
  
  {#if searchTerm.length > 0 && filteredCompanies.length === 0}
    <div class="absolute z-50 w-full mt-1 bg-base-100 border border-base-300 rounded-lg shadow-lg p-4 text-center text-base-content/60">
      No companies found matching "{searchTerm}"
    </div>
  {/if}
  
  {#if error}
    <label class="label">
      <span class="label-text-alt text-error">{error}</span>
    </label>
  {/if}
</div>
