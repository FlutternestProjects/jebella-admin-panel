<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';

    // Check for admin signup access
    const ADMIN_SIGNUP_ENABLED = import.meta.env.VITE_ENABLE_ADMIN_SIGNUP === 'true';

    let email = '';
    let password = '';
    let confirmPassword = '';
    let isLoading = false;
    let error: string | null = null;
    let success: string | null = null;
    let accessCode = '';
    let accessCodeRequired = true;

    
    onMount(async () => {
        // Redirect if admin signup is disabled
        if (!ADMIN_SIGNUP_ENABLED) {
            goto('/login');
            return;
        }

        try {
            // Check if access code is required
            const { data: config, error } = await supabase
                .from('admin_config')
                .select('value')
                .eq('key', 'admin_signup_access_code')
                .single();
            
            if (error) {
                // If table doesn't exist or other error, default to no access code required
                console.warn('Could not check admin config:', error);
                accessCodeRequired = false;
            } else if (!config) {
                accessCodeRequired = false;
            }
        } catch (e) {
            console.warn('Error checking admin config:', e);
            accessCodeRequired = false;
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
            

            let { data: userData, error: userError  } = await supabase.auth.signUp({
                email:  email,
                password: password
            });

            if (userError) {
                throw new Error(`Failed to create user: ${userError.message}`);
            }

            if (!userData) {
                throw new Error('No user data returned after creation');
            }

            // Create user record
            const { data: dbUserData, error: dbUserError } = await supabase
                .from('users')
                .insert({
                    id: userData.user?.id,
                    user_type: 'admin',
                    status: 'active',
                    name: email.split('@')[0], // Using email username as initial name
                    gender: 'other', // Default gender
                    age: 18 // Default age
                })
                .select()
                .single();

            if (dbUserError) {
                console.error('Error creating user:', dbUserError);
                throw new Error(`Failed to create user: ${dbUserError.message}`);
            }

            if (!dbUserData) {
                throw new Error('No user data returned after creation');
            }

            // Insert email
            const { error: emailError } = await supabase
                .from('user_emails')
                .insert({
                    user_id: userData.user?.id,
                    email,
                    is_primary: true
                });

            if (emailError) {
                console.error('Error creating email:', emailError);
                throw new Error(`Failed to create email: ${emailError.message}`);
            }

            success = 'Admin account created successfully!';
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
            <h1>Admin Signup</h1>
            <p class="dev-warning">⚠️ Development Mode Only</p>
        </div>

        <form on:submit|preventDefault={handleSignup} class="signup-form">
            <div class="form-group">
                <label for="email">Email</label>
                <input
                    type="email"
                    id="email"
                    bind:value={email}
                    placeholder="Enter admin email"
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

            {#if accessCodeRequired}
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
                    Create Admin Account
                {/if}
            </button>

            <div class="back-link">
                <a href="/login">Back to Login</a>
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

    .dev-warning {
        color: #e53e3e;
        font-size: 0.875rem;
        font-weight: 500;
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