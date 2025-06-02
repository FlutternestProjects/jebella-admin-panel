<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { selectedShop } from '$lib/stores/selectedShop';
    import { goto } from '$app/navigation';

    let loading = true;
    let inventory: any[] = [];
    let totalCount = 0;
    let currentPage = 1;
    let itemsPerPage = 10;
    let searchQuery = '';
    let selectedProduct: any = null;
    let showEditModal = false;
    let showAddModal = false;

    // Form data
    let inventoryForm = {
        product_id: null as string | null,
        variant_id: null as string | null,
        quantity: 0,
        location: '',
        notes: ''
    };

    onMount(async () => {
        await loadInventory();
    });

    async function loadInventory() {
        try {
            const selectedShopId = $selectedShop;
            if (!selectedShopId) {
                loading = false;
                return;
            }

            let query = supabase
                .from('inventory')
                .select(`
                    *,
                    product:products (
                        id,
                        title,
                        sub_title,
                        brand:brands (name),
                        category:categories (name),
                        subcategory:subcategories (name)
                    ),
                    variant:product_variants (
                        id,
                        name,
                        sku,
                        size:sizes (label),
                        color:colors (name, hex_code)
                    )
                `, { count: 'exact' })
                .eq('shop_id', selectedShopId)
                .eq('is_deleted', false);

            // Add search if query exists
            if (searchQuery) {
                query = query.or(`
                    product.title.ilike.%${searchQuery}%,
                    product.sub_title.ilike.%${searchQuery}%,
                    variant.sku.ilike.%${searchQuery}%,
                    variant.name.ilike.%${searchQuery}%
                `);
            }

            // Add pagination
            const from = (currentPage - 1) * itemsPerPage;
            const to = from + itemsPerPage - 1;
            query = query.range(from, to);

            const { data, error, count } = await query;

            if (!error && data) {
                inventory = data;
                totalCount = count || 0;
            }

        } catch (e) {
            console.error('Error:', e);
        } finally {
            loading = false;
        }
    }

    async function handleSearch() {
        currentPage = 1;
        await loadInventory();
    }

    async function handlePageChange(newPage: number) {
        currentPage = newPage;
        await loadInventory();
    }

    async function handleAdd() {
        try {
            if (!$selectedShop) {
                alert('Please select a shop first');
                return;
            }

            const { error } = await supabase
                .from('inventory')
                .insert({
                    ...inventoryForm,
                    shop_id: $selectedShop
                });

            if (error) throw error;

            showAddModal = false;
            resetForm();
            await loadInventory();
            alert('Inventory item added successfully!');

        } catch (error: any) {
            console.error('Error:', error);
            alert(error.message || 'An error occurred while adding the inventory item');
        }
    }

    async function handleUpdate() {
        try {
            if (!selectedProduct) return;

            const { error } = await supabase
                .from('inventory')
                .update({
                    quantity: inventoryForm.quantity,
                    location: inventoryForm.location,
                    notes: inventoryForm.notes
                })
                .eq('id', selectedProduct.id);

            if (error) throw error;

            showEditModal = false;
            resetForm();
            await loadInventory();
            alert('Inventory item updated successfully!');

        } catch (error: any) {
            console.error('Error:', error);
            alert(error.message || 'An error occurred while updating the inventory item');
        }
    }

    async function handleDelete(id: string) {
        if (!confirm('Are you sure you want to delete this inventory item?')) return;

        try {
            const { error } = await supabase
                .from('inventory')
                .update({ is_deleted: true })
                .eq('id', id);

            if (error) throw error;

            await loadInventory();
            alert('Inventory item deleted successfully!');

        } catch (error: any) {
            console.error('Error:', error);
            alert(error.message || 'An error occurred while deleting the inventory item');
        }
    }

    function openEditModal(item: any) {
        selectedProduct = item;
        inventoryForm = {
            product_id: item.product_id,
            variant_id: item.variant_id,
            quantity: item.quantity,
            location: item.location,
            notes: item.notes
        };
        showEditModal = true;
    }

    function resetForm() {
        inventoryForm = {
            product_id: null,
            variant_id: null,
            quantity: 0,
            location: '',
            notes: ''
        };
        selectedProduct = null;
    }

    $: totalPages = Math.ceil(totalCount / itemsPerPage);
</script>

