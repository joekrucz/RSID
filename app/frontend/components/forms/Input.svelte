<script>
  let { 
    type = 'text',
    placeholder = '',
    value = $bindable(''),
    label = '',
    error = '',
    required = false,
    disabled = false,
    class: className = '',
    id = '',
    ...restProps
  } = $props();
</script>

<div class="form-control w-full">
  {#if label}
    <label class="label" for={id}>
      <span class="label-text">{label}</span>
      {#if required}
        <span class="label-text-alt text-error">*</span>
      {/if}
    </label>
  {/if}
  
  <input 
    {id}
    {type}
    {placeholder}
    {required}
    {disabled}
    bind:value
    class="input input-bordered w-full {error ? 'input-error' : ''} {className}"
    {...restProps}
  />
  
  {#if error}
    <label class="label">
      <span class="label-text-alt text-error">{error}</span>
    </label>
  {/if}
</div> 