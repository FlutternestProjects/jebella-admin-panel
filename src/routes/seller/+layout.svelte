<script lang="ts">
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';
    import { selectedShop } from '$lib/stores/selectedShop';
    import { get } from 'svelte/store';
    import ConfirmationDialog from '$lib/components/ConfirmationDialog.svelte';

    let user: any = null;
    let shops: any[] = [];
    let loading = true;
    let shopsLoading = false;
    let showLogoutDialog = false;
    let authChecked = false;

    $: currentPath = $page.url.pathname;
    $: isLoginPage = currentPath === '/seller/login';
    $: isAuthenticated = user !== null && authChecked;

    onMount(() => {
        // Async function for initial auth check
        async function checkAuth() {
            try {
                const { data: { session }, error } = await supabase.auth.getSession();
                if (error) throw error;
                
                if (!session) {
                    authChecked = true;
                    loading = false;
                    if (!isLoginPage) {
                        goto('/seller/login');
                    }
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
                    authChecked = true;
                    loading = false;
                    goto('/seller/login');
                    return;
                }

                user = userData;
                authChecked = true;

                // Load shops after user is authenticated
                await loadShops(userData.id);

            } catch (e) {
                console.error('Error:', e);
                authChecked = true;
                if (!isLoginPage) {
                    goto('/seller/login');
                }
            } finally {
                loading = false;
            }
        }

        // Run initial auth check
        checkAuth();

        // Listen for auth state changes
        const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
            if (event === 'SIGNED_IN' && session) {
                // User just signed in, reload user data
                const { data: userData, error: userError } = await supabase
                    .from('users')
                    .select('*')
                    .eq('id', session.user.id)
                    .single();

                if (!userError && userData.user_type === 'seller') {
                    user = userData;
                    authChecked = true;
                    loading = false;
                    
                    // Load shops for the authenticated user
                    await loadShops(userData.id);
                    
                    // Redirect to dashboard if on login page
                    if (isLoginPage) {
                        goto('/seller/dashboard');
                    }
                }
            } else if (event === 'SIGNED_OUT') {
                user = null;
                shops = [];
                authChecked = true;
                loading = false;
                selectedShop.set(null);
                if (!isLoginPage) {
                    goto('/seller/login');
                }
            }
        });

        // Return cleanup function
        return () => {
            subscription.unsubscribe();
        };
    });

    async function loadShops(userId: string) {
        try {
            shopsLoading = true;
            
            // Get all shops for this seller
            const { data: shopList, error: shopListError } = await supabase
                .from('seller_shops')
                .select('*')
                .eq('user_id', userId)
                .eq('is_deleted', false);

            if (!shopListError && shopList) {
                shops = shopList;
                // If no shop selected, select the first one
                if (shops.length > 0 && !get(selectedShop)) {
                    selectedShop.set(shops[0].id);
                }
            } else {
                console.error('Error loading shops:', shopListError);
                shops = [];
            }
        } catch (e) {
            console.error('Error loading shops:', e);
            shops = [];
        } finally {
            shopsLoading = false;
        }
    }

    function handleLogoutClick() {
        showLogoutDialog = true;
    }

    async function handleLogout() {
        try {
            // Clear local state first
            user = null;
            shops = [];
            selectedShop.set(null);
            
            // Sign out from Supabase
            await supabase.auth.signOut();
            
            // Set auth state after signout
            authChecked = true;
            loading = false;
            
            // Redirect to login
            goto('/seller/login');
        } catch (error) {
            console.error('Logout error:', error);
            // Even if there's an error, still redirect to login
            goto('/seller/login');
        }
    }

    function handleShopChange(event: Event) {
        const id = (event.target as HTMLSelectElement).value;
        selectedShop.set(id);
        // Optionally reload the page or trigger data reloads
        location.reload();
    }

    // Helper function to check if a nav item is active
    function isNavActive(path: string): boolean {
        if (path === '/seller/dashboard') {
            return currentPath === '/seller/dashboard';
        }
        return currentPath.startsWith(path);
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
{:else if isLoginPage}
    <!-- Render login page without sidebar and tabs -->
    <slot />
{:else if isAuthenticated}
    <!-- Render authenticated layout with sidebar -->
    <div class="seller-layout">
        <nav class="sidebar">
            <div class="logo">
                <h1>Seller Dashboard</h1>
            </div>
            <ul class="nav-links">
                <li class:active={isNavActive('/seller/dashboard')}>
                    <a href="/seller/dashboard">Dashboard</a>
                </li>
                <li class:active={isNavActive('/seller/shops')}>
                    <a href="/seller/shops">My Shops</a>
                </li>
                <li class:active={isNavActive('/seller/products')}>
                    <a href="/seller/products">Products</a>
                </li>
                <li class:active={isNavActive('/seller/inventory')}>
                    <a href="/seller/inventory">Inventory</a>
                </li>
            </ul>
            <div class="user-section">
                <div class="user-info">
                    <a href="/seller/profile" class="user-name-link">
                        <span class="user-name">{user?.name || user?.email}</span>
                    </a>
                    <span class="user-role">Seller</span>
                    <label class="block mt-2 text-xs text-gray-400">Shop:</label>
                    {#if shopsLoading}
                        <span class="shop-loading text-blue-400">Loading shops...</span>
                    {:else if shops.length > 0}
                        <select class="shop-switcher" on:change={handleShopChange} bind:value={$selectedShop}>
                            {#each shops as s}
                                <option value={s.id}>{s.shop_name}</option>
                            {/each}
                        </select>
                    {:else}
                        <div class="no-shop-container">
                            <span class="shop-name text-red-400">No shop found</span>
                            <a href="/seller/shops" class="create-shop-link">Create Shop</a>
                        </div>
                    {/if}
                </div>
                <button class="logout-button" on:click={handleLogoutClick}>
                    Logout
                </button>
            </div>
        </nav>

        <main class="main-content">
            <slot />
        </main>
    </div>
{:else if authChecked}
    <!-- Only show this after auth has been checked -->
    <div class="loading">Redirecting to login...</div>
{:else}
    <!-- Still checking authentication -->
    <div class="loading">Loading...</div>
{/if}

<style>
    .seller-layout {
        display: flex;
        min-height: 100vh;
        max-height: 100vh;
        overflow: hidden;
    }

    .sidebar {
        width: 280px;
        background: #1a202c;
        color: white;
        padding: 1.5rem;
        display: flex;
        flex-direction: column;
        flex-shrink: 0;
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

    .user-name-link {
        text-decoration: none;
        color: inherit;
        display: block;
        padding: 0.5rem;
        border-radius: 6px;
        transition: background-color 0.2s;
        margin: -0.5rem;
        margin-bottom: 0.5rem;
    }

    .user-name-link:hover {
        background-color: #2d3748;
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

    .shop-switcher {
        width: 100%;
        margin-top: 0.25rem;
        padding: 0.5rem;
        border-radius: 6px;
        border: 1px solid #2d3748;
        background: #2d3748;
        color: #fff;
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

    .main-content {
        flex: 1;
        padding: 2rem;
        background: #f7fafc;
        overflow-y: auto;
        max-height: 100vh;
    }

    .loading {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        font-size: 1.2rem;
        color: #4a5568;
    }

    .shop-loading {
        display: block;
        font-size: 0.875rem;
        font-style: italic;
    }

    .no-shop-container {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }

    .create-shop-link {
        color: #4299e1;
        text-decoration: none;
        font-size: 0.75rem;
        padding: 0.25rem 0.5rem;
        border: 1px solid #4299e1;
        border-radius: 4px;
        text-align: center;
        transition: all 0.2s;
    }

    .create-shop-link:hover {
        background: #4299e1;
        color: white;
    }
</style> 