<script>
  import { router } from '@inertiajs/svelte';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  let { user, companies } = $props();
  function go(path){ router.visit(path); }
</script>

<Layout {user}>
  <div class="max-w-6xl mx-auto">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-3xl font-bold">Companies</h1>
        <p class="text-base-content/70">Directory of companies</p>
      </div>
      <Button variant="primary" onclick={() => go('/companies/new')}>Add Company</Button>
    </div>
    <div class="bg-base-100 rounded-lg shadow border p-4">
      {#if companies.length}
        <div class="overflow-x-auto">
          <table class="table w-full">
            <thead>
              <tr>
                <th>Name</th>
                <th>Website</th>
                <th>Notes</th>
                <th>Added</th>
              </tr>
            </thead>
            <tbody>
              {#each companies as c}
                <tr>
                  <td class="font-medium">
                    <a class="link link-primary" href={`/companies/${c.id}`}>{c.name}</a>
                  </td>
                  <td>
                    {#if c.website}
                      <a href={c.website} class="link link-primary" target="_blank" rel="noopener noreferrer">{c.website}</a>
                    {:else}
                      —
                    {/if}
                  </td>
                  <td class="max-w-xl truncate">{c.notes}</td>
                  <td>{c.created_at}</td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      {:else}
        <div class="text-center py-12">
          <p class="mb-4">No companies yet.</p>
          <Button variant="primary" onclick={() => go('/companies/new')}>Add your first company</Button>
        </div>
      {/if}
    </div>
  </div>
</Layout>

