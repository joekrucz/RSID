<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Select from '../../components/forms/Select.svelte';
  
  let { user, person, can_edit, can_change_role } = $props();
  
  let editing = $state(false);
  let newRole = $state(person.role);
  let loading = $state(false);
  
  let editForm = $state({
    name: person.name,
    email: person.email
  });
  
  function goBack() {
    router.visit('/people');
  }
  
  function startEdit() {
    editing = true;
    editForm = {
      name: person.name,
      email: person.email
    };
  }
  
  function cancelEdit() {
    editing = false;
    editForm = {
      name: person.name,
      email: person.email
    };
  }
  
  function saveEdit() {
    if (!editForm.name.trim() || !editForm.email.trim()) {
      toast.error('Please fill in all required fields');
      return;
    }
    
    loading = true;
    router.put(`/people/${person.id}`, {
      person: editForm
    }, {
      onSuccess: () => {
        toast.success('Person updated successfully!');
        editing = false;
        loading = false;
      },
      onError: (errors) => {
        toast.error('Failed to update person');
        loading = false;
      }
    });
  }
  
  function changeRole() {
    if (confirm(`Are you sure you want to change ${person.name}'s role to ${newRole}?`)) {
      loading = true;
      router.patch(`/people/${person.id}/update_role`, { role: newRole }, {
        onSuccess: () => {
          toast.success('Role updated successfully!');
          loading = false;
        },
        onError: () => {
          toast.error('Failed to update role');
          loading = false;
        }
      });
    }
  }
  
  function deletePerson() {
    if (confirm(`Are you sure you want to delete ${person.name}? This action cannot be undone.`)) {
      router.delete(`/people/${person.id}`, {
        onSuccess: () => {
          toast.success('Person deleted successfully!');
        },
        onError: () => {
          toast.error('Failed to delete person');
        }
      });
    }
  }
  
  function getRoleBadgeClass(role) {
    switch (role) {
      case 'admin':
        return 'badge-error';
      case 'employee':
        return 'badge-warning';
      case 'client':
        return 'badge-info';
      default:
        return 'badge-neutral';
    }
  }
  
  function getRoleDisplayName(role) {
    return role.charAt(0).toUpperCase() + role.slice(1);
  }
</script>

<svelte:head>
  <title>{person.name} - People Management - RSID App</title>
</svelte:head>

