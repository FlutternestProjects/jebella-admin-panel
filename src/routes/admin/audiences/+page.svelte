<script lang="ts">
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { toast } from '$lib/toast';
    import { goto } from '$app/navigation';
    import Pagination from '$lib/components/Pagination.svelte';
    import SearchBar from '$lib/components/SearchBar.svelte';

    interface Audience {
        id: string;
        name: string;
        is_deleted: boolean;
        created_at: string;
        updated_at: string;
    }

    let audiences: Audience[] = [];
    let loading = true;
    let showAddModal = false;
    let showEditModal = false;
    let selectedAudience: Audience | null = null;
    let newAudience = {
        name: ''
    };
    let error: string | null = null;
    let currentPage = 1;
    let totalPages = 1;
    let searchQuery = '';
    const itemsPerPage = 10;

    onMount(async () => {
        await fetchAudiences();
    });

    // Handle back button
    function handleBackButton(e: PopStateEvent) {
        if (showAddModal || showEditModal) {
            e.preventDefault();
            history.pushState(null, '', window.location.href);
            showAddModal = false;
            showEditModal = false;
            selectedAudience = null;
        }
    }

    onMount(() => {
        window.addEventListener('popstate', handleBackButton);
        return () => {
            window.removeEventListener('popstate', handleBackButton);
        };
    });

    async function fetchAudiences() {
        try {
            loading = true;
            error = null;

            let query = supabase
                .from('audiences')
                .select('*', { count: 'exact' })
                .eq('is_deleted', false);

            if (searchQuery) {
                query = query.ilike('name', `%${searchQuery}%`);
            }

            const { data, error: err, count } = await query
                .range((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage - 1)
                .order('created_at', { ascending: false });

            if (err) throw err;

            audiences = data || [];
            totalPages = Math.ceil((count || 0) / itemsPerPage);
        } catch (err) {
            console.error('Error fetching audiences:', err);
            error = 'Failed to load audiences';
        } finally {
            loading = false;
        }
    }

    function handlePageChange(page: number) {
        currentPage = page;
        fetchAudiences();
    }

    function handleSearch(event: CustomEvent<{ value: string }>) {
        searchQuery = event.detail.value;
        currentPage = 1;
        fetchAudiences();
    }

    async function handleAddAudience() {
        try {
            if (!newAudience.name?.trim()) {
                toast.error('Audience name is required');
                return;
            }

            // Check if audience name already exists
            const { data: existingAudience, error: checkError } = await supabase
                .from('audiences')
                .select('id')
                .eq('name', newAudience.name.trim())
                .eq('is_deleted', false)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking audience name:', checkError);
                throw checkError;
            }

            if (existingAudience) {
                toast.error('An audience with this name already exists');
                return;
            }

            const { error } = await supabase
                .from('audiences')
                .insert([{ 
                    name: newAudience.name.trim(),
                    is_deleted: false
                }]);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Audience added successfully');
            showAddModal = false;
            newAudience = { name: '' };
            await fetchAudiences();
        } catch (error) {
            console.error('Error adding audience:', error);
            const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
            toast.error(`Failed to add audience: ${errorMessage}`);
        }
    }

    async function handleEditAudience() {
        if (!selectedAudience) return;

        try {
            if (!selectedAudience.name?.trim()) {
                toast.error('Audience name is required');
                return;
            }

            // Check if audience name already exists (excluding current audience)
            const { data: existingAudience, error: checkError } = await supabase
                .from('audiences')
                .select('id')
                .eq('name', selectedAudience.name.trim())
                .eq('is_deleted', false)
                .neq('id', selectedAudience.id)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking audience name:', checkError);
                throw checkError;
            }

            if (existingAudience) {
                toast.error('An audience with this name already exists');
                return;
            }

            const { error } = await supabase
                .from('audiences')
                .update({
                    name: selectedAudience.name.trim(),
                    updated_at: new Date().toISOString()
                })
                .eq('id', selectedAudience.id);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Audience updated successfully');
            showEditModal = false;
            selectedAudience = null;
            await fetchAudiences();
        } catch (error) {
            console.error('Error updating audience:', error);
            toast.error('Failed to update audience');
        }
    }

    async function handleDeleteAudience(audienceId: string) {
        if (!confirm('Are you sure you want to delete this audience?')) return;

        try {
            const { error } = await supabase
                .from('audiences')
                .update({ is_deleted: true })
                .eq('id', audienceId);

            if (error) throw error;

            toast.success('Audience deleted successfully');
            await fetchAudiences();
        } catch (error) {
            console.error('Error deleting audience:', error);
            toast.error('Failed to delete audience');
        }
    }

    // Reset state when closing modals
    function handleCloseAddModal() {
        showAddModal = false;
        newAudience = { name: '' };
    }

    function handleCloseEditModal() {
        showEditModal = false;
        selectedAudience = null;
    }
</script>

<div class="container mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Audiences Management</h1>
        <button
            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            on:click={() => showAddModal = true}
        >
            Add New Audience
        </button>
    </div>

    <div class="mb-4">
        <SearchBar placeholder="Search audiences..." on:search={handleSearch} />
    </div>

    {#if loading}
        <div class="flex justify-center items-center h-64">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        </div>
    {:else if error}
        <div class="text-center py-4 text-red-600">{error}</div>
    {:else if audiences.length === 0}
        <div class="text-center py-4 text-gray-500">No audiences found</div>
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
                    {#each audiences as audience}
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap">{audience.name}</td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                {new Date(audience.created_at).toLocaleDateString()}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <button
                                    class="text-blue-600 hover:text-blue-900 mr-3"
                                    on:click={() => {
                                        selectedAudience = { ...audience };
                                        showEditModal = true;
                                    }}
                                >
                                    Edit
                                </button>
                                <button
                                    class="text-red-600 hover:text-red-900"
                                    on:click={() => handleDeleteAudience(audience.id)}
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

<!-- Add Audience Modal -->
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
            <h2 id="add-modal-title" class="text-xl font-bold mb-4">Add New Audience</h2>
            <form on:submit|preventDefault={handleAddAudience}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="name">
                        Name *
                    </label>
                    <input
                        type="text"
                        id="name"
                        bind:value={newAudience.name}
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
                        Add Audience
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<!-- Edit Audience Modal -->
{#if showEditModal && selectedAudience}
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
            <h2 id="edit-modal-title" class="text-xl font-bold mb-4">Edit Audience</h2>
            <form on:submit|preventDefault={handleEditAudience}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-name">
                        Name *
                    </label>
                    <input
                        type="text"
                        id="edit-name"
                        bind:value={selectedAudience.name}
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