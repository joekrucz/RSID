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
    client_acquisition_project_qualification: { inactive: 'bg-pink-200 text-pink-900', active: 'bg-pink-500 text-white', complete: 'bg-pink-600 text-white', fillInactive: 'fill-pink-200', fillActive: 'fill-pink-500', fillComplete: 'fill-pink-600' },
    client_invoiced: { inactive: 'bg-amber-200 text-amber-900', active: 'bg-amber-500 text-white', complete: 'bg-amber-600 text-white', fillInactive: 'fill-amber-200', fillActive: 'fill-amber-500', fillComplete: 'fill-amber-600' },
    invoice_paid: { inactive: 'bg-emerald-200 text-emerald-900', active: 'bg-emerald-500 text-white', complete: 'bg-emerald-600 text-white', fillInactive: 'fill-emerald-200', fillActive: 'fill-emerald-500', fillComplete: 'fill-emerald-600' },
    preparing_for_kick_off_aml_resourcing: { inactive: 'bg-cyan-200 text-cyan-900', active: 'bg-cyan-500 text-white', complete: 'bg-cyan-600 text-white', fillInactive: 'fill-cyan-200', fillActive: 'fill-cyan-500', fillComplete: 'fill-cyan-600' },
    kicked_off_in_progress: { inactive: 'bg-indigo-200 text-indigo-900', active: 'bg-indigo-500 text-white', complete: 'bg-indigo-600 text-white', fillInactive: 'fill-indigo-200', fillActive: 'fill-indigo-500', fillComplete: 'fill-indigo-600' },
    submitted: { inactive: 'bg-blue-200 text-blue-900', active: 'bg-blue-500 text-white', complete: 'bg-blue-600 text-white', fillInactive: 'fill-blue-200', fillActive: 'fill-blue-500', fillComplete: 'fill-blue-600' },
    awaiting_funding_decision: { inactive: 'bg-sky-200 text-sky-900', active: 'bg-sky-500 text-white', complete: 'bg-sky-600 text-white', fillInactive: 'fill-sky-200', fillActive: 'fill-sky-500', fillComplete: 'fill-sky-600' },
    application_successful_or_not_successful: { inactive: 'bg-violet-200 text-violet-900', active: 'bg-violet-500 text-white', complete: 'bg-violet-600 text-white', fillInactive: 'fill-violet-200', fillActive: 'fill-violet-500', fillComplete: 'fill-violet-600' },
    resub_due: { inactive: 'bg-fuchsia-200 text-fuchsia-900', active: 'bg-fuchsia-500 text-white', complete: 'bg-fuchsia-600 text-white', fillInactive: 'fill-fuchsia-200', fillActive: 'fill-fuchsia-500', fillComplete: 'fill-fuchsia-600' },
    success_fee_invoiced: { inactive: 'bg-orange-200 text-orange-900', active: 'bg-orange-500 text-white', complete: 'bg-orange-600 text-white', fillInactive: 'fill-orange-200', fillActive: 'fill-orange-500', fillComplete: 'fill-orange-600' },
    success_fee_paid: { inactive: 'bg-lime-200 text-lime-900', active: 'bg-lime-500 text-white', complete: 'bg-lime-600 text-white', fillInactive: 'fill-lime-200', fillActive: 'fill-lime-500', fillComplete: 'fill-lime-600' }
  };
  
  
  
  function handleStageChange(targetStage) {
    if (targetStage === currentStage) return;
    stageLoading = true;
    router.patch(`/grant_applications/${grant_application.id}/change_stage`, { stage: targetStage }, {
      onSuccess: () => {
        currentStage = targetStage;
        toast.success('Stage updated successfully!');
        stageLoading = false;
      },
      onError: () => {
        toast.error('Failed to update stage.');
        stageLoading = false;
      }
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
            <h1 class="text-3xl font-bold text-gray-900 mb-2">{grant_application.title}</h1>
            <p class="text-gray-600 mb-4">{grant_application.description}</p>
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
            {@const palette = stageStyles[s] || { inactive: 'bg-gray-200 text-gray-700', active: 'bg-gray-500 text-white', complete: 'bg-gray-600 text-white', fillInactive: 'fill-gray-200', fillActive: 'fill-gray-500', fillComplete: 'fill-gray-600' }}
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
      <div class="bg-white rounded-lg shadow-sm border p-6 mt-6">
        <h2 class="text-xl font-semibold text-gray-900 mb-4">Application Details</h2>
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