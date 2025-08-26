<script>
  import { router } from '@inertiajs/svelte';
  import Layout from '../../components/Layout.svelte';
  import Button from '../../components/forms/Button.svelte';
  
  let { user, message } = $props();
  
  function goBack() {
    router.visit('/messages');
  }
</script>

<Layout {user}>
    <div class="mb-6">
      <Button variant="secondary" on:click={goBack} class="mb-4">
        ← Back to Messages
      </Button>
      
      <div class="bg-white rounded-lg shadow-sm border p-6">
        <div class="flex justify-between items-start mb-6">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 mb-2">
              {message.subject}
            </h1>
            <div class="flex items-center space-x-4 text-sm text-gray-600">
              <span>From: {message.sender_name}</span>
              <span>To: {message.recipient_name}</span>
              <span>Client: {message.client_name}</span>
            </div>
          </div>
          <span class="px-3 py-1 text-sm rounded-full {message.is_internal ? 'bg-purple-100 text-purple-800' : 'bg-blue-100 text-blue-800'}">
            {message.is_internal ? 'Internal Note' : 'Client Communication'}
          </span>
        </div>
        
        <div class="prose max-w-none">
          <div class="bg-gray-50 rounded-lg p-6 mb-6">
            <p class="text-gray-800 whitespace-pre-wrap">{message.content}</p>
          </div>
        </div>
        
        <div class="border-t pt-4">
          <div class="text-sm text-gray-500">
            Sent on {message.created_at}
          </div>
        </div>
      </div>
    </div>
</Layout> 