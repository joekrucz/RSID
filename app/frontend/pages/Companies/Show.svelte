<script>
  import { router } from '@inertiajs/svelte';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  let { user, company, grant_applications = [], rnd_claims = [] } = $props();
  function back(){ router.visit('/companies'); }
  
  function formatStageName(stage) {
    return stage.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
  }
  
</script>

<Layout {user}>
  <div class="max-w-4xl mx-auto">
    <Button variant="secondary" onclick={back} class="mb-4">← Back to Companies</Button>
    <div class="bg-base-100 rounded-lg shadow border p-6 space-y-3">
      <h1 class="text-3xl font-bold">{company.name}</h1>
      {#if company.website}
        <div>
          <span class="font-medium">Website:</span>
          <a href={company.website} target="_blank" rel="noopener noreferrer" class="link link-primary ml-1">{company.website}</a>
        </div>
      {/if}
      {#if company.notes}
        <div>
          <span class="font-medium">Notes:</span>
          <p class="mt-1 whitespace-pre-wrap">{company.notes}</p>
        </div>
      {/if}
      <div class="text-sm opacity-70">Added {company.created_at}</div>
    </div>
    
    <!-- Grant Applications Section -->
    <div class="mt-8">
      <h2 class="text-2xl font-bold mb-4">Grant Applications ({grant_applications.length})</h2>
      
      {#if grant_applications.length > 0}
        <div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
          <div class="overflow-x-auto">
            <table class="table table-zebra w-full">
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Stage</th>
                  <th>Deadline</th>
                  <th>Created</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {#each grant_applications as application}
                  <tr class={application.overdue ? 'bg-error/10' : ''}>
                    <td>
                      <div class="flex items-center space-x-3">
                        <div>
                          <div class="font-bold">
                            <a class="link link-hover" href={`/grant_applications/${application.id}`}>
                              {application.title}
                            </a>
                          </div>
                          <div class="text-sm opacity-70 line-clamp-2">{application.description}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div class="badge {application.stage_badge_class}" title="{formatStageName(application.stage)}">
                        {formatStageName(application.stage)}
                      </div>
                      {#if application.overdue}
                        <div class="badge badge-error badge-sm mt-1">Overdue</div>
                      {/if}
                    </td>
                    <td>
                      <div class="text-sm">
                        {application.deadline || 'No deadline set'}
                      </div>
                      {#if application.days_until_deadline !== null}
                        <div class="text-xs opacity-50">
                          {application.days_until_deadline > 0 
                            ? `${application.days_until_deadline} days left`
                            : application.days_until_deadline < 0 
                              ? `${Math.abs(application.days_until_deadline)} days overdue`
                              : 'Due today'
                          }
                        </div>
                      {/if}
                    </td>
                    <td>
                      <div class="text-sm">{application.created_at}</div>
                    </td>
                    <td>
                      <div class="flex items-center space-x-2">
                        <button 
                          class="btn btn-ghost btn-xs"
                          onclick={() => router.visit(`/grant_applications/${application.id}`)}
                        >
                          View
                        </button>
                        <button 
                          class="btn btn-ghost btn-xs"
                          onclick={() => router.visit(`/grant_applications/${application.id}/edit`)}
                        >
                          Edit
                        </button>
                      </div>
                    </td>
                  </tr>
                {/each}
              </tbody>
            </table>
          </div>
        </div>
      {:else}
        <div class="bg-base-100 rounded-lg shadow border border-base-300 p-8 text-center">
          <svg class="mx-auto h-12 w-12 text-base-content/30 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
          </svg>
          <h3 class="text-lg font-medium text-base-content mb-2">No grant applications</h3>
          <p class="text-base-content/70 mb-4">
            This company doesn't have any grant applications yet.
          </p>
          <Button variant="primary" onclick={() => router.visit('/grant_applications/new')}>
            Create Grant Application
          </Button>
        </div>
      {/if}
    </div>
    
    <!-- R&D Claims Section -->
    <div class="mt-8">
      <h2 class="text-2xl font-bold mb-4">R&D Claims ({rnd_claims.length})</h2>
      
      {#if rnd_claims.length > 0}
        <div class="bg-base-100 rounded-lg shadow border border-base-300 overflow-hidden">
          <div class="overflow-x-auto">
            <table class="table table-zebra w-full">
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Expenditure</th>
                  <th>Created</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {#each rnd_claims as claim}
                  <tr>
                    <td>
                      <div class="flex items-center space-x-3">
                        <div class="avatar placeholder">
                          <div class="bg-primary text-primary-content rounded-full w-8">
                            <span class="text-xs">R&D</span>
                          </div>
                        </div>
                        <div>
                          <div class="font-bold">
                            <a class="link link-hover" href={`/rnd_claims/${claim.id}`}>
                              {claim.title}
                            </a>
                          </div>
                          <div class="text-sm opacity-70 line-clamp-2">{claim.qualifying_activities}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div class="font-medium">£{claim.total_expenditure.toLocaleString()}</div>
                    </td>
                    <td>
                      <div class="text-sm">{claim.created_at}</div>
                    </td>
                    <td>
                      <div class="flex items-center space-x-2">
                        <button 
                          class="btn btn-ghost btn-xs"
                          onclick={() => router.visit(`/rnd_claims/${claim.id}`)}
                        >
                          View
                        </button>
                        <button 
                          class="btn btn-ghost btn-xs"
                          onclick={() => router.visit(`/rnd_claims/${claim.id}/edit`)}
                        >
                          Edit
                        </button>
                      </div>
                    </td>
                  </tr>
                {/each}
              </tbody>
            </table>
          </div>
        </div>
      {:else}
        <div class="bg-base-100 rounded-lg shadow border border-base-300 p-8 text-center">
          <svg class="mx-auto h-12 w-12 text-base-content/30 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"></path>
          </svg>
          <h3 class="text-lg font-medium text-base-content mb-2">No R&D claims</h3>
          <p class="text-base-content/70 mb-4">
            This company doesn't have any R&D claims yet.
          </p>
          <Button variant="primary" onclick={() => router.visit('/rnd_claims/new')}>
            Create R&D Claim
          </Button>
        </div>
      {/if}
    </div>
  </div>
</Layout>

