<script>
  import { createEventDispatcher } from 'svelte';
  import { isFeatureEnabled } from '../stores/features.js';
  
  let { feature, fallback = null } = $props();
  const dispatch = createEventDispatcher();
  
  let enabled = $derived(isFeatureEnabled(feature));
</script>

{#if enabled}
  <slot />
{:else if fallback}
  {fallback}
{/if}
