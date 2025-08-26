<script>
  let { 
    value = $bindable(''),
    options = [],
    label = '',
    error = '',
    required = false,
    disabled = false,
    placeholder = 'Select an option',
    class: className = '',
    id = '',
    onchange,
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
  
  <select 
    {id}
    {required}
    {disabled}
    bind:value
    class="select select-bordered w-full {error ? 'select-error' : ''} {className}"
    onchange={onchange}
    {...restProps}
  >
    {#if placeholder}
      <option disabled selected={!value}>{placeholder}</option>
    {/if}
    
    {#each options as option}
      {#if typeof option === 'string'}
        <option value={option}>{option.charAt(0).toUpperCase() + option.slice(1)}</option>
      {:else}
        <option value={option.value}>{option.label}</option>
      {/if}
    {/each}
  </select>
  
  {#if error}
    <label class="label">
      <span class="label-text-alt text-error">{error}</span>
    </label>
  {/if}
</div> 