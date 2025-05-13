<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';

    interface SellerFormData {
        id?: string;
        email: string;
        name: string;
        gender: string;
        age: number;
    }

    let sellers: any[] = [];
    let isLoading = false;
    let error: string | null = null;
    let success: string | null = null;
    let successTimeout: ReturnType<typeof setTimeout> | null = null;
    let currentPage = 1;
    let totalPages = 1;
    let itemsPerPage = 10;
    let totalItems = 0;

    // Form data for add/edit
    let showForm = false;
    let isEditing = false;
    let formData: SellerFormData = {
        email: '',
        name: '',
        gender: 'other',
        age: 18
    };

    onMount(async () => {
        await loadSellers();
    });

    async function loadSellers() {
        try {
            isLoading = true;
            error = null;

            // Get total count
            const { count, error: countError } = await supabase
                .from('users')
                .select('*', { count: 'exact', head: true })
                .eq('user_type', 'seller')
                .eq('is_deleted', false);

            if (countError) throw countError;
            totalItems = count || 0;
            totalPages = Math.ceil(totalItems / itemsPerPage);

            // Get paginated sellers
            const { data, error: sellersError } = await supabase
                .from('users')
                .select(`
                    *,
                    user_emails!inner(email)
                `)
                .eq('user_type', 'seller')
                .eq('is_deleted', false)
                .range((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage - 1)
                .order('created_at', { ascending: false });

            if (sellersError) throw sellersError;
            sellers = data || [];

        } catch (e: any) {
            error = e?.message || 'An error occurred while loading sellers';
        } finally {
            isLoading = false;
        }
    }

    function showSuccessMessage(message: string) {
        success = message;
        if (successTimeout) clearTimeout(successTimeout);
        successTimeout = setTimeout(() => {
            success = null;
        }, 4000);
    }

    async function handleAddSeller() {
        try {
            isLoading = true;
            error = null;
            success = null;

            // Call our server endpoint to invite the user
            const response = await fetch('/api/invite-seller', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ email: formData.email })
            });

            const result = await response.json();
            if (!result.success) throw new Error(result.error);

            // Create user record
            const { data: userData, error: userError } = await supabase
                .from('users')
                .insert({
                    id: result.data.user.id,
                    user_type: 'seller',
                    status: 'pending_verification',
                    name: formData.name,
                    gender: formData.gender,
                    age: formData.age
                })
                .select()
                .single();

            if (userError) throw userError;

            // Create email record
            const { error: emailError } = await supabase
                .from('user_emails')
                .insert({
                    user_id: result.data.user.id,
                    email: formData.email,
                    is_primary: true
                });

            if (emailError) throw emailError;

            showSuccessMessage('Seller invited successfully. They will receive an email to set up their account.');
            showForm = false;
            await loadSellers();

        } catch (e: any) {
            error = e?.message || 'An error occurred while adding seller';
        } finally {
            isLoading = false;
        }
    }

    async function handleEditSeller() {
        try {
            isLoading = true;
            error = null;
            success = null;

            const { error: updateError } = await supabase
                .from('users')
                .update({
                    name: formData.name,
                    gender: formData.gender,
                    age: formData.age
                })
                .eq('id', formData.id);

            if (updateError) throw updateError;

            showSuccessMessage('Seller updated successfully');
            showForm = false;
            await loadSellers();

        } catch (e: any) {
            error = e?.message || 'An error occurred while updating seller';
        } finally {
            isLoading = false;
        }
    }

    async function handleDeleteSeller(id: string) {
        if (!confirm('Are you sure you want to delete this seller?')) return;

        try {
            isLoading = true;
            error = null;
            success = null;

            const { error: deleteError } = await supabase
                .from('users')
                .update({ is_deleted: true })
                .eq('id', id);

            if (deleteError) throw deleteError;

            showSuccessMessage('Seller deleted successfully');
            await loadSellers();

        } catch (e: any) {
            error = e?.message || 'An error occurred while deleting seller';
        } finally {
            isLoading = false;
        }
    }

    function openEditForm(seller: any) {
        formData = {
            id: seller.id,
            email: seller.user_emails[0].email,
            name: seller.name,
            gender: seller.gender,
            age: seller.age
        };
        isEditing = true;
        showForm = true;
    }

    function resetForm() {
        formData = {
            email: '',
            name: '',
            gender: 'other',
            age: 18
        };
        isEditing = false;
        showForm = false;
    }
</script>

