<!--
  Dashboard Index Page
  
  This is the main dashboard page that users see after logging in.
  It displays key statistics, recent activity, and quick access to main features.
  
  NOTE: This is a UI/UX mockup component. The layout and styling are designed
  to demonstrate the user experience for the real application.
  
  Key features:
  - User statistics and metrics
  - Recent activity feed
  - Quick navigation to main features
  - Feature-gated content based on user permissions
-->
<script>
  import Layout from '../../components/Layout.svelte';
  import FeatureGate from '../../components/FeatureGate.svelte';
  import { router } from '@inertiajs/svelte';
  
  // Props passed from the Rails controller
  let { user, stats, recent_activity } = $props();
  
  // Utility functions for styling based on data values
  // These help maintain consistent visual hierarchy across the dashboard
  
  function getPriorityColor(priority) {
    switch (priority) {
      case 'high': return 'badge-error';
      case 'medium': return 'badge-warning';
      case 'low': return 'badge-success';
      default: return 'badge-neutral';
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
  
  // Navigation helper using Inertia.js router
  function navigateTo(path) {
    router.visit(path);
  }
</script>

<svelte:head>
  <title>Dashboard - RSID App</title>
</svelte:head>

<Layout {user} currentPage="dashboard">
  {#snippet children()}
    <!-- Welcome Section -->
    <div class="mb-8">
      <h1 class="text-4xl font-bold text-base-content mb-2">Welcome back, {user.name}! 👋</h1>
      <p class="text-base-content/70">Here's what's happening with your productivity today.</p>
    </div>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-4 mb-8">
      
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-info">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
          </svg>
        </div>
        <div class="stat-title">Progress</div>
        <div class="stat-value text-info">{stats.completion_rate}%</div>
        <div class="stat-desc">Todo completion rate</div>
      </div>
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-success">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
          </svg>
        </div>
        <div class="stat-title">Clients</div>
        <div class="stat-value text-success">{stats.clients}</div>
        <div class="stat-desc">Total clients</div>
      </div>
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-warning">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
          </svg>
        </div>
        <div class="stat-title">Grant Applications</div>
        <div class="stat-value text-warning">{stats.grant_applications}</div>
        <div class="stat-desc">{stats.grant_applications_draft} draft, {stats.grant_applications_submitted} submitted</div>
      </div>
      
      <FeatureGate feature="rnd_claims">
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-figure text-error">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"></path>
            </svg>
          </div>
          <div class="stat-title">R&D Claims</div>
          <div class="stat-value text-error">{stats.rnd_claims}</div>
          <div class="stat-desc">{stats.rnd_claims_draft} draft, {stats.rnd_claims_ready_for_claim} ready</div>
          <div class="stat-desc text-xs">Total value: {stats.rnd_claims_total_value ? new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP' }).format(stats.rnd_claims_total_value) : '£0'}</div>
        </div>
      </FeatureGate>
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-info">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
          </svg>
        </div>
        <div class="stat-title">Companies</div>
        <div class="stat-value text-info">{stats.companies}</div>
        <div class="stat-desc">Total companies</div>
      </div>
      
      <div class="stat bg-base-100 shadow rounded-lg">
        <div class="stat-figure text-accent">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
          </svg>
        </div>
        <div class="stat-title">Grant Competitions</div>
        <div class="stat-value text-accent">{stats.grant_competitions}</div>
        <div class="stat-desc">Available competitions</div>
      </div>
      
      {#if user.isAdmin}
        <div class="stat bg-base-100 shadow rounded-lg">
          <div class="stat-figure text-secondary">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"></path>
            </svg>
          </div>
          <div class="stat-title">People</div>
          <div class="stat-value text-secondary">{stats.people}</div>
          <div class="stat-desc">Total users</div>
        </div>
      {/if}
    </div>

    <!-- Content Summaries -->
    <div class="grid grid-cols-1 lg:grid-cols-4 gap-6 mb-8">


      <!-- Grant Applications Summary -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            Grant Applications Summary
          </h2>
          
          <div class="stats stats-vertical shadow">
            <div class="stat">
              <div class="stat-title">Total Applications</div>
              <div class="stat-value text-primary">{stats.grant_applications}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Draft</div>
              <div class="stat-value text-warning">{stats.grant_applications_draft}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Overdue</div>
              <div class="stat-value text-error">{stats.grant_applications_overdue}</div>
            </div>
          </div>
          
          <div class="card-actions justify-end">
            <button onclick={() => navigateTo('/grant_applications')} class="btn btn-primary btn-sm">View All Applications</button>
          </div>
        </div>
      </div>

      <!-- R&D Claims Summary -->
      <FeatureGate feature="rnd_claims">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"></path>
              </svg>
              R&D Claims Summary
            </h2>
            
            <div class="stats stats-vertical shadow">
              <div class="stat">
                <div class="stat-title">Total Claims</div>
                <div class="stat-value text-primary">{stats.rnd_claims}</div>
              </div>
              
              <div class="stat">
                <div class="stat-title">Draft</div>
                <div class="stat-value text-warning">{stats.rnd_claims_draft}</div>
              </div>
              
              <div class="stat">
                <div class="stat-title">Ready for Claim</div>
                <div class="stat-value text-success">{stats.rnd_claims_ready_for_claim}</div>
              </div>
              
              <div class="stat">
                <div class="stat-title">Total Value</div>
                <div class="stat-value text-accent text-lg">{stats.rnd_claims_total_value ? new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP' }).format(stats.rnd_claims_total_value) : '£0'}</div>
              </div>
            </div>
            
            <div class="card-actions justify-end">
              <button onclick={() => navigateTo('/rnd_claims')} class="btn btn-primary btn-sm">View All Claims</button>
            </div>
          </div>
        </div>
      </FeatureGate>

      <!-- Companies Summary -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
            </svg>
            Companies Summary
          </h2>
          
          <div class="stats stats-vertical shadow">
            <div class="stat">
              <div class="stat-title">Total Companies</div>
              <div class="stat-value text-primary">{stats.companies}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">With Websites</div>
              <div class="stat-value text-secondary">{stats.companies_with_websites || 0}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Recent</div>
              <div class="stat-value text-accent text-lg">{stats.companies_recent || 0}</div>
            </div>
          </div>
          
          <div class="card-actions justify-end">
            <button onclick={() => navigateTo('/companies')} class="btn btn-primary btn-sm">View All Companies</button>
          </div>
        </div>
      </div>

      <!-- Grant Competitions Summary -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            Grant Competitions Summary
          </h2>
          
          <div class="stats stats-vertical shadow">
            <div class="stat">
              <div class="stat-title">Total Competitions</div>
              <div class="stat-value text-primary">{stats.grant_competitions}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Active</div>
              <div class="stat-value text-secondary">{stats.grant_competitions_active || 0}</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Upcoming Deadlines</div>
              <div class="stat-value text-accent text-lg">{stats.grant_competitions_upcoming || 0}</div>
            </div>
          </div>
          
          <div class="card-actions justify-end">
            <button onclick={() => navigateTo('/grant_competitions')} class="btn btn-primary btn-sm">View All Competitions</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Activity -->
    <div class="card bg-base-100 shadow-xl mb-8">
      <div class="card-body">
        <h2 class="card-title">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
          </svg>
          Recent Activity
        </h2>
        
        <div class="space-y-4">


          <!-- Recent Grant Applications -->
          {#if recent_activity.grant_applications && recent_activity.grant_applications.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">📋 Recent Grant Applications</h3>
              <div class="space-y-2">
                {#each recent_activity.grant_applications as application}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div class="flex items-center gap-3">
                      <div class="text-2xl">📄</div>
                      <div>
                        <div class="font-medium">{application.title}</div>
                        <div class="text-sm text-base-content/70">
                          {#if application.grant_competition?.deadline}
                            <span class="text-xs">Deadline: {application.grant_competition.deadline}</span>
                          {/if}
                        </div>
                      </div>
                    </div>
                    <button onclick={() => navigateTo(`/grant_applications/${application.id}`)} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          <!-- Recent R&D Claims -->
          <FeatureGate feature="rnd_claims">
            {#if recent_activity.rnd_claims && recent_activity.rnd_claims.length > 0}
              <div>
                <h3 class="text-lg font-semibold mb-2">🔬 Recent R&D Claims</h3>
                <div class="space-y-2">
                  {#each recent_activity.rnd_claims as claim}
                    <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                      <div class="flex items-center gap-3">
                        <div class="text-2xl">🧪</div>
                        <div>
                          <div class="font-medium">{claim.title}</div>
                          <div class="text-sm text-base-content/70">
                            <span class="text-xs">£{claim.total_expenditure}</span>
                          </div>
                        </div>
                      </div>
                      <button onclick={() => navigateTo(`/rnd_claims/${claim.id}`)} class="btn btn-ghost btn-sm">View</button>
                    </div>
                  {/each}
                </div>
              </div>
            {/if}
          </FeatureGate>

          <!-- Recent Companies -->
          {#if recent_activity.companies && recent_activity.companies.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">🏢 Recent Companies</h3>
              <div class="space-y-2">
                {#each recent_activity.companies as company}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div class="flex items-center gap-3">
                      <div class="text-2xl">🏢</div>
                      <div>
                        <div class="font-medium">{company.name}</div>
                        <div class="text-sm text-base-content/70">
                          {#if company.website}
                            <span class="text-xs">Website: {company.website}</span>
                          {/if}
                        </div>
                      </div>
                    </div>
                    <button onclick={() => navigateTo(`/companies/${company.id}`)} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          <!-- Recent Grant Competitions -->
          {#if recent_activity.grant_competitions && recent_activity.grant_competitions.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">🏆 Recent Grant Competitions</h3>
              <div class="space-y-2">
                {#each recent_activity.grant_competitions as competition}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div class="flex items-center gap-3">
                      <div class="text-2xl">🏆</div>
                      <div>
                        <div class="font-medium">{competition.grant_name}</div>
                        <div class="text-sm text-base-content/70">
                          <span class="text-xs">Funding Body: {competition.funding_body}</span>
                          {#if competition.deadline}
                            <span class="text-xs ml-2">Deadline: {competition.deadline}</span>
                          {/if}
                        </div>
                      </div>
                    </div>
                    <button onclick={() => navigateTo(`/grant_competitions/${competition.id}`)} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          <!-- Recent People (Admin only) -->
          {#if user.isAdmin && recent_activity.people && recent_activity.people.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">👥 Recent People</h3>
              <div class="space-y-2">
                {#each recent_activity.people as person}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div class="flex items-center gap-3">
                      <div class="text-2xl">👤</div>
                      <div>
                        <div class="font-medium">{person.name}</div>
                        <div class="text-sm text-base-content/70">
                          <span class="text-xs">Email: {person.email}</span>
                          <span class="text-xs ml-2">Role: {person.role}</span>
                        </div>
                      </div>
                    </div>
                    <button onclick={() => navigateTo(`/people/${person.id}`)} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          <!-- Recent Clients -->
          {#if recent_activity.clients && recent_activity.clients.length > 0}
            <div>
              <h3 class="text-lg font-semibold mb-2">👥 Recent Clients</h3>
              <div class="space-y-2">
                {#each recent_activity.clients as client}
                  <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                    <div class="flex items-center gap-3">
                      <div class="text-2xl">👤</div>
                      <div>
                        <div class="font-medium">{client.name}</div>
                        <div class="text-sm text-base-content/70">
                          <span class="badge badge-outline mr-2">{client.sector}</span>
                          {client.company}
                        </div>
                      </div>
                    </div>
                    <button onclick={() => navigateTo('/people')} class="btn btn-ghost btn-sm">View</button>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          {#if (!recent_activity.clients || recent_activity.clients.length === 0) && (!recent_activity.grant_applications || recent_activity.grant_applications.length === 0) && (!recent_activity.companies || recent_activity.companies.length === 0) && (!recent_activity.grant_competitions || recent_activity.grant_competitions.length === 0) && (!recent_activity.people || recent_activity.people.length === 0)}
            <div class="text-center py-8">
              <div class="text-4xl mb-4">🚀</div>
              <h3 class="text-lg font-semibold mb-2">No recent activity</h3>
              <p class="text-base-content/70">Start managing grant applications and working with companies to see your activity here!</p>
            </div>
          {/if}
        </div>
      </div>
    </div>

  {/snippet}
</Layout> 