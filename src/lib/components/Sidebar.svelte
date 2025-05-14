<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';
    import { page } from '$app/stores';
    import ConfirmationDialog from '$lib/components/ConfirmationDialog.svelte';

    let user: any = null;
    let error: string | null = null;
    let showLogoutDialog = false;

    onMount(async () => {
        try {
            // Get current session
            const { data: { session }, error: sessionError } = await supabase.auth.getSession();
            if (sessionError) throw sessionError;
            if (!session) {
                goto('/admin/login');
                return;
            }

            // Get user data
            const { data: userData, error: userError } = await supabase
                .from('users')
                .select('*')
                .eq('id', session.user.id)
                .single();

            if (userError) throw new Error('User not found');
            if (userData.user_type !== 'admin') {
                throw new Error('Unauthorized: Admin access required');
            }

            user = userData;

        } catch (e: any) {
            error = e?.message || 'An error occurred';
            if (error?.includes('Unauthorized')) {
                goto('/admin/login');
            }
        }
    });

    function handleLogoutClick() {
        showLogoutDialog = true;
    }

    async function handleLogout() {
        await supabase.auth.signOut();
        goto('/admin/login');
    }
</script>

<ConfirmationDialog
    bind:isOpen={showLogoutDialog}
    title="Confirm Logout"
    message="Are you sure you want to logout from your admin account?"
    confirmText="Logout"
    on:confirm={handleLogout}
/>

<nav class="sidebar">
    <div class="logo">
        <h1>Jebella Admin</h1>
    </div>
    <ul class="nav-links">
        <li class:active={$page.url.pathname === '/admin/dashboard'}>
            <a href="/admin/dashboard">Dashboard</a>
        </li>
        <li class:active={$page.url.pathname === '/admin/sellers'}>
            <a href="/admin/sellers">Manage Sellers</a>
        </li>
        <li class:active={$page.url.pathname === '/admin/brands'}>
            <a href="/admin/brands">Manage Brands</a>
        </li>
        <li class:active={$page.url.pathname === '/admin/categories'}>
            <a href="/admin/categories">Manage Categories</a>
        </li>
        <li class:active={$page.url.pathname === '/admin/subcategories'}>
            <a href="/admin/subcategories">Manage Subcategories</a>
        </li>
        <li class:active={$page.url.pathname === '/admin/audiences'}>
            <a href="/admin/audiences">Manage Audiences</a>
        </li>
        <li class:active={$page.url.pathname === '/admin/colors'}>
            <a href="/admin/colors">Manage Colors</a>
        </li>
        <li class:active={$page.url.pathname === '/admin/sizes'}>
            <a href="/admin/sizes">Manage Sizes</a>
        </li>
    </ul>
    <div class="user-section">
        <div class="user-info">
            <span class="user-name">{user?.name ?? 'Loading...'}</span>
            <span class="user-role">Admin</span>
        </div>
        <button class="logout-button" on:click={handleLogoutClick}>
            Logout
        </button>
    </div>
</nav>

<style>
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
</style> 