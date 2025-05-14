<script lang="ts">
    import { toast } from '$lib/toast';
</script>

<div class="fixed top-4 right-4 z-50 flex flex-col gap-2">
    {#each $toast as notification}
        <div
            class="px-4 py-2 rounded shadow-lg text-white transform transition-all duration-300 ease-in-out"
            class:bg-green-500={notification.type === 'success'}
            class:bg-red-500={notification.type === 'error'}
            class:bg-blue-500={notification.type === 'info'}
            class:bg-yellow-500={notification.type === 'warning'}
        >
            {notification.message}
        </div>
    {/each}
</div> 