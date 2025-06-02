<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { selectedShop } from '$lib/stores/selectedShop';
    import ConfirmationDialog from '$lib/components/ConfirmationDialog.svelte';

    let shops: any[] = [];
    let loading = true;
    let showDeleteDialog = false;
    let shopToDelete: any = null;
    let showEditDialog = false;
    let editingShop: any = null;
    let showCreateDialog = false;
    let newShop = {
        shop_name: '',
        description: '',
        address: '',
        phone: ''
    };

    onMount(async () => {
        await loadShops();
    });

    async function loadShops() {
        try {
            const { data: { session } } = await supabase.auth.getSession();
            if (!session) return;

            const { data: shopsData, error } = await supabase
                .from('seller_shops')
                .select('*')
                .eq('user_id', session.user.id)
                .eq('is_deleted', false);

            if (!error && shopsData) {
                shops = shopsData;
            }
        } catch (e) {
            console.error('Error loading shops:', e);
        } finally {
            loading = false;
        }
    }

    function handleCreateClick() {
        newShop = {
            shop_name: '',
            description: '',
            address: '',
            phone: ''
        };
        showCreateDialog = true;
    }

    function handleEditClick(shop: any) {
        editingShop = { ...shop };
        showEditDialog = true;
    }

    function handleDeleteClick(shop: any) {
        shopToDelete = shop;
        showDeleteDialog = true;
    }

    async function handleCreate() {
        try {
            const { data: { session } } = await supabase.auth.getSession();
            if (!session) return;

            const { error } = await supabase
                .from('seller_shops')
                .insert({
                    user_id: session.user.id,
                    ...newShop
                });

            if (!error) {
                showCreateDialog = false;
                await loadShops();
            }
        } catch (e) {
            console.error('Error creating shop:', e);
        }
    }

    async function handleEdit() {
        try {
            const { error } = await supabase
                .from('seller_shops')
                .update({
                    shop_name: editingShop.shop_name,
                    description: editingShop.description,
                    address: editingShop.address,
                    phone: editingShop.phone
                })
                .eq('id', editingShop.id);

            if (!error) {
                showEditDialog = false;
                await loadShops();
            }
        } catch (e) {
            console.error('Error updating shop:', e);
        }
    }

    async function handleDelete() {
        try {
            const { error } = await supabase
                .from('seller_shops')
                .update({ is_deleted: true })
                .eq('id', shopToDelete.id);

            if (!error) {
                showDeleteDialog = false;
                await loadShops();
                // If the deleted shop was selected, clear the selection
                if ($selectedShop === shopToDelete.id) {
                    selectedShop.set(null);
                }
            }
        } catch (e) {
            console.error('Error deleting shop:', e);
        }
    }

    function handleShopSelect(shopId: string) {
        selectedShop.set(shopId);
    }
</script>

