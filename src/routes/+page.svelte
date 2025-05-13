<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';

    let connectionStatus = 'Testing connection...';
    let error: string | null = null;

    onMount(async () => {
        try {
            // Try to fetch the current user session
            const { data, error: sessionError } = await supabase.auth.getSession();
            
            if (sessionError) throw sessionError;
            
            connectionStatus = 'Successfully connected to Supabase!';
            console.log('Supabase connection successful:', data);
        } catch (e: any) {
            error = e?.message || 'An unknown error occurred';
            connectionStatus = 'Failed to connect to Supabase';
            console.error('Supabase connection error:', e);
        }
    });

    function handleAdminLogin() {
        goto('/admin/login');
    }

    function handleSellerLogin() {
        goto('/seller/login');
    }
</script>

<div class="landing-container">
    <div class="content">
        <h1>Welcome to Jebella Admin</h1>
        <p class="subtitle">Your comprehensive platform for managing sellers and business operations</p>
        
        <div class="features">
            <div class="feature">
                <h3>Seller Management</h3>
                <p>Easily manage and monitor your sellers' activities</p>
            </div>
            <div class="feature">
                <h3>Business Analytics</h3>
                <p>Track performance and make data-driven decisions</p>
            </div>
            <div class="feature">
                <h3>Secure Access</h3>
                <p>Enterprise-grade security for your business operations</p>
            </div>
        </div>

        <div class="login-buttons">
            <button class="login-button admin" on:click={handleAdminLogin}>
                Admin Login
            </button>
            <button class="login-button seller" on:click={handleSellerLogin}>
                Seller Login
            </button>
        </div>
    </div>
</div>

<style>
    .landing-container {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        padding: 2rem;
    }

    .content {
        max-width: 800px;
        text-align: center;
        background: white;
        padding: 3rem;
        border-radius: 16px;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
    }

    h1 {
        color: #2d3748;
        font-size: 2.5rem;
        margin-bottom: 1rem;
    }

    .subtitle {
        color: #718096;
        font-size: 1.2rem;
        margin-bottom: 3rem;
    }

    .features {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 2rem;
        margin-bottom: 3rem;
    }

    .feature {
        padding: 1.5rem;
        background: #f7fafc;
        border-radius: 8px;
        transition: transform 0.2s;
    }

    .feature:hover {
        transform: translateY(-5px);
    }

    .feature h3 {
        color: #2d3748;
        margin-bottom: 0.5rem;
    }

    .feature p {
        color: #718096;
        font-size: 0.9rem;
    }

    .login-buttons {
        display: flex;
        gap: 1rem;
        justify-content: center;
    }

    .login-button {
        padding: 1rem 2rem;
        font-size: 1.1rem;
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.2s;
        border: none;
        min-width: 160px;
    }

    .login-button.admin {
        background: #4299e1;
        color: white;
    }

    .login-button.admin:hover {
        background: #3182ce;
    }

    .login-button.seller {
        background: #48bb78;
        color: white;
    }

    .login-button.seller:hover {
        background: #38a169;
    }

    @media (max-width: 640px) {
        .content {
            padding: 2rem;
        }

        h1 {
            font-size: 2rem;
        }

        .features {
            grid-template-columns: 1fr;
        }

        .login-buttons {
            flex-direction: column;
        }
    }
</style>
