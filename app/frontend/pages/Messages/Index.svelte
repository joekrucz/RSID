<script>
  import { router } from '@inertiajs/svelte';
  import { toast } from '../../stores/toast.js';
  import Layout from '../../components/Layout.svelte';
  import Input from '../../components/forms/Input.svelte';
  import Button from '../../components/forms/Button.svelte';
  import Select from '../../components/forms/Select.svelte';
  
  let { user, messages, can_send_messages } = $props();
  
  let newMessage = $state({
    subject: '',
    content: '',
    client_id: '',
    recipient_id: '',
    message_type: 'internal'
  });
  
  let showNewMessageForm = $state(false);
  let search = $state('');
  let sortBy = $state('created_at');
  let sortOrder = $state('desc');
  
  function handleSubmit() {
    if (!newMessage.subject || !newMessage.content) {
      toast.error('Please fill in all required fields');
      return;
    }
    
    router.post('/messages', newMessage, {
      onSuccess: () => {
        toast.success('Message sent successfully!');
        newMessage = {
          subject: '',
          content: '',
          client_id: '',
          recipient_id: '',
          message_type: 'internal'
        };
        showNewMessageForm = false;
      },
      onError: (errors) => {
        toast.error('Failed to send message');
      }
    });
  }
  
  function filteredMessages() {
    let filtered = messages;
    
    if (search) {
      filtered = filtered.filter(message => 
        message.subject.toLowerCase().includes(search.toLowerCase()) ||
        message.content.toLowerCase().includes(search.toLowerCase()) ||
        message.sender_name.toLowerCase().includes(search.toLowerCase()) ||
        message.recipient_name.toLowerCase().includes(search.toLowerCase())
      );
    }
    
    return filtered.sort((a, b) => {
      let aValue = a[sortBy];
      let bValue = b[sortBy];
      
      if (sortBy === 'created_at') {
        aValue = new Date(aValue);
        bValue = new Date(bValue);
      }
      
      if (sortOrder === 'asc') {
        return aValue > bValue ? 1 : -1;
      } else {
        return aValue < bValue ? 1 : -1;
      }
    });
  }
</script>

<Layout {user}>
    <div class="flex justify-between items-center mb-8">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">Messages</h1>
        <p class="text-gray-600 mt-2">Manage your communications</p>
      </div>
      
      {#if can_send_messages}
        <Button 
          variant="primary" 
          on:click={() => showNewMessageForm = !showNewMessageForm}
        >
          {showNewMessageForm ? 'Cancel' : 'New Message'}
        </Button>
      {/if}
    </div>
    
    <!-- Search and Filter -->
    <div class="bg-white rounded-lg shadow-sm border p-6 mb-6">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="md:col-span-2">
          <Input
            type="text"
            placeholder="Search messages..."
            bind:value={search}
          />
        </div>
        <Select bind:value={sortBy}>
          <option value="created_at">Date</option>
          <option value="subject">Subject</option>
          <option value="sender_name">Sender</option>
          <option value="recipient_name">Recipient</option>
        </Select>
        <Select bind:value={sortOrder}>
          <option value="desc">Newest First</option>
          <option value="asc">Oldest First</option>
        </Select>
      </div>
    </div>
    
    <!-- New Message Form -->
    {#if showNewMessageForm && can_send_messages}
      <div class="bg-white rounded-lg shadow-sm border p-6 mb-6">
        <h3 class="text-lg font-semibold mb-4">Send New Message</h3>
        <form on:submit|preventDefault={handleSubmit} class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input
              type="text"
              placeholder="Subject"
              bind:value={newMessage.subject}
              required
            />
            <Select bind:value={newMessage.message_type}>
              <option value="internal">Internal Note</option>
              <option value="client_communication">Client Communication</option>
            </Select>
          </div>
          <textarea
            placeholder="Message content..."
            bind:value={newMessage.content}
            class="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            rows="4"
            required
          ></textarea>
          <div class="flex justify-end space-x-3">
            <Button type="button" variant="secondary" on:click={() => showNewMessageForm = false}>
              Cancel
            </Button>
            <Button type="submit" variant="primary">
              Send Message
            </Button>
          </div>
        </form>
      </div>
    {/if}
    
    <!-- Messages List -->
    <div class="bg-white rounded-lg shadow-sm border">
      {#if filteredMessages().length === 0}
        <div class="p-8 text-center">
          <div class="text-gray-400 text-6xl mb-4">💬</div>
          <h3 class="text-lg font-medium text-gray-900 mb-2">No messages found</h3>
          <p class="text-gray-600">
            {search ? 'Try adjusting your search terms' : 'Start by sending your first message'}
          </p>
        </div>
      {:else}
        <div class="divide-y divide-gray-200">
          {#each filteredMessages() as message}
            <div class="p-6 hover:bg-gray-50 transition-colors">
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <div class="flex items-center space-x-3 mb-2">
                    <h3 class="text-lg font-medium text-gray-900">
                      {message.subject}
                    </h3>
                    <span class="px-2 py-1 text-xs rounded-full {message.is_internal ? 'bg-purple-100 text-purple-800' : 'bg-blue-100 text-blue-800'}">
                      {message.is_internal ? 'Internal' : 'Client'}
                    </span>
                  </div>
                  <p class="text-gray-600 mb-3 line-clamp-2">{message.content}</p>
                  <div class="flex items-center space-x-4 text-sm text-gray-500">
                    <span>From: {message.sender_name}</span>
                    <span>To: {message.recipient_name}</span>
                    <span>Client: {message.client_name}</span>
                    <span>{message.created_at}</span>
                  </div>
                </div>
                <div class="flex space-x-2">
                  <Button 
                    variant="secondary" 
                    size="sm"
                    on:click={() => router.visit(`/messages/${message.id}`, {
                      onSuccess: () => {
                        // Refresh the page after navigation
                        window.location.reload();
                      }
                    })}
                  >
                    View
                  </Button>
                </div>
              </div>
            </div>
          {/each}
        </div>
      {/if}
    </div>
</Layout>

<style>
  .line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
</style> 