<div class="sellers-container">
    <div class="header">
        <h1>Manage Sellers</h1>
        <button class="add-button" on:click={() => { resetForm(); showForm = true; }}>
            Add New Seller
        </button>
    </div>

    {#if error}
        <div class="error-message">{error}</div>
    {/if}

    {#if success}
        <div class="success-message">{success}</div>
    {/if}

    {#if showForm}
        <div class="form-overlay">
            <div class="form-container">
                <h2>{isEditing ? 'Edit' : 'Add'} Seller</h2>
                <form on:submit|preventDefault={isEditing ? handleEditSeller : handleAddSeller}>
                    {#if !isEditing}
                        <div class="form-group">
                            <label for="email">Email</label>
                            <input
                                type="email"
                                id="email"
                                bind:value={formData.email}
                                required
                            />
                        </div>
                    {/if}
                    <div class="form-group">
                        <label for="name">Name</label>
                        <input
                            type="text"
                            id="name"
                            bind:value={formData.name}
                            required
                        />
                    </div>
                    <div class="form-group">
                        <label for="gender">Gender</label>
                        <select id="gender" bind:value={formData.gender}>
                            <option value="male">Male</option>
                            <option value="female">Female</option>
                            <option value="other">Other</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="age">Age</label>
                        <input
                            type="number"
                            id="age"
                            bind:value={formData.age}
                            min="18"
                            required
                        />
                    </div>
                    <div class="form-actions">
                        <button type="submit" class="submit-button" disabled={isLoading}>
                            {#if isLoading}
                                <span class="loading-spinner"></span>
                            {:else}
                                {isEditing ? 'Update' : 'Add'} Seller
                            {/if}
                        </button>
                        <button type="button" class="cancel-button" on:click={resetForm}>
                            Cancel
                        </button>
                    </div>
                </form>
            </div>
        </div>
    {/if}

    <div class="sellers-list">
        <table>
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Gender</th>
                    <th>Age</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                {#if isLoading}
                    <tr>
                        <td colspan="6" class="loading">Loading...</td>
                    </tr>
                {:else if sellers.length === 0}
                    <tr>
                        <td colspan="6" class="empty">No sellers found</td>
                    </tr>
                {:else}
                    {#each sellers as seller}
                        <tr>
                            <td>{seller.name}</td>
                            <td>{seller.user_emails[0].email}</td>
                            <td>{seller.gender}</td>
                            <td>{seller.age}</td>
                            <td>{seller.status}</td>
                            <td class="actions">
                                <button class="edit-button" on:click={() => openEditForm(seller)}>
                                    Edit
                                </button>
                                <button class="delete-button" on:click={() => handleDeleteSeller(seller.id)}>
                                    Delete
                                </button>
                            </td>
                        </tr>
                    {/each}
                {/if}
            </tbody>
        </table>
    </div>

    {#if totalPages > 1}
        <div class="pagination">
            <button 
                disabled={currentPage === 1} 
                on:click={() => { currentPage--; loadSellers(); }}
            >
                Previous
            </button>
            <span>Page {currentPage} of {totalPages}</span>
            <button 
                disabled={currentPage === totalPages} 
                on:click={() => { currentPage++; loadSellers(); }}
            >
                Next
            </button>
        </div>
    {/if}
</div>

<style>
    .sellers-container {
        padding: 2rem;
    }

    .header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .add-button {
        padding: 0.75rem 1.5rem;
        background: #4299e1;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        transition: background 0.2s;
    }

    .add-button:hover {
        background: #3182ce;
    }

    .form-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
    }

    .form-container {
        background: white;
        padding: 2rem;
        border-radius: 12px;
        width: 100%;
        max-width: 500px;
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

    .form-group input,
    .form-group select {
        width: 100%;
        padding: 0.75rem;
        border: 2px solid #e2e8f0;
        border-radius: 6px;
        font-size: 1rem;
    }

    .form-actions {
        display: flex;
        gap: 1rem;
        margin-top: 2rem;
    }

    .submit-button,
    .cancel-button {
        padding: 0.75rem 1.5rem;
        border-radius: 6px;
        cursor: pointer;
        transition: all 0.2s;
    }

    .submit-button {
        background: #4299e1;
        color: white;
        border: none;
    }

    .submit-button:hover {
        background: #3182ce;
    }

    .cancel-button {
        background: white;
        color: #4a5568;
        border: 2px solid #e2e8f0;
    }

    .cancel-button:hover {
        background: #f7fafc;
    }

    .sellers-list {
        background: white;
        border-radius: 12px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        overflow: hidden;
    }

    table {
        width: 100%;
        border-collapse: collapse;
    }

    th, td {
        padding: 1rem;
        text-align: left;
        border-bottom: 1px solid #e2e8f0;
    }

    th {
        background: #f7fafc;
        font-weight: 500;
        color: #4a5568;
    }

    .actions {
        display: flex;
        gap: 0.5rem;
    }

    .edit-button,
    .delete-button {
        padding: 0.5rem 1rem;
        border-radius: 4px;
        cursor: pointer;
        transition: all 0.2s;
    }

    .edit-button {
        background: #4299e1;
        color: white;
        border: none;
    }

    .edit-button:hover {
        background: #3182ce;
    }

    .delete-button {
        background: #e53e3e;
        color: white;
        border: none;
    }

    .delete-button:hover {
        background: #c53030;
    }

    .pagination {
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 1rem;
        margin-top: 2rem;
    }

    .pagination button {
        padding: 0.5rem 1rem;
        border: 2px solid #e2e8f0;
        border-radius: 6px;
        background: white;
        cursor: pointer;
        transition: all 0.2s;
    }

    .pagination button:disabled {
        opacity: 0.5;
        cursor: not-allowed;
    }

    .pagination button:not(:disabled):hover {
        background: #f7fafc;
    }

    .error-message,
    .success-message {
        padding: 1rem;
        border-radius: 6px;
        margin-bottom: 1rem;
    }

    .error-message {
        background: #fed7d7;
        color: #c53030;
    }

    .success-message {
        background: #c6f6d5;
        color: #2f855a;
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