<script>
    let {name} = $props();
    console.log(name);
    let inputText = $state("");
</script>

<div>
    <h1 class="text-4xl">Hello {name}</h1>
</div>

<div>
    <button class="btn">Click me</button>
    <button class="btn btn-primary">Click me</button>
</div>

<div>
    <input type="text" class="input input-bordered" bind:value={inputText} /> 
</div>
<div>
    {inputText}
</div>
<div>
    <input type="checkbox" class="checkbox" />
</div>

<div>
    <input type="radio" class="radio" />
</div>

<div>
    <input type="range" class="range" />
</div>

<div>
    <input type="date" class="date" />
</div>

<div>
    <input type="time" class="time" />
</div>

<div>
    <input type="email" class="email" />
</div>


