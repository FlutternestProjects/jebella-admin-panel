<script lang="ts">
    import { page } from '$app/stores';
</script>

{#if $page.url.pathname === '/seller/login'}
    <slot />
{:else}
    <div class="seller-layout">
        <main class="main-content">
            <slot />
        </main>
    </div>
{/if}

<style>
    .seller-layout {
        display: flex;
        min-height: 100vh;
        margin: 0;
        padding: 0;
    }

    .main-content {
        flex: 1;
        padding: 0;
        margin: 0;
        background: #f7fafc;
    }

    :global(body) {
        margin: 0;
        padding: 0;
    }
</style> 