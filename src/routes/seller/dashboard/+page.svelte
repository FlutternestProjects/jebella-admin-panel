<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';
    import ConfirmationDialog from '$lib/components/ConfirmationDialog.svelte';
    import { page } from '$app/stores';
    import { selectedShop } from '$lib/stores/selectedShop';
    import { get } from 'svelte/store';

    let user: any = null;
    let shop: any = null;
    let loading = true;
    let showLogoutDialog = false;
    let shops: any[] = [];
    let metrics = {
        totalProducts: 0,
        totalOrders: 0,
        totalSales: 0
    };

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

            // Get all shops for this seller
            const { data: shopList, error: shopListError } = await supabase
                .from('seller_shops')
                .select('*')
                .eq('user_id', userData.id)
                .eq('is_deleted', false);

            if (!shopListError && shopList) {
                shops = shopList;
                // If no shop selected, select the first one
                if (shops.length > 0 && !get(selectedShop)) {
                    selectedShop.set(shops[0].id);
                }
            }

            // Get current shop info (optional, for dashboard display)
            const selectedShopId = get(selectedShop);
            if (selectedShopId) {
                const { data: shopData, error: shopError } = await supabase
                    .from('seller_shops')
                    .select('*')
                    .eq('id', selectedShopId)
                    .single();
                if (!shopError) {
                    shop = shopData;
                }
            }

            // Get shop metrics
            const { data: metricsData, error: metricsError } = await supabase
                .from('seller_metrics')
                .select('*')
                .eq('shop_id', selectedShopId)
                .single();

            if (!metricsError && metricsData) {
                metrics = {
                    totalProducts: metricsData.products_count || 0,
                    totalOrders: metricsData.total_orders || 0,
                    totalSales: metricsData.total_sales || 0
                };
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

    function handleShopChange(event: Event) {
        const id = (event.target as HTMLSelectElement).value;
        selectedShop.set(id);
        // Optionally reload the page or trigger data reloads
        location.reload();
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
{:else if !$selectedShop}
    <div class="setup-shop">
        <h3>Select or Create a Shop</h3>
        <p>You need to select or create a shop to view your dashboard</p>
        <a href="/seller/shops" class="setup-button">Manage Shops</a>
    </div>
{:else}
    <div class="dashboard">
        <main class="content">
            <header class="content-header">
                <h2>Dashboard Overview</h2>
            </header>

            <div class="dashboard-grid">
                <div class="stat-card">
                    <h3>Total Products</h3>
                    <p class="stat-number">{metrics.totalProducts}</p>
                </div>
                <div class="stat-card">
                    <h3>Total Orders</h3>
                    <p class="stat-number">{metrics.totalOrders}</p>
                </div>
                <div class="stat-card">
                    <h3>Total Sales</h3>
                    <p class="stat-number">${metrics.totalSales.toFixed(2)}</p>
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

    .shop-switcher {
        width: 100%;
        margin-top: 0.25rem;
        padding: 0.5rem;
        border-radius: 6px;
        border: 1px solid #2d3748;
        background: #2d3748;
        color: #fff;
    }
</style> 