<script lang="ts">
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { toast } from '$lib/toast';
    import { goto } from '$app/navigation';
    import Pagination from '$lib/components/Pagination.svelte';
    import SearchBar from '$lib/components/SearchBar.svelte';

    interface Color {
        id: string;
        name: string;
        hex_code: string;
        is_deleted: boolean;
        created_at: string;
        updated_at: string;
    }

    let colors: Color[] = [];
    let loading = true;
    let showAddModal = false;
    let showEditModal = false;
    let selectedColor: Color | null = null;
    let newColor = {
        name: '',
        hex_code: ''
    };
    let error: string | null = null;
    let currentPage = 1;
    let totalPages = 1;
    let searchQuery = '';
    const itemsPerPage = 10;

    onMount(async () => {
        await fetchColors();
    });

    // Handle back button
    function handleBackButton(e: PopStateEvent) {
        if (showAddModal || showEditModal) {
            e.preventDefault();
            history.pushState(null, '', window.location.href);
            showAddModal = false;
            showEditModal = false;
            selectedColor = null;
        }
    }

    onMount(() => {
        window.addEventListener('popstate', handleBackButton);
        return () => {
            window.removeEventListener('popstate', handleBackButton);
        };
    });

    async function fetchColors() {
        try {
            loading = true;
            error = null;

            let query = supabase
                .from('colors')
                .select('*', { count: 'exact' })
                .eq('is_deleted', false);

            if (searchQuery) {
                query = query.ilike('name', `%${searchQuery}%`);
            }

            const { data, error: err, count } = await query
                .range((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage - 1)
                .order('created_at', { ascending: false });

            if (err) throw err;

            colors = data || [];
            totalPages = Math.ceil((count || 0) / itemsPerPage);
        } catch (err) {
            console.error('Error fetching colors:', err);
            error = 'Failed to load colors';
        } finally {
            loading = false;
        }
    }

    function handlePageChange(page: number) {
        currentPage = page;
        fetchColors();
    }

    function handleSearch(event: CustomEvent<{ value: string }>) {
        searchQuery = event.detail.value;
        currentPage = 1;
        fetchColors();
    }

    function validateHexCode(hex: string): boolean {
        return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(hex);
    }

    async function handleAddColor() {
        try {
            if (!newColor.name?.trim()) {
                toast.error('Color name is required');
                return;
            }

            if (!newColor.hex_code?.trim()) {
                toast.error('Hex code is required');
                return;
            }

            if (!validateHexCode(newColor.hex_code.trim())) {
                toast.error('Invalid hex code format. Please use #RRGGBB or #RGB format');
                return;
            }

            // Check if color name already exists
            const { data: existingColor, error: checkError } = await supabase
                .from('colors')
                .select('id')
                .eq('name', newColor.name.trim())
                .eq('is_deleted', false)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking color name:', checkError);
                throw checkError;
            }

            if (existingColor) {
                toast.error('A color with this name already exists');
                return;
            }

            const { error } = await supabase
                .from('colors')
                .insert([{ 
                    name: newColor.name.trim(),
                    hex_code: newColor.hex_code.trim(),
                    is_deleted: false
                }]);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Color added successfully');
            showAddModal = false;
            newColor = { name: '', hex_code: '' };
            await fetchColors();
        } catch (error) {
            console.error('Error adding color:', error);
            const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
            toast.error(`Failed to add color: ${errorMessage}`);
        }
    }

    async function handleEditColor() {
        if (!selectedColor) return;

        try {
            if (!selectedColor.name?.trim()) {
                toast.error('Color name is required');
                return;
            }

            if (!selectedColor.hex_code?.trim()) {
                toast.error('Hex code is required');
                return;
            }

            if (!validateHexCode(selectedColor.hex_code.trim())) {
                toast.error('Invalid hex code format. Please use #RRGGBB or #RGB format');
                return;
            }

            // Check if color name already exists (excluding current color)
            const { data: existingColor, error: checkError } = await supabase
                .from('colors')
                .select('id')
                .eq('name', selectedColor.name.trim())
                .eq('is_deleted', false)
                .neq('id', selectedColor.id)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking color name:', checkError);
                throw checkError;
            }

            if (existingColor) {
                toast.error('A color with this name already exists');
                return;
            }

            const { error } = await supabase
                .from('colors')
                .update({
                    name: selectedColor.name.trim(),
                    hex_code: selectedColor.hex_code.trim(),
                    updated_at: new Date().toISOString()
                })
                .eq('id', selectedColor.id);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Color updated successfully');
            showEditModal = false;
            selectedColor = null;
            await fetchColors();
        } catch (error) {
            console.error('Error updating color:', error);
            toast.error('Failed to update color');
        }
    }

    async function handleDeleteColor(colorId: string) {
        if (!confirm('Are you sure you want to delete this color?')) return;

        try {
            const { error } = await supabase
                .from('colors')
                .update({ is_deleted: true })
                .eq('id', colorId);

            if (error) throw error;

            toast.success('Color deleted successfully');
            await fetchColors();
        } catch (error) {
            console.error('Error deleting color:', error);
            toast.error('Failed to delete color');
        }
    }

    // Reset state when closing modals
    function handleCloseAddModal() {
        showAddModal = false;
        newColor = { name: '', hex_code: '' };
    }

    function handleCloseEditModal() {
        showEditModal = false;
        selectedColor = null;
    }
