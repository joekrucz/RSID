<script>
  import { router } from '@inertiajs/svelte';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';

  let { user, grant_competition, grant_applications } = $props();

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

  function getStageBadgeClass(stage) {
    const stageClasses = {
      'client_acquisition_project_qualification': 'badge-neutral',
      'client_invoiced': 'badge-info',
      'invoice_paid': 'badge-primary',
      'preparing_for_kick_off_aml_resourcing': 'badge-warning',
      'kicked_off_in_progress': 'badge-warning',
      'submitted': 'badge-success',
      'awaiting_funding_decision': 'badge-info',
      'application_successful_or_not_successful': 'badge-success',
      'resub_due': 'badge-error',
      'success_fee_invoiced': 'badge-primary',
      'success_fee_paid': 'badge-success'
    };
    return stageClasses[stage] || 'badge-neutral';
  }
</script>

<Layout {user}>
  <div class="container mx-auto px-4 py-8">
    <!-- Back Button -->
    <div class="mb-6">
      <button
        class="btn btn-outline btn-sm"
        onclick={() => router.visit('/grant_competitions')}
      >
        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
        </svg>
        Back to Competitions
      </button>
    </div>

    <!-- Competition Header -->
    <div class="card bg-base-100 shadow-sm border border-base-300 mb-8">
      <div class="card-body">
        <div class="flex flex-col lg:flex-row lg:items-start justify-between gap-6">
          <!-- Competition Info -->
          <div class="flex-1">
            <div class="flex items-start gap-3 mb-4">
              <div class="badge {getStatusBadgeClass(grant_competition)} text-sm">
                {getStatusText(grant_competition)}
              </div>
            </div>
            
            <h1 class="text-3xl font-bold text-base-content mb-4">
              {grant_competition.grant_name}
            </h1>
            
            <div class="space-y-3">
              <div class="flex items-center gap-3">
                <svg class="w-5 h-5 text-base-content/70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                </svg>
                <div>
                  <span class="text-sm font-medium text-base-content/70">Funding Body:</span>
                  <span class="ml-2 text-base-content font-medium">{grant_competition.funding_body}</span>
                </div>
              </div>
              
              <div class="flex items-center gap-3">
                <svg class="w-5 h-5 text-base-content/70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                </svg>
                <div>
                  <span class="text-sm font-medium text-base-content/70">Deadline:</span>
                  <span class="ml-2 text-base-content font-medium">{formatDateTime(grant_competition.deadline)}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex flex-col gap-2">
            <a
              href={grant_competition.competition_link}
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-primary"
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
              </svg>
              View Competition
            </a>
            <button
              class="btn btn-outline"
              onclick={() => router.visit('/grant_applications/new')}
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
              </svg>
              New Application
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Applications Section -->
    <div class="card bg-base-100 shadow-sm border border-base-300">
      <div class="card-body">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-xl font-semibold text-base-content">
            Grant Applications ({grant_applications.length})
          </h2>
        </div>

        {#if grant_applications.length > 0}
          <div class="overflow-x-auto">
            <table class="table table-zebra w-full">
              <thead>
                <tr>
                  <th class="text-base-content/70">Title</th>
                  <th class="text-base-content/70">Company</th>
                  <th class="text-base-content/70">Stage</th>
                  <th class="text-base-content/70">Documents</th>
                  <th class="text-base-content/70">Created</th>
                  <th class="text-base-content/70">Actions</th>
                </tr>
              </thead>
              <tbody>
                {#each grant_applications as application}
                  <tr class="hover">
                    <td>
                      <div class="font-medium text-base-content">{application.title}</div>
                      <div class="text-sm text-base-content/70 line-clamp-2">
                        {application.description}
                      </div>
                    </td>
                    <td>
                      {#if application.company}
                        <a
                          href="/companies/{application.company.id}"
                          class="link link-primary hover:link-hover"
                        >
                          {application.company.name}
                        </a>
                      {:else}
                        <span class="text-base-content/50">No company</span>
                      {/if}
                    </td>
                    <td>
                      <div class="badge {getStageBadgeClass(application.stage)}">
                        {application.stage_human}
                      </div>
                    </td>
                    <td>
                      <span class="text-base-content/70">{application.documents_count}</span>
                    </td>
                    <td>
                      <span class="text-base-content/70">{formatDate(application.created_at)}</span>
                    </td>
                    <td>
                      <button
                        class="btn btn-ghost btn-sm"
                        onclick={() => router.visit(`/grant_applications/${application.id}`)}
                      >
                        View
                      </button>
                    </td>
                  </tr>
                {/each}
              </tbody>
            </table>
          </div>
        {:else}
          <div class="text-center py-8">
            <svg class="w-12 h-12 mx-auto text-base-content/30 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            <h3 class="text-lg font-medium text-base-content mb-2">No applications yet</h3>
            <p class="text-base-content/70 mb-4">No grant applications have been created for this competition.</p>
            <button
              class="btn btn-primary"
              onclick={() => router.visit('/grant_applications/new')}
            >
              Create First Application
            </button>
          </div>
        {/if}
      </div>
    </div>
  </div>
</Layout>
