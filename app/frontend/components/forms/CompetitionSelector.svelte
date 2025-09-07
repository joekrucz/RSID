<script>
  import { onMount } from 'svelte';

  let { competitions = [], selectedCompetition = null, onSelect, placeholder = "Search competitions..." } = $props();

  let searchTerm = $state('');
  let filteredCompetitions = $state([]);
  let showDropdown = $state(false);
  let highlightedIndex = $state(-1);

  // Filter competitions based on search term
  function filterCompetitions() {
    if (!searchTerm.trim()) {
      filteredCompetitions = competitions;
      return;
    }

    const term = searchTerm.toLowerCase();
    filteredCompetitions = competitions.filter(competition => 
      competition.grant_name.toLowerCase().includes(term) ||
      competition.funding_body.toLowerCase().includes(term)
    );
  }

  // Handle input changes
  function handleInput() {
    filterCompetitions();
    showDropdown = true;
    highlightedIndex = -1;
  }

  // Handle focus
  function handleFocus() {
    filterCompetitions();
    showDropdown = true;
  }

  // Handle blur
  function handleBlur() {
    // Delay hiding dropdown to allow for clicks
    setTimeout(() => {
      showDropdown = false;
    }, 200);
  }

  // Select a competition
  function selectCompetition(competition) {
    selectedCompetition = competition;
    searchTerm = competition.grant_name;
    showDropdown = false;
    highlightedIndex = -1;
    
    if (onSelect) {
      onSelect(competition);
    }
  }

  // Clear selection
  function clearSelection() {
    selectedCompetition = null;
    searchTerm = '';
    filteredCompetitions = competitions;
    showDropdown = false;
    highlightedIndex = -1;
    
    if (onSelect) {
      onSelect(null);
    }
  }

  // Handle keyboard navigation
  function handleKeydown(event) {
    if (!showDropdown) return;

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        highlightedIndex = Math.min(highlightedIndex + 1, filteredCompetitions.length - 1);
        break;
      case 'ArrowUp':
        event.preventDefault();
        highlightedIndex = Math.max(highlightedIndex - 1, -1);
        break;
      case 'Enter':
        event.preventDefault();
        if (highlightedIndex >= 0 && highlightedIndex < filteredCompetitions.length) {
          selectCompetition(filteredCompetitions[highlightedIndex]);
        }
        break;
      case 'Escape':
        showDropdown = false;
        highlightedIndex = -1;
        break;
    }
  }

  // Initialize with selected competition
  onMount(() => {
    if (selectedCompetition) {
      searchTerm = selectedCompetition.grant_name;
    }
    filterCompetitions();
  });

  // Update search term when selected competition changes
  $effect(() => {
    if (selectedCompetition) {
      searchTerm = selectedCompetition.grant_name;
    } else {
      searchTerm = '';
    }
    filterCompetitions();
  });

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString('en-GB', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  }

  function getStatusBadgeClass(competition) {
    if (competition.upcoming) {
      if (competition.days_until_deadline <= 7) {
        return 'badge-error badge-sm';
      } else if (competition.days_until_deadline <= 30) {
        return 'badge-warning badge-sm';
      } else {
        return 'badge-success badge-sm';
      }
    } else {
      return 'badge-neutral badge-sm';
    }
  }

  function getStatusText(competition) {
    if (competition.upcoming) {
      if (competition.days_until_deadline <= 0) {
        return 'Due Today';
      } else if (competition.days_until_deadline === 1) {
        return 'Due Tomorrow';
      } else {
        return `${competition.days_until_deadline} days left`;
      }
    } else {
      return 'Past Deadline';
    }
  }
</script>

<div class="form-control w-full">
  <label class="label" for="competition-selector">
    <span class="label-text font-medium">Grant Competition</span>
  </label>
  
  <div class="relative">
    <input
      id="competition-selector"
      type="text"
      class="input input-bordered w-full pr-10"
      placeholder={placeholder}
      bind:value={searchTerm}
      oninput={handleInput}
      onfocus={handleFocus}
      onblur={handleBlur}
      onkeydown={handleKeydown}
      aria-label="Search and select a grant competition"
      title="Type to search competitions"
    />
    
    <!-- Clear button -->
    {#if selectedCompetition}
      <button
        type="button"
        class="absolute right-8 top-1/2 transform -translate-y-1/2 text-base-content/50 hover:text-base-content"
        onclick={clearSelection}
        title="Clear selection"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </button>
    {/if}
    
    <!-- Dropdown arrow -->
    <div class="absolute right-3 top-1/2 transform -translate-y-1/2 text-base-content/50 pointer-events-none">
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
      </svg>
    </div>

    <!-- Dropdown -->
    {#if showDropdown && filteredCompetitions.length > 0}
      <div class="absolute z-50 w-full mt-1 bg-base-100 border border-base-300 rounded-lg shadow-lg max-h-60 overflow-y-auto">
        {#each filteredCompetitions as competition, index}
          <button
            type="button"
            class="w-full px-4 py-3 text-left hover:bg-base-200 focus:bg-base-200 focus:outline-none {index === highlightedIndex ? 'bg-base-200' : ''}"
            onclick={() => selectCompetition(competition)}
            onmouseenter={() => highlightedIndex = index}
          >
            <div class="flex items-start justify-between gap-3">
              <div class="flex-1 min-w-0">
                <div class="font-medium text-base-content truncate">
                  {competition.grant_name}
                </div>
                <div class="text-sm text-base-content/70 truncate">
                  {competition.funding_body}
                </div>
                <div class="text-xs text-base-content/50">
                  Deadline: {formatDate(competition.deadline)}
                </div>
              </div>
              <div class="flex-shrink-0">
                <div class="badge {getStatusBadgeClass(competition)}">
                  {getStatusText(competition)}
                </div>
              </div>
            </div>
          </button>
        {/each}
      </div>
    {/if}

    <!-- No results -->
    {#if showDropdown && searchTerm.trim() && filteredCompetitions.length === 0}
      <div class="absolute z-50 w-full mt-1 bg-base-100 border border-base-300 rounded-lg shadow-lg">
        <div class="px-4 py-3 text-base-content/70 text-center">
          No competitions found for "{searchTerm}"
        </div>
      </div>
    {/if}
  </div>
</div>
