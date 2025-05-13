<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';
    import ConfirmationDialog from '$lib/components/ConfirmationDialog.svelte';

    let user: any = null;
    let shop: any = null;
    let loading = true;
    let showLogoutDialog = false;

    onMount(async () => {
        try {
            const { data: { session }, error } = await supabase.auth.getSession();
            if (error) throw error;
            
            if (!session) {
                goto('/seller/login');
                return;
            }

            // Get user data using id
            const { data: userData, error: userError } = await supabase
                .from('users')
                .select('*')
                .eq('id', session.user.id)
                .single();

            if (userError || userData.user_type !== 'seller') {
                await supabase.auth.signOut();
                goto('/seller/login');
                return;
            }

            user = userData;

            // Get seller's shop information
            const { data: shopData, error: shopError } = await supabase
                .from('seller_shops')
                .select('*')
                .eq('user_id', userData.id)
                .single();

            if (!shopError) {
                shop = shopData;
            }

        } catch (e) {
            console.error('Error:', e);
            goto('/seller/login');
        } finally {
            loading = false;
        }
    });

    function handleLogoutClick() {
        showLogoutDialog = true;
    }

    async function handleLogout() {
        await supabase.auth.signOut();
        goto('/seller/login');
    }
</script>

<ConfirmationDialog
    bind:isOpen={showLogoutDialog}
    title="Confirm Logout"
    message="Are you sure you want to logout from your seller account?"
    confirmText="Logout"
    on:confirm={handleLogout}
/>

{#if loading}
    <div class="loading">Loading...</div>
{:else}
    <div class="dashboard">
        <nav class="sidebar">
            <div class="logo">
                <h1>Seller Dashboard</h1>
            </div>
            <ul class="nav-links">
                <li class="active">
                    <a href="/seller/dashboard">Dashboard</a>
                </li>
                <li>
                    <a href="/seller/products">My Products</a>
                </li>
                <li>
                    <a href="/seller/orders">Orders</a>
                </li>
                <li>
                    <a href="/seller/shop">Shop Settings</a>
                </li>
            </ul>
            <div class="user-section">
                <div class="user-info">
                    <span class="user-name">{user?.email}</span>
                    <span class="user-role">Seller</span>
                    {#if shop}
                        <span class="shop-name">{shop.shop_name}</span>
                    {/if}
                </div>
                <button class="logout-button" on:click={handleLogoutClick}>
                    Logout
                </button>
            </div>
        </nav>

        <main class="content">
            <header class="content-header">
                <h2>Dashboard Overview</h2>
            </header>

            <div class="dashboard-grid">
                <div class="stat-card">
                    <h3>Total Products</h3>
                    <p class="stat-number">0</p>
                </div>
                <div class="stat-card">
                    <h3>Total Orders</h3>
                    <p class="stat-number">0</p>
                </div>
                <div class="stat-card">
                    <h3>Total Sales</h3>
                    <p class="stat-number">$0</p>
                </div>
                <div class="stat-card">
                    <h3>Shop Rating</h3>
                    <p class="stat-number">{shop?.rating || '0.0'}</p>
                </div>
            </div>

            {#if !shop}
                <div class="setup-shop">
                    <h3>Complete Your Shop Setup</h3>
                    <p>Set up your shop to start selling on Jebella</p>
                    <a href="/seller/shop" class="setup-button">Set Up Shop</a>
                </div>
            {/if}
        </main>
    </div>
{/if}

<style>
    .dashboard {
        display: flex;
        min-height: 100vh;
    }

    .sidebar {
        width: 280px;
        background: #1a202c;
        color: white;
        padding: 1.5rem;
        display: flex;
        flex-direction: column;
    }

    .logo h1 {
        font-size: 1.5rem;
        margin-bottom: 2rem;
        color: #4299e1;
    }

    .nav-links {
        list-style: none;
        padding: 0;
        margin: 0;
    }

    .nav-links li {
        margin-bottom: 0.5rem;
    }

    .nav-links a {
        color: #a0aec0;
        text-decoration: none;
        padding: 0.75rem 1rem;
        display: block;
        border-radius: 6px;
        transition: all 0.2s;
    }

    .nav-links li.active a,
    .nav-links a:hover {
        background: #2d3748;
        color: white;
    }

    .user-section {
        margin-top: auto;
        padding-top: 1rem;
        border-top: 1px solid #2d3748;
    }

    .user-info {
        margin-bottom: 1rem;
    }

    .user-name {
        display: block;
        font-weight: 500;
    }

    .user-role {
        display: block;
        font-size: 0.875rem;
        color: #a0aec0;
    }

    .shop-name {
        display: block;
        font-size: 0.875rem;
        color: #4299e1;
        margin-top: 0.25rem;
    }

    .logout-button {
        width: 100%;
        padding: 0.75rem;
        background: #e53e3e;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        transition: background 0.2s;
    }

    .logout-button:hover {
        background: #c53030;
    }

    .content {
        flex: 1;
        padding: 2rem;
        background: #f7fafc;
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
        margin-bottom: 2rem;
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

    .setup-shop {
        background: white;
        padding: 2rem;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        text-align: center;
    }

    .setup-shop h3 {
        color: #2d3748;
        font-size: 1.25rem;
        margin-bottom: 0.5rem;
    }

    .setup-shop p {
        color: #718096;
        margin-bottom: 1.5rem;
    }

    .setup-button {
        display: inline-block;
        padding: 0.75rem 1.5rem;
        background: #4299e1;
        color: white;
        text-decoration: none;
        border-radius: 6px;
        transition: background 0.2s;
    }

    .setup-button:hover {
        background: #3182ce;
    }

    .loading {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        font-size: 1.2rem;
        color: #4a5568;
    }
</style> 