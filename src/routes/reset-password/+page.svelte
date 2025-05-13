<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';
    import { page } from '$app/stores';

    let password = '';
    let confirmPassword = '';
    let isLoading = false;
    let error: string | null = null;
    let success: string | null = null;

    onMount(async () => {
        // Check if we have a valid session
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) {
            // If no session, redirect to login
            goto('/seller/login');
        }
    });

    async function handleResetPassword() {
        try {
            isLoading = true;
            error = null;
            success = null;

            // Validate passwords match
            if (password !== confirmPassword) {
                throw new Error('Passwords do not match');
            }

            // Validate password strength
            if (password.length < 8) {
                throw new Error('Password must be at least 8 characters long');
            }

            // Update password
            const { error: updateError } = await supabase.auth.updateUser({
                password: password
            });

            if (updateError) throw updateError;

            success = 'Password updated successfully! Redirecting to login...';
            
            // Redirect to login after 2 seconds
            setTimeout(() => {
                goto('/seller/login');
            }, 2000);

        } catch (e: any) {
            error = e?.message || 'An error occurred while resetting password';
        } finally {
            isLoading = false;
        }
    }
</script>

<div class="reset-password-container">
    <div class="reset-password-box">
        <div class="reset-password-header">
            <h1>Reset Password</h1>
            <p>Please enter your new password</p>
        </div>

        <form on:submit|preventDefault={handleResetPassword} class="reset-password-form">
            <div class="form-group">
                <label for="password">New Password</label>
                <input
                    type="password"
                    id="password"
                    bind:value={password}
                    placeholder="Enter new password"
                    required
                />
            </div>

            <div class="form-group">
                <label for="confirmPassword">Confirm Password</label>
                <input
                    type="password"
                    id="confirmPassword"
                    bind:value={confirmPassword}
                    placeholder="Confirm new password"
                    required
                />
            </div>

            {#if error}
                <div class="error-message">
                    {error}
                </div>
            {/if}

            {#if success}
                <div class="success-message">
                    {success}
                </div>
            {/if}

            <button type="submit" class="reset-button" disabled={isLoading}>
                {#if isLoading}
                    <span class="loading-spinner"></span>
                {:else}
                    Reset Password
                {/if}
            </button>
        </form>
    </div>
</div>

<style>
    .reset-password-container {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        padding: 1rem;
    }

    .reset-password-box {
        background: white;
        padding: 2rem;
        border-radius: 12px;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
        width: 100%;
        max-width: 400px;
    }

    .reset-password-header {
        text-align: center;
        margin-bottom: 2rem;
    }

    .reset-password-header h1 {
        color: #2d3748;
        font-size: 1.8rem;
        margin-bottom: 0.5rem;
    }

    .reset-password-header p {
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
        border-color: #4299e1;
    }

    .reset-button {
        width: 100%;
        padding: 0.75rem;
        background: #4299e1;
        color: white;
        border: none;
        border-radius: 6px;
        font-size: 1rem;
        font-weight: 500;
        cursor: pointer;
        transition: background 0.2s;
    }

    .reset-button:hover {
        background: #3182ce;
    }

    .reset-button:disabled {
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

    .success-message {
        background: #c6f6d5;
        color: #2f855a;
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