{#if loading}
    <div class="loading">Loading...</div>
{:else if !$selectedShop}
    <div class="setup-shop">
        <h3>Select or Create a Shop</h3>
        <p>You need to select or create a shop to manage inventory</p>
        <a href="/seller/shops" class="setup-button">Manage Shops</a>
    </div>
{:else}
    <div class="inventory-container">
        <header class="content-header">
            <h2>Inventory Management</h2>
            <button class="add-button" on:click={() => showAddModal = true}>
                Add Inventory Item
            </button>
        </header>

        <div class="search-bar">
            <input
                type="text"
                placeholder="Search by product name, SKU, or variant..."
                bind:value={searchQuery}
                on:keydown={(e) => e.key === 'Enter' && handleSearch()}
            />
            <button on:click={handleSearch}>Search</button>
        </div>

        <div class="inventory-table">
            <table>
                <thead>
                    <tr>
                        <th>Product</th>
                        <th>Variant</th>
                        <th>SKU</th>
                        <th>Quantity</th>
                        <th>Location</th>
                        <th>Last Updated</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {#each inventory as item}
                        <tr>
                            <td>
                                <div class="product-info">
                                    <span class="product-title">{item.product.title}</span>
                                    {#if item.product.sub_title}
                                        <span class="product-subtitle">{item.product.sub_title}</span>
                                    {/if}
                                </div>
                            </td>
                            <td>
                                <div class="variant-info">
                                    <span>{item.variant.name}</span>
                                    {#if item.variant.size}
                                        <span class="variant-attribute">Size: {item.variant.size.label}</span>
                                    {/if}
                                    {#if item.variant.color}
                                        <div class="color-info">
                                            <span class="variant-attribute">Color: {item.variant.color.name}</span>
                                            <div 
                                                class="color-swatch"
                                                style="background-color: {item.variant.color.hex_code}"
                                            ></div>
                                        </div>
                                    {/if}
                                </div>
                            </td>
                            <td>{item.variant.sku}</td>
                            <td>
                                <span class="quantity-badge {item.quantity <= 0 ? 'out-of-stock' : item.quantity < 10 ? 'low-stock' : ''}">
                                    {item.quantity}
                                </span>
                            </td>
                            <td>{item.location || '-'}</td>
                            <td>{new Date(item.updated_at).toLocaleDateString()}</td>
                            <td>
                                <div class="action-buttons">
                                    <button 
                                        class="edit-button"
                                        on:click={() => openEditModal(item)}
                                    >
                                        Edit
                                    </button>
                                    <button 
                                        class="delete-button"
                                        on:click={() => handleDelete(item.id)}
                                    >
                                        Delete
                                    </button>
                                </div>
                            </td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>

        {#if totalPages > 1}
            <div class="pagination">
                <button 
                    disabled={currentPage === 1}
                    on:click={() => handlePageChange(currentPage - 1)}
                >
                    Previous
                </button>
                <span>Page {currentPage} of {totalPages}</span>
                <button 
                    disabled={currentPage === totalPages}
                    on:click={() => handlePageChange(currentPage + 1)}
                >
                    Next
                </button>
            </div>
        {/if}
    </div>

    {#if showAddModal}
        <div class="modal-overlay">
            <div class="modal-content">
                <h3>Add Inventory Item</h3>
                <form on:submit|preventDefault={handleAdd}>
                    <div class="form-group">
                        <label for="quantity">Quantity *</label>
                        <input
                            type="number"
                            id="quantity"
                            bind:value={inventoryForm.quantity}
                            min="0"
                            required
                        />
                    </div>

                    <div class="form-group">
                        <label for="location">Location</label>
                        <input
                            type="text"
                            id="location"
                            bind:value={inventoryForm.location}
                            placeholder="e.g., Warehouse A, Shelf B3"
                        />
                    </div>

                    <div class="form-group">
                        <label for="notes">Notes</label>
                        <textarea
                            id="notes"
                            bind:value={inventoryForm.notes}
                            placeholder="Additional information about this inventory item"
                        ></textarea>
                    </div>

                    <div class="modal-actions">
                        <button type="button" class="cancel-button" on:click={() => showAddModal = false}>
                            Cancel
                        </button>
                        <button type="submit" class="submit-button">
                            Add Item
                        </button>
                    </div>
                </form>
            </div>
        </div>
    {/if}

    {#if showEditModal}
        <div class="modal-overlay">
            <div class="modal-content">
                <h3>Edit Inventory Item</h3>
                <form on:submit|preventDefault={handleUpdate}>
                    <div class="form-group">
                        <label for="edit-quantity">Quantity *</label>
                        <input
                            type="number"
                            id="edit-quantity"
                            bind:value={inventoryForm.quantity}
                            min="0"
                            required
                        />
                    </div>

                    <div class="form-group">
                        <label for="edit-location">Location</label>
                        <input
                            type="text"
                            id="edit-location"
                            bind:value={inventoryForm.location}
                            placeholder="e.g., Warehouse A, Shelf B3"
                        />
                    </div>

                    <div class="form-group">
                        <label for="edit-notes">Notes</label>
                        <textarea
                            id="edit-notes"
                            bind:value={inventoryForm.notes}
                            placeholder="Additional information about this inventory item"
                        ></textarea>
                    </div>

                    <div class="modal-actions">
                        <button type="button" class="cancel-button" on:click={() => showEditModal = false}>
                            Cancel
                        </button>
                        <button type="submit" class="submit-button">
                            Update Item
                        </button>
                    </div>
                </form>
            </div>
        </div>
    {/if}
{/if}

<style>
    .inventory-container {
        padding: 2rem;
    }

    .content-header {
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

    .search-bar {
        display: flex;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .search-bar input {
        flex: 1;
        padding: 0.75rem;
        border: 2px solid #e2e8f0;
        border-radius: 6px;
        font-size: 1rem;
    }

    .search-bar button {
        padding: 0.75rem 1.5rem;
        background: #4299e1;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
    }

    .inventory-table {
        background: white;
        border-radius: 8px;
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
        font-weight: 600;
        color: #4a5568;
    }

    .product-info {
        display: flex;
        flex-direction: column;
    }

    .product-title {
        font-weight: 500;
        color: #2d3748;
    }

    .product-subtitle {
        font-size: 0.875rem;
        color: #718096;
    }

    .variant-info {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
    }

    .variant-attribute {
        font-size: 0.875rem;
        color: #718096;
    }

    .color-info {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .color-swatch {
        width: 1rem;
        height: 1rem;
        border-radius: 4px;
        border: 1px solid #e2e8f0;
    }

    .quantity-badge {
        display: inline-block;
        padding: 0.25rem 0.5rem;
        border-radius: 4px;
        font-weight: 500;
    }

    .quantity-badge.out-of-stock {
        background: #fed7d7;
        color: #c53030;
    }

    .quantity-badge.low-stock {
        background: #fefcbf;
        color: #975a16;
    }

    .action-buttons {
        display: flex;
        gap: 0.5rem;
    }

    .edit-button,
    .delete-button {
        padding: 0.5rem;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.875rem;
    }

    .edit-button {
        background: #4299e1;
        color: white;
    }

    .delete-button {
        background: #e53e3e;
        color: white;
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
        background: #4299e1;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
    }

    .pagination button:disabled {
        background: #cbd5e0;
        cursor: not-allowed;
    }

    .modal-overlay {
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

    .modal-content {
        background: white;
        padding: 2rem;
        border-radius: 8px;
        width: 100%;
        max-width: 500px;
    }

    .modal-content h3 {
        margin-bottom: 1.5rem;
        color: #2d3748;
    }

    .form-group {
        margin-bottom: 1rem;
    }

    .form-group label {
        display: block;
        margin-bottom: 0.5rem;
        color: #4a5568;
        font-weight: 500;
    }

    .form-group input,
    .form-group textarea {
        width: 100%;
        padding: 0.75rem;
        border: 2px solid #e2e8f0;
        border-radius: 6px;
        font-size: 1rem;
    }

    .form-group textarea {
        min-height: 100px;
        resize: vertical;
    }

    .modal-actions {
        display: flex;
        justify-content: flex-end;
        gap: 1rem;
        margin-top: 2rem;
    }

    .cancel-button {
        padding: 0.75rem 1.5rem;
        background: #e2e8f0;
        color: #4a5568;
        border: none;
        border-radius: 6px;
        cursor: pointer;
    }

    .submit-button {
        padding: 0.75rem 1.5rem;
        background: #4299e1;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
    }

    .setup-shop {
        text-align: center;
        padding: 2rem;
    }

    .setup-shop h3 {
        font-size: 1.5rem;
        color: #2d3748;
        margin-bottom: 1rem;
    }

    .setup-shop p {
        color: #4a5568;
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
</style> 