<script lang="ts">
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { toast } from '$lib/toast';
    import { goto } from '$app/navigation';
    import Pagination from '$lib/components/Pagination.svelte';
    import SearchBar from '$lib/components/SearchBar.svelte';

    interface Size {
        id: string;
        label: string;
        size_type: 'alpha' | 'numeric' | 'custom';
        category: 'tops' | 'bottoms' | 'dresses' | 'shoes' | 'accessories' | 'unisex';
        numeric_value: number | null;
        display_order: number;
        description: string | null;
        is_active: boolean;
        is_deleted: boolean;
        created_at: string;
        updated_at: string;
    }

    let sizes: Size[] = [];
    let loading = true;
    let showAddModal = false;
    let showEditModal = false;
    let selectedSize: Size | null = null;
    let newSize = {
        label: '',
        size_type: 'alpha' as const,
        category: 'unisex' as const,
        numeric_value: null as number | null,
        display_order: 0,
        description: '',
        is_active: true
    };
    let error: string | null = null;
    let currentPage = 1;
    let totalPages = 1;
    let searchQuery = '';
    const itemsPerPage = 10;

    onMount(async () => {
        await fetchSizes();
    });

    // Handle back button
    function handleBackButton(e: PopStateEvent) {
        if (showAddModal || showEditModal) {
            e.preventDefault();
            history.pushState(null, '', window.location.href);
            showAddModal = false;
            showEditModal = false;
            selectedSize = null;
        }
    }

    onMount(() => {
        window.addEventListener('popstate', handleBackButton);
        return () => {
            window.removeEventListener('popstate', handleBackButton);
        };
    });

    async function fetchSizes() {
        try {
            loading = true;
            error = null;

            let query = supabase
                .from('sizes')
                .select('*', { count: 'exact' })
                .eq('is_deleted', false)
                .order('category', { ascending: true })
                .order('display_order', { ascending: true });

            if (searchQuery) {
                query = query.or(`label.ilike.%${searchQuery}%,description.ilike.%${searchQuery}%`);
            }

            const { data, error: err, count } = await query
                .range((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage - 1);

            if (err) throw err;

            sizes = data || [];
            totalPages = Math.ceil((count || 0) / itemsPerPage);
        } catch (err) {
            console.error('Error fetching sizes:', err);
            error = 'Failed to load sizes';
        } finally {
            loading = false;
        }
    }

    function handlePageChange(page: number) {
        currentPage = page;
        fetchSizes();
    }

    function handleSearch(event: CustomEvent<{ value: string }>) {
        searchQuery = event.detail.value;
        currentPage = 1;
        fetchSizes();
    }

    async function handleAddSize() {
        try {
            if (!newSize.label?.trim()) {
                toast.error('Size label is required');
                return;
            }

            // Check if size label already exists in the same category
            const { data: existingSize, error: checkError } = await supabase
                .from('sizes')
                .select('id')
                .eq('label', newSize.label.trim())
                .eq('category', newSize.category)
                .eq('is_deleted', false)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking size label:', checkError);
                throw checkError;
            }

            if (existingSize) {
                toast.error('A size with this label already exists in this category');
                return;
            }

            const { error } = await supabase
                .from('sizes')
                .insert([{ 
                    label: newSize.label.trim(),
                    size_type: newSize.size_type,
                    category: newSize.category,
                    numeric_value: newSize.numeric_value,
                    display_order: newSize.display_order,
                    description: newSize.description?.trim() || null,
                    is_active: newSize.is_active,
                    is_deleted: false
                }]);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Size added successfully');
            showAddModal = false;
            newSize = {
                label: '',
                size_type: 'alpha',
                category: 'unisex',
                numeric_value: null,
                display_order: 0,
                description: '',
                is_active: true
            };
            await fetchSizes();
        } catch (error) {
            console.error('Error adding size:', error);
            const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
            toast.error(`Failed to add size: ${errorMessage}`);
        }
    }

    async function handleEditSize() {
        if (!selectedSize) return;

        try {
            if (!selectedSize.label?.trim()) {
                toast.error('Size label is required');
                return;
            }

            // Check if size label already exists in the same category (excluding current size)
            const { data: existingSize, error: checkError } = await supabase
                .from('sizes')
                .select('id')
                .eq('label', selectedSize.label.trim())
                .eq('category', selectedSize.category)
                .eq('is_deleted', false)
                .neq('id', selectedSize.id)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking size label:', checkError);
                throw checkError;
            }

            if (existingSize) {
                toast.error('A size with this label already exists in this category');
                return;
            }

            const { error } = await supabase
                .from('sizes')
                .update({
                    label: selectedSize.label.trim(),
                    size_type: selectedSize.size_type,
                    category: selectedSize.category,
                    numeric_value: selectedSize.numeric_value,
                    display_order: selectedSize.display_order,
                    description: selectedSize.description?.trim() || null,
                    is_active: selectedSize.is_active,
                    updated_at: new Date().toISOString()
                })
                .eq('id', selectedSize.id);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Size updated successfully');
            showEditModal = false;
            selectedSize = null;
            await fetchSizes();
        } catch (error) {
            console.error('Error updating size:', error);
            toast.error('Failed to update size');
        }
    }

    async function handleDeleteSize(sizeId: string) {
        if (!confirm('Are you sure you want to delete this size?')) return;

        try {
            const { error } = await supabase
                .from('sizes')
                .update({ is_deleted: true })
                .eq('id', sizeId);

            if (error) throw error;

            toast.success('Size deleted successfully');
            await fetchSizes();
        } catch (error) {
            console.error('Error deleting size:', error);
            toast.error('Failed to delete size');
        }
    }

    // Reset state when closing modals
    function handleCloseAddModal() {
        showAddModal = false;
        newSize = {
            label: '',
            size_type: 'alpha',
            category: 'unisex',
            numeric_value: null,
            display_order: 0,
            description: '',
            is_active: true
        };
    }

    function handleCloseEditModal() {
        showEditModal = false;
        selectedSize = null;
    }
