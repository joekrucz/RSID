<script>
  import { onMount, onDestroy } from 'svelte';
  import { router } from '@inertiajs/svelte';
  import { toast } from '../stores/toast.js';
  
  let { user, unreadCount = 0 } = $props();
  
  let notifications = $state([]);
  let showDropdown = $state(false);
  let consumer = null;
  
  onMount(() => {
    // Connect to ActionCable
    if (window.App && window.App.cable) {
      consumer = window.App.cable.subscriptions.create("NotificationsChannel", {
        received(data) {
          // Add new notification to the list
          notifications = [data, ...notifications.slice(0, 9)];
          unreadCount++;
          
          // Show toast notification
          toast.info(data.title, data.message);
        }
      });
    }
  });
  
  onDestroy(() => {
    if (consumer) {
      consumer.unsubscribe();
    }
  });
  
  function toggleDropdown() {
    showDropdown = !showDropdown;
  }
  
  function markAsRead(notificationId) {
    fetch(`/notifications/${notificationId}/mark_as_read`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      }
    }).then(() => {
      // Update local state
      notifications = notifications.map(n => 
        n.id === notificationId ? { ...n, read: true } : n
      );
      if (unreadCount > 0) unreadCount--;
    });
  }
  
  function markAllAsRead() {
    fetch('/notifications/mark_all_as_read', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      }
    }).then(() => {
      notifications = notifications.map(n => ({ ...n, read: true }));
      unreadCount = 0;
    });
  }
  
  function goToNotifications() {
    router.visit('/notifications');
    showDropdown = false;
  }
</script>

<div class="relative">
  <!-- Notification Bell -->
  <button 
    on:click={toggleDropdown}
    class="btn btn-ghost btn-circle relative"
    aria-label="Notifications"
  >
    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5v-5zM10.5 3.75a6 6 0 0 1 6 6v3.75l1.5 1.5H3l1.5-1.5V9.75a6 6 0 0 1 6-6z"></path>
    </svg>
    
    <!-- Unread Badge -->
    {#if unreadCount > 0}
      <span class="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
        {unreadCount > 99 ? '99+' : unreadCount}
      </span>
    {/if}
  </button>
  
  <!-- Dropdown -->
  {#if showDropdown}
    <div class="absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-lg border z-50">
      <div class="p-4 border-b">
        <div class="flex justify-between items-center">
          <h3 class="text-lg font-semibold">Notifications</h3>
          {#if unreadCount > 0}
            <button 
              on:click={markAllAsRead}
              class="text-sm text-blue-600 hover:text-blue-800"
            >
              Mark all read
            </button>
          {/if}
        </div>
      </div>
      
      <div class="max-h-64 overflow-y-auto">
        {#if notifications.length === 0}
          <div class="p-4 text-center text-gray-500">
            No notifications
          </div>
        {:else}
          {#each notifications as notification}
            <div class="p-3 border-b hover:bg-gray-50 {notification.read ? '' : 'bg-blue-50'}">
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <div class="font-medium text-sm">{notification.title}</div>
                  <div class="text-xs text-gray-600 mt-1">{notification.message}</div>
                  <div class="text-xs text-gray-400 mt-1">{notification.created_at}</div>
                </div>
                {#if !notification.read}
                  <button 
                    on:click={() => markAsRead(notification.id)}
                    class="text-xs text-blue-600 hover:text-blue-800 ml-2"
                  >
                    Mark read
                  </button>
                {/if}
              </div>
            </div>
          {/each}
        {/if}
      </div>
      
      <div class="p-3 border-t">
        <button 
          on:click={goToNotifications}
          class="w-full text-center text-blue-600 hover:text-blue-800 text-sm"
        >
          View all notifications
        </button>
      </div>
    </div>
  {/if}
</div>

<!-- Click outside to close -->
{#if showDropdown}
  <div 
    class="fixed inset-0 z-40" 
    on:click={() => showDropdown = false}
  ></div>
{/if}
