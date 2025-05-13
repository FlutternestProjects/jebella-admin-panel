<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';

    let email = '';
    let password = '';
    let confirmPassword = '';
    let isLoading = false;
    let error: string | null = null;
    let success: string | null = null;
    let userType: 'admin' | 'seller' = 'seller';
    let accessCode = '';
    let accessCodeRequired = true;

    onMount(async () => {
        // Check if seller signup is enabled
        const { data: config } = await supabase
            .from('admin_config')
            .select('value')
            .eq('key', 'seller_signup_enabled')
            .single();

        if (config?.value === 'false') {
            goto('/login');
            return;
        }

        // Check if access code is required for admin signup
        if (userType === 'admin') {
            const { data: adminConfig } = await supabase
                .from('admin_config')
                .select('value')
                .eq('key', 'admin_signup_access_code')
                .single();

            if (!adminConfig) {
                accessCodeRequired = false;
            }
        }
    });

    async function handleSignup() {
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

            // Verify access code for admin signup
            if (userType === 'admin' && accessCodeRequired) {
                const { data: config } = await supabase
                    .from('admin_config')
                    .select('value')
                    .eq('key', 'admin_signup_access_code')
                    .single();

                if (config && config.value !== accessCode) {
                    throw new Error('Invalid access code');
                }
            }

            // Sign up with Supabase Auth
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        user_type: userType
                    }
                }
            });

            if (authError) throw authError;

            // Create user record
            const { data: userData, error: userError } = await supabase
                .from('users')
                .insert({
                    auth_id: authData.user?.id,
                    user_type: userType,
                    status: 'active',
                    name: email.split('@')[0], // Using email username as initial name
                    gender: 'other', // Default gender
                    age: 18 // Default age
                })
                .select()
                .single();

            if (userError) throw userError;

            // If seller, create seller shop placeholder
            if (userType === 'seller') {
                const { error: shopError } = await supabase
                    .from('seller_shops')
                    .insert({
                        user_id: userData.id,
                        shop_name: `${userData.name}'s Shop`,
                        description: 'Welcome to my shop!'
                    });

                if (shopError) throw shopError;
            }

            success = `${userType.charAt(0).toUpperCase() + userType.slice(1)} account created successfully!`;
            
            // Clear form
            email = '';
            password = '';
            confirmPassword = '';
            accessCode = '';

            // Redirect to login after 2 seconds
            setTimeout(() => {
                goto('/login');
            }, 2000);

        } catch (e: any) {
            console.error('Signup error:', e);
            error = e?.message || 'An error occurred during signup';
        } finally {
            isLoading = false;
        }
    }
</script>

<div class="signup-container">
    <div class="signup-box">
        <div class="signup-header">
            <h1>Create Account</h1>
            <p>Join Jebella as a {userType}</p>
        </div>

        <div class="signup-type-toggle">
            <button 
                class:active={userType === 'admin'} 
                on:click={() => userType = 'admin'}
            >
                Admin Signup
            </button>
            <button 
                class:active={userType === 'seller'} 
                on:click={() => userType = 'seller'}
            >
                Seller Signup
            </button>
        </div>

        <form on:submit|preventDefault={handleSignup} class="signup-form">
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
                    placeholder="Enter password"
                    required
                />
            </div>

            <div class="form-group">
                <label for="confirmPassword">Confirm Password</label>
                <input
                    type="password"
                    id="confirmPassword"
                    bind:value={confirmPassword}
                    placeholder="Confirm password"
                    required
                />
            </div>

            {#if userType === 'admin' && accessCodeRequired}
                <div class="form-group">
                    <label for="accessCode">Access Code</label>
                    <input
                        type="text"
                        id="accessCode"
                        bind:value={accessCode}
                        placeholder="Enter access code"
                        required
                    />
                </div>
            {/if}

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

            <button type="submit" class="signup-button" disabled={isLoading}>
                {#if isLoading}
                    <span class="loading-spinner"></span>
                {:else}
                    Create {userType.charAt(0).toUpperCase() + userType.slice(1)} Account
                {/if}
            </button>

            <div class="back-link">
                <a href="/login">Already have an account? Login</a>
            </div>
        </form>
    </div>
</div>

<style>
    .signup-container {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        padding: 1rem;
    }

    .signup-box {
        background: white;
        padding: 2rem;
        border-radius: 12px;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
        width: 100%;
        max-width: 400px;
    }

    .signup-header {
        text-align: center;
        margin-bottom: 2rem;
    }

    .signup-header h1 {
        color: #2d3748;
        font-size: 1.8rem;
        margin-bottom: 0.5rem;
    }

    .signup-header p {
        color: #718096;
        font-size: 1rem;
    }

    .signup-type-toggle {
        display: flex;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .signup-type-toggle button {
        flex: 1;
        padding: 0.75rem;
        border: 2px solid #e2e8f0;
        background: white;
        border-radius: 6px;
        cursor: pointer;
        transition: all 0.2s;
        font-weight: 500;
    }

    .signup-type-toggle button.active {
        background: #4299e1;
        color: white;
        border-color: #4299e1;
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

    .signup-button {
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

    .signup-button:hover {
        background: #3182ce;
    }

    .signup-button:disabled {
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

    .back-link {
        text-align: center;
        margin-top: 1rem;
    }

    .back-link a {
        color: #4299e1;
        text-decoration: none;
        font-size: 0.875rem;
    }

    .back-link a:hover {
        text-decoration: underline;
    }

    @keyframes spin {
        to {
            transform: rotate(360deg);
        }
    }
</style> 