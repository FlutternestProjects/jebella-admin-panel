<script lang="ts">
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import type { Brand } from '$lib/types';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';
    import { toast } from '$lib/toast';
    import ImageUpload from '$lib/components/ImageUpload.svelte';

    let brands: Brand[] = [];
    let loading = true;
    let showAddModal = false;
    let showEditModal = false;
    let selectedBrand: Brand | null = null;
    let newBrand = {
        name: '',
        description: '',
        logo_url: ''
    };
    let uploadingLogo = false;
    let selectedFile: File | null = null;
    let selectedEditFile: File | null = null;
    let addImageUpload: ImageUpload;
    let editImageUpload: ImageUpload;
    let previewUrl: string | null = null;
    let editPreviewUrl: string | null = null;

    onMount(async () => {
        await loadBrands();
    });

    // Handle back button
    function handleBackButton(e: PopStateEvent) {
        if (showAddModal || showEditModal) {
            e.preventDefault();
            history.pushState(null, '', window.location.href);
            showAddModal = false;
            showEditModal = false;
            selectedBrand = null;
        }
    }

    onMount(() => {
        window.addEventListener('popstate', handleBackButton);
        return () => {
            window.removeEventListener('popstate', handleBackButton);
        };
    });

    async function loadBrands() {
        try {
            loading = true;
            const { data, error } = await supabase
                .from('brands')
                .select('*')
                .eq('is_deleted', false)
                .order('created_at', { ascending: false });

            if (error) throw error;
            brands = data;
        } catch (error) {
            console.error('Error loading brands:', error);
            toast.error('Failed to load brands');
        } finally {
            loading = false;
        }
    }

    function handleFileSelect(event: CustomEvent<{ file: File }>) {
        const file = event.detail.file;
        const target = event.target as HTMLElement;
        const isAddModal = target.closest('#add-modal') !== null;

        if (isAddModal) {
            selectedFile = file;
        } else {
            selectedEditFile = file;
        }
    }

    function handleRemoveImage(event: CustomEvent<void>) {
        const target = event.target as HTMLElement;
        const isAddModal = target.closest('#add-modal') !== null;

        if (isAddModal) {
            selectedFile = null;
        } else {
            selectedEditFile = null;
        }
    }

    function handleUploadError(event: CustomEvent<{ message: string }>) {
        toast.error(event.detail.message);
    }

    async function uploadLogo(file: File): Promise<string | null> {
        try {
            uploadingLogo = true;
            const fileExt = file.name.split('.').pop();
            const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`;
            const filePath = `${fileName}`;

            // Upload file to Supabase storage
            const { error: uploadError, data } = await supabase.storage
                .from('brand-logos')
                .upload(filePath, file, {
                    cacheControl: '3600',
                    upsert: false
                });

            if (uploadError) {
                console.error('Upload error:', uploadError);
                throw uploadError;
            }

            // Get the public URL
            const { data: { publicUrl } } = supabase.storage
                .from('brand-logos')
                .getPublicUrl(filePath);

            return publicUrl;
        } catch (error) {
            console.error('Error uploading logo:', error);
            toast.error('Failed to upload logo');
            return null;
        } finally {
            uploadingLogo = false;
        }
    }

    async function handleAddBrand() {
        try {
            let logoUrl = newBrand.logo_url;

            if (selectedFile) {
                const uploadedUrl = await uploadLogo(selectedFile);
                if (!uploadedUrl) {
                    toast.error('Failed to upload logo');
                    return;
                }
                logoUrl = uploadedUrl;
            }

            const { error } = await supabase
                .from('brands')
                .insert([{ 
                    name: newBrand.name,
                    description: newBrand.description,
                    logo_url: logoUrl,
                    is_deleted: false
                }]);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Brand added successfully');
            showAddModal = false;
            newBrand = { name: '', description: '', logo_url: '' };
            selectedFile = null;
            await loadBrands();
        } catch (error) {
            console.error('Error adding brand:', error);
            toast.error('Failed to add brand');
        }
    }

    async function handleEditBrand() {
        if (!selectedBrand) return;

        try {
            let logoUrl = selectedBrand.logo_url;

            if (selectedEditFile) {
                const uploadedUrl = await uploadLogo(selectedEditFile);
                if (!uploadedUrl) {
                    toast.error('Failed to upload logo');
                    return;
                }
                logoUrl = uploadedUrl;
            }

            const { error } = await supabase
                .from('brands')
                .update({
                    name: selectedBrand.name,
                    description: selectedBrand.description,
                    logo_url: logoUrl,
                    updated_at: new Date().toISOString()
                })
                .eq('id', selectedBrand.id);

            if (error) {
                console.error('Database error:', error);
                throw error;
            }

            toast.success('Brand updated successfully');
            showEditModal = false;
            selectedBrand = null;
            selectedEditFile = null;
            await loadBrands();
        } catch (error) {
            console.error('Error updating brand:', error);
            toast.error('Failed to update brand');
        }
    }

    async function handleDeleteBrand(brandId: string) {
        if (!confirm('Are you sure you want to delete this brand?')) return;

        try {
            const { error } = await supabase
                .from('brands')
                .update({ is_deleted: true })
                .eq('id', brandId);

            if (error) throw error;

            toast.success('Brand deleted successfully');
            await loadBrands();
        } catch (error) {
            console.error('Error deleting brand:', error);
            toast.error('Failed to delete brand');
        }
    }

    // Cleanup preview URLs when component is destroyed
    onMount(() => {
        return () => {
            if (previewUrl) URL.revokeObjectURL(previewUrl);
            if (editPreviewUrl) URL.revokeObjectURL(editPreviewUrl);
        };
    });
</script>

<div class="container mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Brands Management</h1>
        <button
            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            on:click={() => showAddModal = true}
        >
            Add New Brand
        </button>
    </div>

    {#if loading}
        <div class="flex justify-center items-center h-64">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        </div>
    {:else}
        <div class="bg-white rounded-lg shadow overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Logo</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    {#each brands as brand}
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap">
                                {#if brand.logo_url}
                                    <img src={brand.logo_url} alt={brand.name} class="h-10 w-10 object-contain" />
                                {:else}
                                    <div class="h-10 w-10 bg-gray-200 rounded flex items-center justify-center">
                                        <span class="text-gray-500">No logo</span>
                                    </div>
                                {/if}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">{brand.name}</td>
                            <td class="px-6 py-4">{brand.description || '-'}</td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <button
                                    class="text-blue-600 hover:text-blue-900 mr-3"
                                    on:click={() => {
                                        selectedBrand = { ...brand };
                                        showEditModal = true;
                                    }}
                                >
                                    Edit
                                </button>
                                <button
                                    class="text-red-600 hover:text-red-900"
                                    on:click={() => handleDeleteBrand(brand.id)}
                                >
                                    Delete
                                </button>
                            </td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
    {/if}
</div>

<!-- Add Brand Modal -->
{#if showAddModal}
    <div 
        class="modal-overlay" 
        on:click={() => showAddModal = false}
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
            <h2 id="add-modal-title" class="text-xl font-bold mb-4">Add New Brand</h2>
            <form on:submit|preventDefault={handleAddBrand}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="name">
                        Name
                    </label>
                    <input
                        type="text"
                        id="name"
                        bind:value={newBrand.name}
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
                        bind:value={newBrand.description}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        rows="3"
                    ></textarea>
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="brand-logo">
                        Brand Logo
                    </label>
                    <ImageUpload
                        bind:this={addImageUpload}
                        currentImageUrl={newBrand.logo_url}
                        on:fileSelect={handleFileSelect}
                        on:error={handleUploadError}
                        on:remove={handleRemoveImage}
                    />
                </div>
                <div class="flex justify-end gap-2">
                    <button
                        type="button"
                        class="bg-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-400"
                        on:click={() => {
                            showAddModal = false;
                            selectedFile = null;
                        }}
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
                        disabled={uploadingLogo}
                    >
                        {uploadingLogo ? 'Uploading...' : 'Add Brand'}
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<!-- Edit Brand Modal -->
{#if showEditModal && selectedBrand}
    <div 
        class="modal-overlay" 
        on:click={() => showEditModal = false}
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
            <h2 id="edit-modal-title" class="text-xl font-bold mb-4">Edit Brand</h2>
            <form on:submit|preventDefault={handleEditBrand}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-name">
                        Name
                    </label>
                    <input
                        type="text"
                        id="edit-name"
                        bind:value={selectedBrand.name}
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
                        bind:value={selectedBrand.description}
                        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        rows="3"
                    ></textarea>
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-brand-logo">
                        Brand Logo
                    </label>
                    <ImageUpload
                        bind:this={editImageUpload}
                        currentImageUrl={selectedBrand.logo_url}
                        on:fileSelect={handleFileSelect}
                        on:error={handleUploadError}
                        on:remove={handleRemoveImage}
                    />
                </div>
                <div class="flex justify-end gap-2">
                    <button
                        type="button"
                        class="bg-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-400"
                        on:click={() => {
                            showEditModal = false;
                            selectedEditFile = null;
                        }}
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
                        disabled={uploadingLogo}
                    >
                        {uploadingLogo ? 'Uploading...' : 'Save Changes'}
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