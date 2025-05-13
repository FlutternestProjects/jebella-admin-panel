<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';

    let totalSellers = 0;

    onMount(async () => {
        try {
            const { count, error } = await supabase
                .from('users')
                .select('*', { count: 'exact', head: true })
                .eq('user_type', 'seller')
                .eq('is_deleted', false);

            if (error) throw error;
            totalSellers = count || 0;
        } catch (e) {
            console.error('Error loading dashboard stats:', e);
        }
    });
</script>

<div class="dashboard-content">
    <header class="content-header">
        <h2>Dashboard Overview</h2>
    </header>

    <div class="dashboard-grid">
        <div class="stat-card">
            <h3>Total Sellers</h3>
            <p class="stat-number">{totalSellers}</p>
        </div>
    </div>
</div>

<style>
    .dashboard-content {
        padding: 2rem;
    }

    .content-header {
        margin-bottom: 2rem;
    }

    .content-header h2 {
        color: #2d3748;
        font-size: 1.5rem;
    }

    .dashboard-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
        gap: 1.5rem;
    }

    .stat-card {
        background: white;
        padding: 1.5rem;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    }

    .stat-card h3 {
        color: #4a5568;
        font-size: 1rem;
        margin-bottom: 0.5rem;
    }

    .stat-number {
        color: #2d3748;
        font-size: 1.5rem;
        font-weight: 600;
    }
</style> 