<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Checklist from '../../components/Checklist.svelte';
  
  let { user, grant_application } = $props();
  const stages = [
    'client_acquisition_project_qualification',
    'client_invoiced',
    'invoice_paid',
    'preparing_for_kick_off_aml_resourcing',
    'kicked_off_in_progress',
    'submitted',
    'awaiting_funding_decision',
    'application_successful_or_not_successful',
    'resub_due',
    'success_fee_invoiced',
    'success_fee_paid'
  ];
  let currentStage = $state(grant_application.stage || 'pre_delivery');
  let loading = $state(false);
  let stageLoading = $state(false);
  const idxCurrent = $derived(stages.indexOf(currentStage));

  const stageStyles = {
    client_acquisition_project_qualification: { inactive: 'bg-secondary/20 text-secondary', active: 'bg-secondary text-secondary-content', complete: 'bg-secondary text-secondary-content', fillInactive: 'fill-secondary/20', fillActive: 'fill-secondary', fillComplete: 'fill-secondary' },
    client_invoiced: { inactive: 'bg-warning/20 text-warning', active: 'bg-warning text-warning-content', complete: 'bg-warning text-warning-content', fillInactive: 'fill-warning/20', fillActive: 'fill-warning', fillComplete: 'fill-warning' },
    invoice_paid: { inactive: 'bg-success/20 text-success', active: 'bg-success text-success-content', complete: 'bg-success text-success-content', fillInactive: 'fill-success/20', fillActive: 'fill-success', fillComplete: 'fill-success' },
    preparing_for_kick_off_aml_resourcing: { inactive: 'bg-info/20 text-info', active: 'bg-info text-info-content', complete: 'bg-info text-info-content', fillInactive: 'fill-info/20', fillActive: 'fill-info', fillComplete: 'fill-info' },
    kicked_off_in_progress: { inactive: 'bg-primary/20 text-primary', active: 'bg-primary text-primary-content', complete: 'bg-primary text-primary-content', fillInactive: 'fill-primary/20', fillActive: 'fill-primary', fillComplete: 'fill-primary' },
    submitted: { inactive: 'bg-accent/20 text-accent', active: 'bg-accent text-accent-content', complete: 'bg-accent text-accent-content', fillInactive: 'fill-accent/20', fillActive: 'fill-accent', fillComplete: 'fill-accent' },
    awaiting_funding_decision: { inactive: 'bg-neutral/20 text-neutral', active: 'bg-neutral text-neutral-content', complete: 'bg-neutral text-neutral-content', fillInactive: 'fill-neutral/20', fillActive: 'fill-neutral', fillComplete: 'fill-neutral' },
    application_successful_or_not_successful: { inactive: 'bg-base-content/20 text-base-content', active: 'bg-base-content text-base-100', complete: 'bg-base-content text-base-100', fillInactive: 'fill-base-content/20', fillActive: 'fill-base-content', fillComplete: 'fill-base-content' },
    resub_due: { inactive: 'bg-error/20 text-error', active: 'bg-error text-error-content', complete: 'bg-error text-error-content', fillInactive: 'fill-error/20', fillActive: 'fill-error', fillComplete: 'fill-error' },
    success_fee_invoiced: { inactive: 'bg-warning/20 text-warning', active: 'bg-warning text-warning-content', complete: 'bg-warning text-warning-content', fillInactive: 'fill-warning/20', fillActive: 'fill-warning', fillComplete: 'fill-warning' },
    success_fee_paid: { inactive: 'bg-success/20 text-success', active: 'bg-success text-success-content', complete: 'bg-success text-success-content', fillInactive: 'fill-success/20', fillActive: 'fill-success', fillComplete: 'fill-success' }
  };
  
  
  
  function handleStageChange(targetStage) {
    if (targetStage === currentStage) return;
    stageLoading = true;
    
    fetch(`/grant_applications/${grant_application.id}/change_stage`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ stage: targetStage })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        currentStage = targetStage;
        toast.success(data.message || 'Stage updated successfully!');
        // Reload the page to get updated data
        router.reload();
      } else {
        toast.error(data.message || 'Failed to update stage.');
      }
    })
    .catch(error => {
      console.error('Error updating stage:', error);
      toast.error('Failed to update stage.');
    })
    .finally(() => {
      stageLoading = false;
    });
  }

  
  function handleDelete() {
    if (confirm('Are you sure you want to delete this grant application? This action cannot be undone.')) {
      router.delete(`/grant_applications/${grant_application.id}`, {
        onSuccess: () => {
          toast.success('Grant application deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete grant application.');
        }
      });
    }
  }
  
  function goBack() {
    router.visit('/grant_applications');
  }
  
  
  function formatDeadline(deadline) {
    if (!deadline) return 'No deadline set';
    return deadline;
  }
</script>

