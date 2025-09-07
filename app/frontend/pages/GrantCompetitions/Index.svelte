<script>
  import { router } from '@inertiajs/svelte';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';

  let { user, grant_competitions, filters, stats } = $props();

  let statusFilter = $state(filters.status || 'all');
  let fundingBodyFilter = $state(filters.funding_body || '');

  function filterByStatus(status) {
    statusFilter = status;
    loadCompetitions();
  }

  function filterByFundingBody() {
    loadCompetitions();
  }

  function clearFilters() {
    statusFilter = 'all';
    fundingBodyFilter = '';
    loadCompetitions();
  }

  function loadCompetitions() {
    const params = new URLSearchParams();
    if (statusFilter !== 'all') params.set('status', statusFilter);
    if (fundingBodyFilter.trim()) params.set('funding_body', fundingBodyFilter);

    const queryString = params.toString();
    const url = queryString ? `/grant_competitions?${queryString}` : '/grant_competitions';

    router.get(url, {}, {
      preserveState: true,
      preserveScroll: true
    });
  }

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString('en-GB', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  }

  function formatDateTime(dateString) {
    return new Date(dateString).toLocaleString('en-GB', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  function getStatusBadgeClass(competition) {
    if (competition.upcoming) {
      if (competition.days_until_deadline <= 7) {
        return 'badge-error';
      } else if (competition.days_until_deadline <= 30) {
        return 'badge-warning';
      } else {
        return 'badge-success';
      }
    } else {
      return 'badge-neutral';
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

<Layout {user}>
  <div class="container mx-auto px-4 py-8">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
      <div>
        <h1 class="text-3xl font-bold text-base-content">Grant Competitions</h1>
        <p class="text-base-content/70 mt-2">Browse and manage grant competitions</p>
      </div>
      <div class="flex items-center gap-4">
        <div class="stats shadow">
          <div class="stat">
            <div class="stat-title">Total</div>
            <div class="stat-value text-primary">{stats.total}</div>
          </div>
          <div class="stat">
            <div class="stat-title">Upcoming</div>
            <div class="stat-value text-success">{stats.upcoming}</div>
          </div>
          <div class="stat">
            <div class="stat-title">Past</div>
            <div class="stat-value text-neutral">{stats.past}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Filters -->
    <div class="card bg-base-100 shadow-sm border border-base-300 mb-6">
      <div class="card-body">
        <div class="flex flex-col sm:flex-row gap-4">
          <!-- Status Filter -->
          <div class="form-control">
            <label class="label">
              <span class="label-text font-medium">Status</span>
            </label>
            <select 
              class="select select-bordered w-full sm:w-48"
              bind:value={statusFilter}
              onchange={() => filterByStatus(statusFilter)}
            >
              <option value="all">All Competitions</option>
              <option value="upcoming">Upcoming</option>
              <option value="past">Past</option>
            </select>
          </div>

          <!-- Funding Body Filter -->
          <div class="form-control flex-1">
            <label class="label">
              <span class="label-text font-medium">Funding Body</span>
            </label>
            <div class="flex gap-2">
              <input
                type="text"
                placeholder="Filter by funding body..."
                class="input input-bordered flex-1"
                bind:value={fundingBodyFilter}
                onkeyup={(e) => e.key === 'Enter' && filterByFundingBody()}
              />
              <button
                class="btn btn-primary"
                onclick={filterByFundingBody}
              >
                Filter
              </button>
            </div>
          </div>

          <!-- Clear Filters -->
          <div class="form-control">
            <label class="label">
              <span class="label-text opacity-0">Clear</span>
            </label>
            <button
              class="btn btn-outline"
              onclick={clearFilters}
            >
              Clear
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Competitions List -->
    <div class="grid gap-4">
      {#each grant_competitions as competition}
        <div class="card bg-base-100 shadow-sm border border-base-300 hover:shadow-md transition-shadow">
          <div class="card-body">
            <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
              <!-- Competition Info -->
              <div class="flex-1">
                <div class="flex items-start gap-3">
                  <div class="badge {getStatusBadgeClass(competition)}">
                    {getStatusText(competition)}
                  </div>
                  <div>
                    <h3 class="text-xl font-semibold text-base-content mb-2">
                      {competition.grant_name}
                    </h3>
                    <div class="space-y-1 text-sm text-base-content/70">
                      <div class="flex items-center gap-2">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                        </svg>
                        <span class="font-medium">{competition.funding_body}</span>
                      </div>
                      <div class="flex items-center gap-2">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                        </svg>
                        <span>Deadline: {formatDateTime(competition.deadline)}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Actions -->
              <div class="flex items-center gap-2">
                <a
                  href={competition.competition_link}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-outline btn-sm"
                >
                  <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
                  </svg>
                  View Competition
                </a>
                <button
                  class="btn btn-primary btn-sm"
                  onclick={() => router.visit(`/grant_competitions/${competition.id}`)}
                >
                  View Details
                </button>
              </div>
            </div>
          </div>
        </div>
      {/each}
    </div>

    <!-- Empty State -->
    {#if grant_competitions.length === 0}
      <div class="text-center py-12">
        <svg class="w-16 h-16 mx-auto text-base-content/30 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
        </svg>
        <h3 class="text-lg font-medium text-base-content mb-2">No competitions found</h3>
        <p class="text-base-content/70">Try adjusting your filters or check back later.</p>
      </div>
    {/if}
  </div>
</Layout>