</script>

<div class="container mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Colors Management</h1>
        <button
            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            on:click={() => showAddModal = true}
        >
            Add New Color
        </button>
    </div>

    <div class="mb-4">
        <SearchBar placeholder="Search colors..." on:search={handleSearch} />
    </div>

    {#if loading}
        <div class="flex justify-center items-center h-64">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        </div>
    {:else if error}
        <div class="text-center py-4 text-red-600">{error}</div>
    {:else if colors.length === 0}
        <div class="text-center py-4 text-gray-500">No colors found</div>
    {:else}
        <div class="bg-white rounded-lg shadow overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Color</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Hex Code</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created At</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    {#each colors as color}
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div 
                                    class="h-8 w-8 rounded-full border border-gray-200" 
                                    style="background-color: {color.hex_code};"
                                ></div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">{color.name}</td>
                            <td class="px-6 py-4 whitespace-nowrap">{color.hex_code}</td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                {new Date(color.created_at).toLocaleDateString()}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <button
                                    class="text-blue-600 hover:text-blue-900 mr-3"
                                    on:click={() => {
                                        selectedColor = { ...color };
                                        showEditModal = true;
                                    }}
                                >
                                    Edit
                                </button>
                                <button
                                    class="text-red-600 hover:text-red-900"
                                    on:click={() => handleDeleteColor(color.id)}
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

<!-- Add Color Modal -->
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
            <h2 id="add-modal-title" class="text-xl font-bold mb-4">Add New Color</h2>
            <form on:submit|preventDefault={handleAddColor}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="name">
                        Name *
                    </label>
                    <input
                        type="text"
                        id="name"
                        bind:value={newColor.name}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    />
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="hex_code">
                        Hex Code *
                    </label>
                    <div class="flex items-center gap-2">
                        <input
                            type="text"
                            id="hex_code"
                            bind:value={newColor.hex_code}
                            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                            placeholder="#RRGGBB or #RGB"
                            required
                        />
                        <input
                            type="color"
                            class="h-10 w-10 p-1 border border-gray-300 rounded cursor-pointer"
                            value={newColor.hex_code || '#000000'}
                            on:input={(e) => {
                                newColor.hex_code = e.currentTarget.value;
                            }}
                        />
                        {#if newColor.hex_code && validateHexCode(newColor.hex_code)}
                            <div 
                                class="h-8 w-8 rounded-full border border-gray-200 flex-shrink-0" 
                                style="background-color: {newColor.hex_code};"
                            ></div>
                        {/if}
                    </div>
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
                        Add Color
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<!-- Edit Color Modal -->
{#if showEditModal && selectedColor}
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
            <h2 id="edit-modal-title" class="text-xl font-bold mb-4">Edit Color</h2>
            <form on:submit|preventDefault={handleEditColor}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-name">
                        Name *
                    </label>
                    <input
                        type="text"
                        id="edit-name"
                        bind:value={selectedColor.name}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        required
                    />
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-hex_code">
                        Hex Code *
                    </label>
                    <div class="flex items-center gap-2">
                        <input
                            type="text"
                            id="edit-hex_code"
                            bind:value={selectedColor.hex_code}
                            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                            placeholder="#RRGGBB or #RGB"
                            required
                        />
                        <input
                            type="color"
                            class="h-10 w-10 p-1 border border-gray-300 rounded cursor-pointer"
                            value={selectedColor?.hex_code || '#000000'}
                            on:input={(e) => {
                                if (selectedColor) {
                                    selectedColor.hex_code = e.currentTarget.value;
                                }
                            }}
                        />
                        {#if selectedColor.hex_code && validateHexCode(selectedColor.hex_code)}
                            <div 
                                class="h-8 w-8 rounded-full border border-gray-200 flex-shrink-0" 
                                style="background-color: {selectedColor.hex_code};"
                            ></div>
                        {/if}
                    </div>
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