<Layout {user}>
    <div class="max-w-4xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <Button variant="secondary" onclick={goBack} class="mb-4">
          ← Back to Grant Applications
        </Button>
        
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-3xl font-bold text-base-content mb-2">{grant_application.title}</h1>
            <p class="text-base-content/70 mb-4">{grant_application.description}</p>
          </div>
          
          <div class="flex space-x-2">
            {#if grant_application.can_edit}
              <Button variant="secondary" onclick={() => router.visit(`/grant_applications/${grant_application.id}/edit`)}>
                Edit
              </Button>
            {/if}
            {#if grant_application.can_edit}
              <Button variant="error" onclick={handleDelete} disabled={loading}>
                Delete
              </Button>
            {/if}
          </div>
        </div>
      </div>
      <!-- Full-width Pipeline (Chevron Style with inline SVG) -->
      {#key currentStage}
      <div class="mt-2 w-full">
        <ul class="flex items-stretch w-full gap-0">
          {#each stages as s, i}
            {@const isComplete = idxCurrent > i}
            {@const isActive = idxCurrent === i}
            {@const palette = stageStyles[s] || { inactive: 'bg-base-300 text-base-content', active: 'bg-base-content text-base-100', complete: 'bg-base-content text-base-100', fillInactive: 'fill-base-300', fillActive: 'fill-base-content', fillComplete: 'fill-base-content' }}
            <li class="relative flex items-stretch flex-1 min-w-0">
              <button
                class={`h-6 px-2 rounded-l-md w-full ${isComplete ? palette.complete : isActive ? palette.active : palette.inactive}`}
                disabled={stageLoading}
                onclick={() => handleStageChange(s)}
                title={s.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                aria-current={currentStage === s ? 'step' : undefined}
              >
                <span class="sr-only">{s.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}</span>
              </button>
              {#if i < stages.length - 1}
                <svg class="h-6 w-2 -ml-px" viewBox="0 0 14 32" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                  <polygon points="0,0 14,16 0,32" class={isComplete ? palette.fillComplete : isActive ? palette.fillActive : palette.fillInactive} />
                </svg>
              {/if}
            </li>
          {/each}
        </ul>
        {#if stageLoading}
          <span class="loading loading-spinner loading-xs align-middle ml-2"></span>
        {/if}
      </div>
      {/key}
      
      <!-- Application Details (full width to match checklist) -->
      <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6 mt-6">
        <h2 class="text-xl font-semibold text-base-content mb-4">Application Details</h2>
        <div class="space-y-4">
          <div>
            <div class="text-sm font-medium mb-1">Deadline</div>
            <div class="text-sm">
              {formatDeadline(grant_application.deadline)}
            </div>
            {#if grant_application.days_until_deadline !== null}
              <div class="text-xs opacity-50 mt-1">
                {grant_application.days_until_deadline > 0 
                  ? `${grant_application.days_until_deadline} days left`
                  : grant_application.days_until_deadline < 0 
                    ? `${Math.abs(grant_application.days_until_deadline)} days overdue`
                    : 'Due today'
                }
              </div>
            {/if}
          </div>
          {#if grant_application.company}
            <div>
              <div class="text-sm font-medium mb-1">Company</div>
              <div class="text-sm">
                <a href={`/companies/${grant_application.company.id}`} class="link link-primary">
                  {grant_application.company.name}
                </a>
              </div>
            </div>
          {/if}
          {#if grant_application.grant_competition}
            <div>
              <div class="text-sm font-medium mb-1">Grant Competition</div>
              <div class="text-sm">
                <a href={`/grant_competitions/${grant_application.grant_competition.id}`} class="link link-primary">
                  {grant_application.grant_competition.grant_name}
                </a>
                <div class="text-xs text-base-content/70 mt-1">
                  {grant_application.grant_competition.funding_body}
                </div>
                <div class="text-xs text-base-content/70">
                  Deadline: {new Date(grant_application.grant_competition.deadline).toLocaleDateString('en-GB', {
                    day: '2-digit',
                    month: '2-digit',
                    year: 'numeric'
                  })}
                </div>
              </div>
            </div>
          {/if}
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <div class="text-sm font-medium mb-1">Created</div>
              <div class="text-sm">{grant_application.created_at}</div>
            </div>
            <div>
              <div class="text-sm font-medium mb-1">Last Updated</div>
              <div class="text-sm">{grant_application.updated_at}</div>
            </div>
          </div>
        </div>
      </div>
      <!-- Checklist Component -->
      <div class="mt-6">
        <h2 class="text-xl font-semibold text-gray-900 mb-3">Project Checklist</h2>
        <Checklist sections={[
          {
            title: 'Client Acquisition/Project Qualification',
            items: [
              { title: 'Project Qualification' },
              { title: 'Proposal Presented' },
              { title: 'Agreement Sent' },
              { title: 'New Project Handover Sent To Delivery' },
              { title: 'Deal marked as "won" / "lost"' }
            ]
          },
          {
            title: 'Client Invoiced',
            items: [ { title: 'Invoice Sent' } ]
          },
          {
            title: 'Invoice Paid',
            items: [ { title: 'Payment Received' } ]
          },
          {
            title: 'Preparing for Kick Off/AML/Resourcing',
            items: [
              { title: 'AML Checks Completed' },
              { title: 'Project Resourced' },
              { title: 'Project Set Up - Slack Channel, Delivery Folders, Etc.' }
            ]
          },
          {
            title: 'Kicked Off/In Progress',
            items: [
              { title: 'Kick Off Call Confirmed' },
              { title: 'Timeline Confirmed and Accepted by Client' },
              { title: 'Drafting' },
              { title: 'Reviews Confirmed' },
              { title: 'Eligibility Checks Completed' }
            ]
          },
          {
            title: 'Submitted',
            items: [ { title: 'Application Submitted' } ]
          },
          { title: 'Awaiting Funding Decision', items: [ { title: 'Completed' } ] },
          { title: 'Application Successful/Not Successful', items: [ { title: 'Completed' } ] },
          { title: 'Resub Due', items: [ { title: 'Completed' } ] },
          { title: 'Success Fee Invoiced', items: [ { title: 'Completed' } ] },
          { title: 'Success Fee Paid', items: [ { title: 'Completed' } ] }
        ]} />
      </div>
    </div>
</Layout> 