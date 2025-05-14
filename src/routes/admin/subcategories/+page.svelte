<script lang="ts">
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { toast } from '$lib/toast';
    import { goto } from '$app/navigation';
    import Pagination from '$lib/components/Pagination.svelte';
    import SearchBar from '$lib/components/SearchBar.svelte';

    interface Category {
        id: string;
        name: string;
    }

    interface Subcategory {
        id: string;
        name: string;
        category_id: string;
        created_at: string;
        updated_at: string;
        is_deleted: boolean;
        category?: {
            name: string;
        };
    }

    let categories: Category[] = [];
    let subcategories: Subcategory[] = [];
    let loading = true;
    let showAddModal = false;
    let showEditModal = false;
    let selectedSubcategory: Subcategory | null = null;
    let newSubcategory = {
        name: '',
        category_id: ''
    };
    let error: string | null = null;
    let currentPage = 1;
    let totalPages = 1;
    let searchQuery = '';
    const itemsPerPage = 10;

    onMount(async () => {
        await Promise.all([loadCategories(), loadSubcategories()]);
    });

    // Handle back button
    function handleBackButton(e: PopStateEvent) {
        if (showAddModal || showEditModal) {
            e.preventDefault();
            history.pushState(null, '', window.location.href);
            showAddModal = false;
            showEditModal = false;
            selectedSubcategory = null;
        }
    }

    onMount(() => {
        window.addEventListener('popstate', handleBackButton);
        return () => {
            window.removeEventListener('popstate', handleBackButton);
        };
    });

    async function loadCategories() {
        try {
            const { data, error } = await supabase
                .from('categories')
                .select('id, name')
                .eq('is_deleted', false)
                .order('name');

            if (error) throw error;
            categories = data;
        } catch (error) {
            console.error('Error loading categories:', error);
            toast.error('Failed to load categories');
        }
    }

    async function loadSubcategories() {
        try {
            loading = true;
            error = null;

            let query = supabase
                .from('subcategories')
                .select(`
                    *,
                    category:categories(name)
                `, { count: 'exact' })
                .eq('is_deleted', false);

            if (searchQuery) {
                query = query.ilike('name', `%${searchQuery}%`);
            }

            const { data, error: err, count } = await query
                .range((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage - 1)
                .order('created_at', { ascending: false });

            if (err) throw err;

            subcategories = data || [];
            totalPages = Math.ceil((count || 0) / itemsPerPage);
        } catch (err) {
            console.error('Error fetching subcategories:', err);
            error = 'Failed to load subcategories';
        } finally {
            loading = false;
        }
    }

    function handlePageChange(page: number) {
        currentPage = page;
        loadSubcategories();
    }

    function handleSearch(event: CustomEvent<{ value: string }>) {
        searchQuery = event.detail.value;
        currentPage = 1;
        loadSubcategories();
    }

    async function handleAddSubcategory() {
        try {
            if (!newSubcategory.name?.trim()) {
                toast.error('Subcategory name is required');
                return;
            }

            if (!newSubcategory.category_id) {
                toast.error('Please select a category');
                return;
            }

            // Check if subcategory name already exists in the same category
            const { data: existingSubcategory, error: checkError } = await supabase
                .from('subcategories')
                .select('id')
                .eq('name', newSubcategory.name.trim())
                .eq('category_id', newSubcategory.category_id)
                .eq('is_deleted', false)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking subcategory name:', checkError);
                throw checkError;
            }

            if (existingSubcategory) {
                toast.error('A subcategory with this name already exists in the selected category');
                return;
            }

            const { error } = await supabase
                .from('subcategories')
                .insert([{ 
                    name: newSubcategory.name.trim(),
                    category_id: newSubcategory.category_id,
                    is_deleted: false
                }]);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Subcategory added successfully');
            showAddModal = false;
            newSubcategory = { name: '', category_id: '' };
            await loadSubcategories();
        } catch (error) {
            console.error('Error adding subcategory:', error);
            const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
            toast.error(`Failed to add subcategory: ${errorMessage}`);
        }
    }

    async function handleEditSubcategory() {
        if (!selectedSubcategory) return;

        try {
            if (!selectedSubcategory.name?.trim()) {
                toast.error('Subcategory name is required');
                return;
            }

            if (!selectedSubcategory.category_id) {
                toast.error('Please select a category');
                return;
            }

            // Check if subcategory name already exists in the same category (excluding current subcategory)
            const { data: existingSubcategory, error: checkError } = await supabase
                .from('subcategories')
                .select('id')
                .eq('name', selectedSubcategory.name.trim())
                .eq('category_id', selectedSubcategory.category_id)
                .eq('is_deleted', false)
                .neq('id', selectedSubcategory.id)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking subcategory name:', checkError);
                throw checkError;
            }

            if (existingSubcategory) {
                toast.error('A subcategory with this name already exists in the selected category');
                return;
            }

            const { error } = await supabase
                .from('subcategories')
                .update({
                    name: selectedSubcategory.name.trim(),
                    category_id: selectedSubcategory.category_id,
                    updated_at: new Date().toISOString()
                })
                .eq('id', selectedSubcategory.id);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Subcategory updated successfully');
            showEditModal = false;
            selectedSubcategory = null;
            await loadSubcategories();
        } catch (error) {
            console.error('Error updating subcategory:', error);
            toast.error('Failed to update subcategory');
        }
    }

    async function handleDeleteSubcategory(subcategoryId: string) {
        if (!confirm('Are you sure you want to delete this subcategory?')) return;

        try {
            const { error } = await supabase
                .from('subcategories')
                .update({ is_deleted: true })
                .eq('id', subcategoryId);

            if (error) throw error;

            toast.success('Subcategory deleted successfully');
            await loadSubcategories();
        } catch (error) {
            console.error('Error deleting subcategory:', error);
            toast.error('Failed to delete subcategory');
        }
    }

    // Reset state when closing modals
    function handleCloseAddModal() {
        showAddModal = false;
        newSubcategory = { name: '', category_id: '' };
    }

    function handleCloseEditModal() {
        showEditModal = false;
        selectedSubcategory = null;
    }