<div class="shops-page">
    <header class="content-header">
        <h2>My Shops</h2>
        <button class="create-button" on:click={handleCreateClick}>
            Create New Shop
        </button>
    </header>

    {#if loading}
        <div class="loading">Loading shops...</div>
    {:else if shops.length === 0}
        <div class="empty-state">
            <p>You haven't created any shops yet.</p>
            <button class="create-button" on:click={handleCreateClick}>
                Create Your First Shop
            </button>
        </div>
    {:else}
        <div class="shops-grid">
            {#each shops as shop}
                <div class="shop-card">
                    <div class="shop-header">
                        <h3>{shop.shop_name}</h3>
                        <div class="shop-actions">
                            <button class="edit-button" on:click={() => handleEditClick(shop)}>
                                Edit
                            </button>
                            <button class="delete-button" on:click={() => handleDeleteClick(shop)}>
                                Delete
                            </button>
                        </div>
                    </div>
                    <div class="shop-info">
                        {#if shop.description}
                            <p class="description">{shop.description}</p>
                        {/if}
                        {#if shop.address}
                            <p class="address">📍 {shop.address}</p>
                        {/if}
                        {#if shop.phone}
                            <p class="phone">📞 {shop.phone}</p>
                        {/if}
                    </div>
                    <div class="shop-footer">
                        <button 
                            class="select-button" 
                            class:selected={$selectedShop === shop.id}
                            on:click={() => handleShopSelect(shop.id)}
                        >
                            {$selectedShop === shop.id ? 'Selected' : 'Select Shop'}
                        </button>
                    </div>
                </div>
            {/each}
        </div>
    {/if}
</div>

<!-- Create Shop Dialog -->
{#if showCreateDialog}
    <div class="dialog-overlay">
        <div class="dialog">
            <h3>Create New Shop</h3>
            <form on:submit|preventDefault={handleCreate}>
                <div class="form-group">
                    <label for="shop_name">Shop Name</label>
                    <input 
                        type="text" 
                        id="shop_name" 
                        bind:value={newShop.shop_name} 
                        required
                        placeholder="Enter shop name"
                    />
                </div>
                <div class="form-group">
                    <label for="description">Description</label>
                    <textarea 
                        id="description" 
                        bind:value={newShop.description}
                        placeholder="Enter shop description"
                    ></textarea>
                </div>
                <div class="form-group">
                    <label for="address">Address</label>
                    <input 
                        type="text" 
                        id="address" 
                        bind:value={newShop.address}
                        placeholder="Enter shop address"
                    />
                </div>
                <div class="form-group">
                    <label for="phone">Phone</label>
                    <input 
                        type="tel" 
                        id="phone" 
                        bind:value={newShop.phone}
                        placeholder="Enter shop phone number"
                    />
                </div>
                <div class="dialog-actions">
                    <button type="button" class="cancel-button" on:click={() => showCreateDialog = false}>
                        Cancel
                    </button>
                    <button type="submit" class="submit-button">
                        Create Shop
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<!-- Edit Shop Dialog -->
{#if showEditDialog}
    <div class="dialog-overlay">
        <div class="dialog">
            <h3>Edit Shop</h3>
            <form on:submit|preventDefault={handleEdit}>
                <div class="form-group">
                    <label for="edit_shop_name">Shop Name</label>
                    <input 
                        type="text" 
                        id="edit_shop_name" 
                        bind:value={editingShop.shop_name} 
                        required
                    />
                </div>
                <div class="form-group">
                    <label for="edit_description">Description</label>
                    <textarea 
                        id="edit_description" 
                        bind:value={editingShop.description}
                    ></textarea>
                </div>
                <div class="form-group">
                    <label for="edit_address">Address</label>
                    <input 
                        type="text" 
                        id="edit_address" 
                        bind:value={editingShop.address}
                    />
                </div>
                <div class="form-group">
                    <label for="edit_phone">Phone</label>
                    <input 
                        type="tel" 
                        id="edit_phone" 
                        bind:value={editingShop.phone}
                    />
                </div>
                <div class="dialog-actions">
                    <button type="button" class="cancel-button" on:click={() => showEditDialog = false}>
                        Cancel
                    </button>
                    <button type="submit" class="submit-button">
                        Save Changes
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<ConfirmationDialog
    bind:isOpen={showDeleteDialog}
    title="Delete Shop"
    message="Are you sure you want to delete this shop? This action cannot be undone."
    confirmText="Delete"
    on:confirm={handleDelete}
/>

<style>
    .shops-page {
        padding: 1rem;
    }

    .content-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .content-header h2 {
        color: #2d3748;
        font-size: 1.5rem;
    }

    .create-button {
        padding: 0.75rem 1.5rem;
        background: #4299e1;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        transition: background 0.2s;
    }

    .create-button:hover {
        background: #3182ce;
    }

    .shops-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        gap: 1.5rem;
    }

    .shop-card {
        background: white;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        overflow: hidden;
    }

    .shop-header {
        padding: 1rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .shop-header h3 {
        color: #2d3748;
        font-size: 1.125rem;
        margin: 0;
    }

    .shop-actions {
        display: flex;
        gap: 0.5rem;
    }

    .edit-button, .delete-button {
        padding: 0.5rem;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        transition: background 0.2s;
    }

    .edit-button {
        background: #4299e1;
        color: white;
    }

    .edit-button:hover {
        background: #3182ce;
    }

    .delete-button {
        background: #e53e3e;
        color: white;
    }

    .delete-button:hover {
        background: #c53030;
    }

    .shop-info {
        padding: 1rem;
    }

    .description {
        color: #4a5568;
        margin-bottom: 0.5rem;
    }

    .address, .phone {
        color: #718096;
        font-size: 0.875rem;
        margin: 0.25rem 0;
    }

    .shop-footer {
        padding: 1rem;
        border-top: 1px solid #e2e8f0;
    }

    .select-button {
        width: 100%;
        padding: 0.75rem;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        transition: all 0.2s;
        background: #e2e8f0;
        color: #4a5568;
    }

    .select-button:hover {
        background: #cbd5e0;
    }

    .select-button.selected {
        background: #48bb78;
        color: white;
    }

    .select-button.selected:hover {
        background: #38a169;
    }

    .empty-state {
        background: white;
        padding: 2rem;
        border-radius: 8px;
        text-align: center;
        color: #718096;
    }

    .empty-state p {
        margin-bottom: 1.5rem;
    }

    .dialog-overlay {
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

    .dialog {
        background: white;
        padding: 2rem;
        border-radius: 8px;
        width: 100%;
        max-width: 500px;
    }

    .dialog h3 {
        color: #2d3748;
        font-size: 1.25rem;
        margin-bottom: 1.5rem;
    }

    .form-group {
        margin-bottom: 1rem;
    }

    .form-group label {
        display: block;
        color: #4a5568;
        margin-bottom: 0.5rem;
    }

    .form-group input,
    .form-group textarea {
        width: 100%;
        padding: 0.75rem;
        border: 1px solid #e2e8f0;
        border-radius: 6px;
        font-size: 1rem;
    }

    .form-group textarea {
        min-height: 100px;
        resize: vertical;
    }

    .dialog-actions {
        display: flex;
        justify-content: flex-end;
        gap: 1rem;
        margin-top: 1.5rem;
    }

    .cancel-button {
        padding: 0.75rem 1.5rem;
        background: #e2e8f0;
        color: #4a5568;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        transition: background 0.2s;
    }

    .cancel-button:hover {
        background: #cbd5e0;
    }

    .submit-button {
        padding: 0.75rem 1.5rem;
        background: #4299e1;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        transition: background 0.2s;
    }

    .submit-button:hover {
        background: #3182ce;
    }

    .loading {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 50vh;
        font-size: 1.2rem;
        color: #4a5568;
    }
</style> 