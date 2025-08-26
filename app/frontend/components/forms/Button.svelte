<script>
  let { 
    type = 'button',
    variant = 'primary',
    size = 'md',
    loading = false,
    disabled = false,
    class: className = '',
    children,
    onclick,
    ...restProps
  } = $props();
  
  function getVariantClass() {
    switch (variant) {
      case 'secondary': return 'btn-secondary';
      case 'accent': return 'btn-accent';
      case 'ghost': return 'btn-ghost';
      case 'link': return 'btn-link';
      case 'info': return 'btn-info';
      case 'success': return 'btn-success';
      case 'warning': return 'btn-warning';
      case 'error': return 'btn-error';
      default: return 'btn-primary';
    }
  }
  
  function getSizeClass() {
    switch (size) {
      case 'xs': return 'btn-xs';
      case 'sm': return 'btn-sm';
      case 'lg': return 'btn-lg';
      default: return '';
    }
  }
</script>

<button 
  {type}
  {disabled}
  {onclick}
  class="btn {getVariantClass()} {getSizeClass()} {loading ? 'loading' : ''} {className}"
  {...restProps}
>
  {#if loading}
    <span class="loading loading-spinner loading-sm"></span>
  {/if}
  {@render children()}
</button> 