<Layout {user}>
    <div class="max-w-4xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <Button variant="secondary" onclick={goBack} class="mb-4">
          ← Back to People
        </Button>
        
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-3xl font-bold text-base-content mb-2">{person.name}</h1>
            <p class="text-base-content/70">Person details and management</p>
          </div>
          
          <div class="flex space-x-2">
            {#if can_edit && !editing}
              <Button variant="secondary" onclick={startEdit}>
                Edit
              </Button>
            {/if}
            {#if can_change_role}
              <Button variant="outline" onclick={deletePerson} class="text-error">
                Delete
              </Button>
            {/if}
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Person Profile -->
        <div class="lg:col-span-2">
          <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
            <div class="flex items-center space-x-4 mb-6">
              <div class="bg-neutral text-neutral-content rounded-full w-20">
                <span class="text-2xl font-bold">{person.name.charAt(0).toUpperCase()}</span>
              </div>
              <div>
                <h2 class="text-2xl font-bold text-base-content">{person.name}</h2>
                <p class="text-base-content/70">{person.email}</p>
              </div>
            </div>

            <!-- Person Stats -->
            <div class="grid grid-cols-2 gap-4 mb-6">
              <div class="stat bg-base-200 rounded-lg p-4">
                <div class="stat-title">Member Since</div>
                <div class="stat-value text-lg">{person.created_at}</div>
              </div>
              <div class="stat bg-base-200 rounded-lg p-4">
                <div class="stat-title">Last Updated</div>
                <div class="stat-value text-lg">{person.updated_at}</div>
              </div>
            </div>

            <!-- Edit Form -->
            {#if editing}
              <div class="bg-base-200 rounded-lg p-6 mb-6">
                <h3 class="text-lg font-semibold text-base-content mb-4">Edit Person</h3>
                <div class="space-y-4">
                  <div class="form-control">
                    <label class="label">
                      <span class="label-text">Name *</span>
                    </label>
                    <input
                      type="text"
                      class="input input-bordered w-full"
                      bind:value={editForm.name}
                      required
                    />
                  </div>
                  
                  <div class="form-control">
                    <label class="label">
                      <span class="label-text">Email *</span>
                    </label>
                    <input
                      type="email"
                      class="input input-bordered w-full"
                      bind:value={editForm.email}
                      required
                    />
                  </div>
                  
                  <div class="flex space-x-2">
                    <Button variant="primary" onclick={saveEdit} disabled={loading}>
                      {loading ? 'Saving...' : 'Save Changes'}
                    </Button>
                    <Button variant="secondary" onclick={cancelEdit}>
                      Cancel
                    </Button>
                  </div>
                </div>
              </div>
            {/if}
          </div>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Role Management -->
          <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
            <h3 class="text-lg font-semibold text-base-content mb-4">Role Management</h3>
            
            <div class="space-y-3">
              <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
                <div class="flex items-center">
                  <span class="badge {getRoleBadgeClass(person.role)}">
                    {getRoleDisplayName(person.role)}
                  </span>
                  <span class="ml-3 text-base-content">Current Role</span>
                </div>
              </div>
              
              {#if can_change_role}
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Change Role</span>
                  </label>
                  <Select
                    bind:value={newRole}
                    options={[
                      { value: 'client', label: 'Client' },
                      { value: 'employee', label: 'Employee' },
                      { value: 'admin', label: 'Admin' }
                    ]}
                  />
                  <Button 
                    variant="primary" 
                    size="sm"
                    onclick={changeRole}
                    disabled={loading || newRole === person.role}
                    class="mt-2 w-full"
                  >
                    {loading ? 'Updating...' : 'Update Role'}
                  </Button>
                </div>
              {/if}
            </div>
          </div>

          <!-- Role Permissions -->
          <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
            <h3 class="text-lg font-semibold text-base-content mb-4">Role Permissions</h3>
            
            <div class="space-y-3">
              <div class="flex items-center">
                <svg class="w-5 h-5 text-success mr-2" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
                </svg>
                <span class="text-base-content">View own profile</span>
              </div>
              
              <div class="flex items-center">
                <svg class="w-5 h-5 text-success mr-2" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
                </svg>
                <span class="text-base-content">Edit own profile</span>
              </div>
              
              {#if person.role === 'employee' || person.role === 'admin'}
                <div class="flex items-center">
                  <svg class="w-5 h-5 text-success mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
                  </svg>
                  <span class="text-base-content">Access client management</span>
                </div>
                
                <div class="flex items-center">
                  <svg class="w-5 h-5 text-success mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
                  </svg>
                  <span class="text-base-content">View grant applications</span>
                </div>
              {/if}
              
              {#if person.role === 'admin'}
                <div class="flex items-center">
                  <svg class="w-5 h-5 text-success mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
                  </svg>
                  <span class="text-base-content">Manage all users</span>
                </div>
                
                <div class="flex items-center">
                  <svg class="w-5 h-5 text-success mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
                  </svg>
                  <span class="text-base-content">System administration</span>
                </div>
              {/if}
            </div>
          </div>

          <!-- Quick Actions -->
          <div class="bg-base-100 rounded-lg shadow border border-base-300 p-6">
            <h3 class="text-lg font-semibold text-base-content mb-4">Quick Actions</h3>
            
            <div class="space-y-3">
              <Button variant="outline" class="w-full" onclick={() => router.visit(`/people/${person.id}/edit`)}>
                Edit Person
              </Button>
              
              <Button variant="outline" class="w-full" onclick={() => router.visit(`/messages?user=${person.id}`)}>
                View Messages
              </Button>
              
              <Button variant="outline" class="w-full" onclick={() => router.visit(`/grant_applications?user=${person.id}`)}>
                View Applications
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
</Layout> 