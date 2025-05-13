<script lang="ts">
    import { page } from '$app/stores';
    import Sidebar from '$lib/components/Sidebar.svelte';
</script>

{#if $page.url.pathname === '/admin/login'}
    <slot />
{:else}
    <div class="admin-layout">
        <Sidebar />
        <main class="main-content">
            <slot />
        </main>
    </div>
{/if}

<style>
    .admin-layout {
        display: flex;
        min-height: 100vh;
    }

    .main-content {
        flex: 1;
        padding: 2rem;
        background: #f7fafc;
    }
</style> 