</script>

<div class="container mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Subcategories Management</h1>
        <button
            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            on:click={() => showAddModal = true}
        >
            Add New Subcategory
        </button>
    </div>

    <div class="mb-4">
        <SearchBar placeholder="Search subcategories..." on:search={handleSearch} />
    </div>

    {#if loading}
        <div class="flex justify-center items-center h-64">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        </div>
    {:else if error}
        <div class="text-center py-4 text-red-600">{error}</div>
    {:else if subcategories.length === 0}
        <div class="text-center py-4 text-gray-500">No subcategories found</div>
    {:else}
        <div class="bg-white rounded-lg shadow overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created At</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    {#each subcategories as subcategory}
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap">{subcategory.name}</td>
                            <td class="px-6 py-4 whitespace-nowrap">{subcategory.category?.name}</td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                {new Date(subcategory.created_at).toLocaleDateString()}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <button
                                    class="text-blue-600 hover:text-blue-900 mr-3"
                                    on:click={() => {
                                        selectedSubcategory = { ...subcategory };
                                        showEditModal = true;
                                    }}
                                >
                                    Edit
                                </button>
                                <button
                                    class="text-red-600 hover:text-red-900"
                                    on:click={() => handleDeleteSubcategory(subcategory.id)}
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

<!-- Add Subcategory Modal -->
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
            <h2 id="add-modal-title" class="text-xl font-bold mb-4">Add New Subcategory</h2>
            <form on:submit|preventDefault={handleAddSubcategory}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="name">
                        Name *
                    </label>
                    <input
                        type="text"
                        id="name"
                        bind:value={newSubcategory.name}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    />
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="category">
                        Category *
                    </label>
                    <select
                        id="category"
                        bind:value={newSubcategory.category_id}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    >
                        <option value="">Select a category</option>
                        {#each categories as category}
                            <option value={category.id}>{category.name}</option>
                        {/each}
                    </select>
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
                        Add Subcategory
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<!-- Edit Subcategory Modal -->
{#if showEditModal && selectedSubcategory}
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
            <h2 id="edit-modal-title" class="text-xl font-bold mb-4">Edit Subcategory</h2>
            <form on:submit|preventDefault={handleEditSubcategory}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-name">
                        Name *
                    </label>
                    <input
                        type="text"
                        id="edit-name"
                        bind:value={selectedSubcategory.name}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    />
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-category">
                        Category *
                    </label>
                    <select
                        id="edit-category"
                        bind:value={selectedSubcategory.category_id}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    >
                        <option value="">Select a category</option>
                        {#each categories as category}
                            <option value={category.id}>{category.name}</option>
                        {/each}
                    </select>
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