<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';

    let email = '';
    let password = '';
    let isLoading = false;
    let error: string | null = null;

    onMount(async () => {
        // Check if user is already logged in
        const { data: { session } } = await supabase.auth.getSession();
        if (session) {
            // Check if user is seller
            const { data: userData } = await supabase
                .from('users')
                .select('user_type')
                .eq('id', session.user.id)
                .single();

            if (userData?.user_type === 'seller') {
                goto('/seller/dashboard');
            } else {
                // If not seller, sign out
                await supabase.auth.signOut();
            }
        }
    });

    async function handleLogin() {
        try {
            isLoading = true;
            error = null;

            const { data, error: signInError } = await supabase.auth.signInWithPassword({
                email,
                password
            });

            if (signInError) throw signInError;

            // Verify user is seller
            const { data: userData, error: userError } = await supabase
                .from('users')
                .select('user_type, is_deleted, status')
                .eq('id', data.user.id)
                .single();

            if (userError) throw userError;

            if (userData.user_type !== 'seller') {
                await supabase.auth.signOut();
                throw new Error('Access denied. Seller account required.');
            }

            if (userData.is_deleted) {
                await supabase.auth.signOut();
                throw new Error('This account has been deactivated.');
            }

            if (userData.status === 'pending_verification') {
                await supabase.auth.signOut();
                throw new Error('Your account is pending verification. Please contact the administrator.');
            }

            goto('/seller/dashboard');

        } catch (e: any) {
            error = e?.message || 'An error occurred during login';
        } finally {
            isLoading = false;
        }
    }
</script>

<div class="login-container">
    <div class="login-box">
        <div class="login-header">
            <h1>Seller Login</h1>
            <p>Access your seller dashboard</p>
        </div>

        <form on:submit|preventDefault={handleLogin} class="login-form">
            <div class="form-group">
                <label for="email">Email</label>
                <input
                    type="email"
                    id="email"
                    bind:value={email}
                    placeholder="Enter your email"
                    required
                />
            </div>

            <div class="form-group">
                <label for="password">Password</label>
                <input
                    type="password"
                    id="password"
                    bind:value={password}
                    placeholder="Enter your password"
                    required
                />
            </div>

            {#if error}
                <div class="error-message">
                    {error}
                </div>
            {/if}

            <button type="submit" class="login-button" disabled={isLoading}>
                {#if isLoading}
                    <span class="loading-spinner"></span>
                {:else}
                    Login
                {/if}
            </button>
        </form>
    </div>
</div>

<style>
    .login-container {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        padding: 1rem;
    }

    .login-box {
        background: white;
        padding: 2rem;
        border-radius: 12px;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
        width: 100%;
        max-width: 400px;
    }

    .login-header {
        text-align: center;
        margin-bottom: 2rem;
    }

    .login-header h1 {
        color: #2d3748;
        font-size: 1.8rem;
        margin-bottom: 0.5rem;
    }

    .login-header p {
        color: #718096;
        font-size: 1rem;
    }

    .form-group {
        margin-bottom: 1.5rem;
    }

    .form-group label {
        display: block;
        margin-bottom: 0.5rem;
        color: #4a5568;
        font-weight: 500;
    }

    .form-group input {
        width: 100%;
        padding: 0.75rem;
        border: 2px solid #e2e8f0;
        border-radius: 6px;
        font-size: 1rem;
        transition: border-color 0.2s;
    }

    .form-group input:focus {
        outline: none;
        border-color: #48bb78;
    }

    .login-button {
        width: 100%;
        padding: 0.75rem;
        background: #48bb78;
        color: white;
        border: none;
        border-radius: 6px;
        font-size: 1rem;
        font-weight: 500;
        cursor: pointer;
        transition: background 0.2s;
    }

    .login-button:hover {
        background: #38a169;
    }

    .login-button:disabled {
        background: #a0aec0;
        cursor: not-allowed;
    }

    .error-message {
        background: #fed7d7;
        color: #c53030;
        padding: 0.75rem;
        border-radius: 6px;
        margin-bottom: 1rem;
        font-size: 0.875rem;
    }

    .loading-spinner {
        display: inline-block;
        width: 1rem;
        height: 1rem;
        border: 2px solid #ffffff;
        border-radius: 50%;
        border-top-color: transparent;
        animation: spin 1s linear infinite;
    }

    @keyframes spin {
        to {
            transform: rotate(360deg);
        }
    }
</style> 