</script>

<div class="container mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Sizes Management</h1>
        <button
            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            on:click={() => showAddModal = true}
        >
            Add New Size
        </button>
    </div>

    <div class="mb-4">
        <SearchBar placeholder="Search sizes..." on:search={handleSearch} />
    </div>

    {#if loading}
        <div class="flex justify-center items-center h-64">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        </div>
    {:else if error}
        <div class="text-center py-4 text-red-600">{error}</div>
    {:else if sizes.length === 0}
        <div class="text-center py-4 text-gray-500">No sizes found</div>
    {:else}
        <div class="bg-white rounded-lg shadow overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Label</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created At</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    {#each sizes as size}
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap capitalize">{size.category}</td>
                            <td class="px-6 py-4 whitespace-nowrap">{size.label}</td>
                            <td class="px-6 py-4 whitespace-nowrap capitalize">{size.size_type}</td>
                            <td class="px-6 py-4 whitespace-nowrap">{size.description || '-'}</td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${size.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                                    {size.is_active ? 'Active' : 'Inactive'}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                {new Date(size.created_at).toLocaleDateString()}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <button
                                    class="text-blue-600 hover:text-blue-900 mr-3"
                                    on:click={() => {
                                        selectedSize = { ...size };
                                        showEditModal = true;
                                    }}
                                >
                                    Edit
                                </button>
                                <button
                                    class="text-red-600 hover:text-red-900"
                                    on:click={() => handleDeleteSize(size.id)}
                                >
                                    Delete
                                </button>
                            </td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>

        <div class="mt-4">
            <Pagination
                {currentPage}
                {totalPages}
                onPageChange={handlePageChange}
            />
        </div>
    {/if}
</div>

<!-- Add Size Modal -->
{#if showAddModal}
    <div 
        class="modal-overlay" 
        on:click={handleCloseAddModal}
        role="dialog"
        aria-modal="true"
        aria-labelledby="add-modal-title"
    >
        <div 
            id="add-modal" 
            class="modal-content" 
            on:click|stopPropagation
            role="document"
        >
            <h2 id="add-modal-title" class="text-xl font-bold mb-4">Add New Size</h2>
            <form on:submit|preventDefault={handleAddSize}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="category">
                        Category *
                    </label>
                    <select
                        id="category"
                        bind:value={newSize.category}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    >
                        <option value="tops">Tops</option>
                        <option value="bottoms">Bottoms</option>
                        <option value="dresses">Dresses</option>
                        <option value="shoes">Shoes</option>
                        <option value="accessories">Accessories</option>
                        <option value="unisex">Unisex</option>
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="size_type">
                        Size Type *
                    </label>
                    <select
                        id="size_type"
                        bind:value={newSize.size_type}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    >
                        <option value="alpha">Alpha (S, M, L, etc.)</option>
                        <option value="numeric">Numeric (28, 29, 30, etc.)</option>
                        <option value="custom">Custom</option>
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="label">
                        Label *
                    </label>
                    <input
                        type="text"
                        id="label"
                        bind:value={newSize.label}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    />
                </div>

                {#if newSize.size_type === 'numeric'}
                    <div class="mb-4">
                        <label class="block text-gray-700 text-sm font-bold mb-2" for="numeric_value">
                            Numeric Value *
                        </label>
                        <input
                            type="number"
                            id="numeric_value"
                            bind:value={newSize.numeric_value}
                            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                            required
                        />
                    </div>
                {/if}

                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="display_order">
                        Display Order *
                    </label>
                    <input
                        type="number"
                        id="display_order"
                        bind:value={newSize.display_order}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    />
                </div>

                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="description">
                        Description
                    </label>
                    <textarea
                        id="description"
                        bind:value={newSize.description}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        rows="3"
                    ></textarea>
                </div>

                <div class="mb-4">
                    <label class="flex items-center">
                        <input
                            type="checkbox"
                            bind:checked={newSize.is_active}
                            class="form-checkbox h-4 w-4 text-blue-600"
                        />
                        <span class="ml-2 text-gray-700">Active</span>
                    </label>
                </div>

                <div class="flex justify-end gap-2">
                    <button
                        type="button"
                        class="bg-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-400"
                        on:click={handleCloseAddModal}
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
                    >
                        Add Size
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<!-- Edit Size Modal -->
{#if showEditModal && selectedSize}
    <div 
        class="modal-overlay" 
        on:click={handleCloseEditModal}
        role="dialog"
        aria-modal="true"
        aria-labelledby="edit-modal-title"
    >
        <div 
            id="edit-modal" 
            class="modal-content" 
            on:click|stopPropagation
            role="document"
        >
            <h2 id="edit-modal-title" class="text-xl font-bold mb-4">Edit Size</h2>
            <form on:submit|preventDefault={handleEditSize}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-category">
                        Category *
                    </label>
                    <select
                        id="edit-category"
                        bind:value={selectedSize.category}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    >
                        <option value="tops">Tops</option>
                        <option value="bottoms">Bottoms</option>
                        <option value="dresses">Dresses</option>
                        <option value="shoes">Shoes</option>
                        <option value="accessories">Accessories</option>
                        <option value="unisex">Unisex</option>
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-size_type">
                        Size Type *
                    </label>
                    <select
                        id="edit-size_type"
                        bind:value={selectedSize.size_type}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    >
                        <option value="alpha">Alpha (S, M, L, etc.)</option>
                        <option value="numeric">Numeric (28, 29, 30, etc.)</option>
                        <option value="custom">Custom</option>
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-label">
                        Label *
                    </label>
                    <input
                        type="text"
                        id="edit-label"
                        bind:value={selectedSize.label}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    />
                </div>

                {#if selectedSize.size_type === 'numeric'}
                    <div class="mb-4">
                        <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-numeric_value">
                            Numeric Value *
                        </label>
                        <input
                            type="number"
                            id="edit-numeric_value"
                            bind:value={selectedSize.numeric_value}
                            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                            required
                        />
                    </div>
                {/if}

                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-display_order">
                        Display Order *
                    </label>
                    <input
                        type="number"
                        id="edit-display_order"
                        bind:value={selectedSize.display_order}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    />
                </div>

                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-description">
                        Description
                    </label>
                    <textarea
                        id="edit-description"
                        bind:value={selectedSize.description}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        rows="3"
                    ></textarea>
                </div>

                <div class="mb-4">
                    <label class="flex items-center">
                        <input
                            type="checkbox"
                            bind:checked={selectedSize.is_active}
                            class="form-checkbox h-4 w-4 text-blue-600"
                        />
                        <span class="ml-2 text-gray-700">Active</span>
                    </label>
                </div>

                <div class="flex justify-end gap-2">
                    <button
                        type="button"
                        class="bg-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-400"
                        on:click={handleCloseEditModal}
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
                    >
                        Save Changes
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<style>
    .modal-overlay {
        position: fixed;
        inset: 0;
        background-color: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 50;
    }

    .modal-content {
        background: white;
        border-radius: 0.5rem;
        padding: 1.5rem;
        width: 100%;
        max-width: 28rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    }
</style> 