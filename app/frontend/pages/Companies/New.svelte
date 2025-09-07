<script>
  import { router } from '@inertiajs/svelte';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  let { user, errors = {}, company = {} } = $props();
  let name = $state(company.name || '');
  let website = $state(company.website || '');
  let notes = $state(company.notes || '');
  function submit() {
    router.post('/companies', { company: { name, website, notes } });
  }
</script>

<Layout {user}>
  <div class="max-w-3xl mx-auto">
    <h1 class="text-3xl font-bold mb-6">Add Company</h1>
    <div class="bg-base-100 rounded-lg shadow border p-6 space-y-4">
      <div class="form-control">
        <label class="label"><span class="label-text">Name</span></label>
        <input class="input input-bordered w-full" bind:value={name} />
        {#if errors.name}<div class="text-error text-sm mt-1">{errors.name}</div>{/if}
      </div>
      <div class="form-control">
        <label class="label"><span class="label-text">Website</span></label>
        <input class="input input-bordered w-full" bind:value={website} placeholder="https://…" />
      </div>
      <div class="form-control">
        <label class="label"><span class="label-text">Notes</span></label>
        <textarea class="textarea textarea-bordered w-full" rows="5" bind:value={notes}></textarea>
      </div>
      <div class="flex gap-2">
        <Button variant="primary" onclick={submit}>Create</Button>
        <Button variant="secondary" onclick={() => router.visit('/companies')}>Cancel</Button>
      </div>
    </div>
  </div>
</Layout>

