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
        is_deleted: boolean;
        created_at: string;
        updated_at: string;
    }

    let categories: Category[] = [];
    let loading = true;
    let showAddModal = false;
    let showEditModal = false;
    let selectedCategory: Category | null = null;
    let newCategory = {
        name: ''
    };
    let error: string | null = null;
    let currentPage = 1;
    let totalPages = 1;
    let searchQuery = '';
    const itemsPerPage = 10;

    onMount(async () => {
        await fetchCategories();
    });

    // Handle back button
    function handleBackButton(e: PopStateEvent) {
        if (showAddModal || showEditModal) {
            e.preventDefault();
            history.pushState(null, '', window.location.href);
            showAddModal = false;
            showEditModal = false;
            selectedCategory = null;
        }
    }

    onMount(() => {
        window.addEventListener('popstate', handleBackButton);
        return () => {
            window.removeEventListener('popstate', handleBackButton);
        };
    });

    async function fetchCategories() {
        try {
            loading = true;
            error = null;

            let query = supabase
                .from('categories')
                .select('*', { count: 'exact' })
                .eq('is_deleted', false);

            if (searchQuery) {
                query = query.ilike('name', `%${searchQuery}%`);
            }

            const { data, error: err, count } = await query
                .range((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage - 1)
                .order('created_at', { ascending: false });

            if (err) throw err;

            categories = data || [];
            totalPages = Math.ceil((count || 0) / itemsPerPage);
        } catch (err) {
            console.error('Error fetching categories:', err);
            error = 'Failed to load categories';
        } finally {
            loading = false;
        }
    }

    function handlePageChange(page: number) {
        currentPage = page;
        fetchCategories();
    }

    function handleSearch(event: CustomEvent<{ value: string }>) {
        searchQuery = event.detail.value;
        currentPage = 1;
        fetchCategories();
    }

    async function handleAddCategory() {
        try {
            if (!newCategory.name?.trim()) {
                toast.error('Category name is required');
                return;
            }

            // Check if category name already exists
            const { data: existingCategory, error: checkError } = await supabase
                .from('categories')
                .select('id')
                .eq('name', newCategory.name.trim())
                .eq('is_deleted', false)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking category name:', checkError);
                throw checkError;
            }

            if (existingCategory) {
                toast.error('A category with this name already exists');
                return;
            }

            const { error } = await supabase
                .from('categories')
                .insert([{ 
                    name: newCategory.name.trim(),
                    is_deleted: false
                }]);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Category added successfully');
            showAddModal = false;
            newCategory = { name: '' };
            await fetchCategories();
        } catch (error) {
            console.error('Error adding category:', error);
            const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
            toast.error(`Failed to add category: ${errorMessage}`);
        }
    }

    async function handleEditCategory() {
        if (!selectedCategory) return;

        try {
            if (!selectedCategory.name?.trim()) {
                toast.error('Category name is required');
                return;
            }

            // Check if category name already exists (excluding current category)
            const { data: existingCategory, error: checkError } = await supabase
                .from('categories')
                .select('id')
                .eq('name', selectedCategory.name.trim())
                .eq('is_deleted', false)
                .neq('id', selectedCategory.id)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking category name:', checkError);
                throw checkError;
            }

            if (existingCategory) {
                toast.error('A category with this name already exists');
                return;
            }

            const { error } = await supabase
                .from('categories')
                .update({
                    name: selectedCategory.name.trim(),
                    updated_at: new Date().toISOString()
                })
                .eq('id', selectedCategory.id);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Category updated successfully');
            showEditModal = false;
            selectedCategory = null;
            await fetchCategories();
        } catch (error) {
            console.error('Error updating category:', error);
            toast.error('Failed to update category');
        }
    }

    async function handleDeleteCategory(categoryId: string) {
        if (!confirm('Are you sure you want to delete this category?')) return;

        try {
            const { error } = await supabase
                .from('categories')
                .update({ is_deleted: true })
                .eq('id', categoryId);

            if (error) throw error;

            toast.success('Category deleted successfully');
            await fetchCategories();
        } catch (error) {
            console.error('Error deleting category:', error);
            toast.error('Failed to delete category');
        }
    }

    // Reset state when closing modals
    function handleCloseAddModal() {
        showAddModal = false;
        newCategory = { name: '' };
    }

    function handleCloseEditModal() {
        showEditModal = false;
        selectedCategory = null;
    }
</script>

<div class="container mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Categories Management</h1>
        <button
            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            on:click={() => showAddModal = true}
        >
            Add New Category
        </button>
    </div>

    <div class="mb-4">
        <SearchBar placeholder="Search categories..." on:search={handleSearch} />
    </div>

    {#if loading}
        <div class="flex justify-center items-center h-64">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        </div>
    {:else if error}
        <div class="text-center py-4 text-red-600">{error}</div>
    {:else if categories.length === 0}
        <div class="text-center py-4 text-gray-500">No categories found</div>
    {:else}
        <div class="bg-white rounded-lg shadow overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created At</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    {#each categories as category}
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap">{category.name}</td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                {new Date(category.created_at).toLocaleDateString()}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <button
                                    class="text-blue-600 hover:text-blue-900 mr-3"
                                    on:click={() => {
                                        selectedCategory = { ...category };
                                        showEditModal = true;
                                    }}
                                >
                                    Edit
                                </button>
                                <button
                                    class="text-red-600 hover:text-red-900"
                                    on:click={() => handleDeleteCategory(category.id)}
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

<!-- Add Category Modal -->
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
            <h2 id="add-modal-title" class="text-xl font-bold mb-4">Add New Category</h2>
            <form on:submit|preventDefault={handleAddCategory}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="name">
                        Name *
                    </label>
                    <input
                        type="text"
                        id="name"
                        bind:value={newCategory.name}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    />
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
                        Add Category
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<!-- Edit Category Modal -->
{#if showEditModal && selectedCategory}
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
            <h2 id="edit-modal-title" class="text-xl font-bold mb-4">Edit Category</h2>
            <form on:submit|preventDefault={handleEditCategory}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-name">
                        Name *
                    </label>
                    <input
                        type="text"
                        id="edit-name"
                        bind:value={selectedCategory.name}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    />
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