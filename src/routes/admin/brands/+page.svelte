<script lang="ts">
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import type { Brand } from '$lib/types';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';
    import { toast } from '$lib/toast';
    import ImageUpload from '$lib/components/ImageUpload.svelte';
    import Pagination from '$lib/components/Pagination.svelte';
    import SearchBar from '$lib/components/SearchBar.svelte';

    interface Brand {
        id: string;
        name: string;
        description: string;
        logo_url: string;
        is_deleted: boolean;
        created_at: string;
        updated_at: string;
    }

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
    let isImageRemoved = false;
    let error: string | null = null;
    let currentPage = 1;
    let totalPages = 1;
    let searchQuery = '';
    const itemsPerPage = 10;

    onMount(async () => {
        await fetchBrands();
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

    async function fetchBrands() {
        try {
            loading = true;
            error = null;

            let query = supabase
                .from('brands')
                .select('*', { count: 'exact' })
                .eq('is_deleted', false);

            if (searchQuery) {
                query = query.ilike('name', `%${searchQuery}%`);
            }

            const { data, error: err, count } = await query
                .range((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage - 1)
                .order('created_at', { ascending: false });

            if (err) throw err;

            brands = data || [];
            totalPages = Math.ceil((count || 0) / itemsPerPage);
        } catch (err) {
            console.error('Error fetching brands:', err);
            error = 'Failed to load brands';
        } finally {
            loading = false;
        }
    }

    function handlePageChange(page: number) {
        currentPage = page;
        fetchBrands();
    }

    function handleSearch(event: CustomEvent<{ value: string }>) {
        searchQuery = event.detail.value;
        currentPage = 1;
        fetchBrands();
    }

    function handleFileSelect(event: CustomEvent<{ file: File; modalType: 'add' | 'edit' }>) {
        const { file, modalType } = event.detail;
        console.log('File selected:', file.name, file.type, file.size, 'for modal:', modalType);

        if (modalType === 'add') {
            selectedFile = file;
            console.log('File assigned to add modal');
        } else if (modalType === 'edit') {
            selectedEditFile = file;
            console.log('File assigned to edit modal');
        } else {
            console.error('Unknown modal type:', modalType);
        }
    }

    function handleRemoveImage(event: CustomEvent<void>) {
        const sourceElement = event.target as HTMLElement;
        const modalElement = sourceElement.closest('[data-modal]');
        
        if (!modalElement) {
            console.error('Could not find modal element');
            return;
        }

        const modalType = modalElement.getAttribute('data-modal');
        if (modalType === 'add') {
            selectedFile = null;
            newBrand.logo_url = '';
            isImageRemoved = true;
            console.log('File removed from add modal');
        } else if (modalType === 'edit') {
            selectedEditFile = null;
            if (selectedBrand) {
                // Store the old URL for potential deletion
                const oldLogoUrl = selectedBrand.logo_url;
                selectedBrand.logo_url = '';
                
                // Delete the old logo from storage if it exists
                if (oldLogoUrl) {
                    deleteOldLogo(oldLogoUrl).then((success) => {
                        if (success) {
                            console.log('Old logo deleted from storage');
                        } else {
                            console.warn('Failed to delete old logo from storage');
                        }
                    });
                }
            }
            isImageRemoved = true;
            console.log('File removed from edit modal');
        } else {
            console.error('Unknown modal type:', modalType);
        }
    }

    function handleUploadError(event: CustomEvent<{ message: string }>) {
        toast.error(event.detail.message);
    }

    async function deleteOldLogo(logoUrl: string): Promise<boolean> {
        try {
            if (!logoUrl) return true;

            // Extract the file path from the URL
            // URL format: https://[project].supabase.co/storage/v1/object/public/brand-logos/[filename]
            const urlParts = logoUrl.split('/');
            const fileName = urlParts[urlParts.length - 1];
            
            if (!fileName) {
                console.warn('Could not extract filename from URL:', logoUrl);
                return true; // Don't block the operation
            }

            console.log('Deleting old logo:', fileName);

            const { error } = await supabase.storage
                .from('brand-logos')
                .remove([fileName]);

            if (error) {
                console.error('Error deleting old logo:', error);
                // Don't throw error - we don't want to block the update if deletion fails
                return false;
            }

            console.log('Old logo deleted successfully:', fileName);
            return true;
        } catch (error) {
            console.error('Error in deleteOldLogo:', error);
            return false;
        }
    }

    async function uploadLogo(file: File): Promise<string | null> {
        try {
            uploadingLogo = true;
            console.log('Starting file upload:', file.name, file.type, file.size);

            // First, check if we can access storage
            const { data: { user }, error: userError } = await supabase.auth.getUser();
            if (userError) {
                console.error('Auth error:', userError);
                throw new Error('Authentication required for upload');
            }

            if (!user) {
                console.error('No authenticated user found');
                throw new Error('You must be logged in to upload files');
            }

            console.log('User authenticated:', user.id);

            // Generate a unique file name
            const timestamp = Date.now();
            const randomString = Math.random().toString(36).substring(2, 15);
            const fileExt = file.name.split('.').pop();
            const fileName = `${timestamp}-${randomString}.${fileExt}`;
            const filePath = fileName;
            
            console.log('Uploading file:', {
                fileName,
                fileType: file.type,
                fileSize: file.size,
                userId: user.id
            });

            // Upload the file directly to the brand-logos bucket
            const { error: uploadError, data } = await supabase.storage
                .from('brand-logos')
                .upload(filePath, file, {
                    cacheControl: '3600',
                    upsert: true,
                    contentType: file.type
                });

            if (uploadError) {
                console.error('Upload error:', uploadError);
                if (uploadError.message.includes('bucket does not exist')) {
                    throw new Error('Storage bucket not found. Please contact the administrator to create the brand-logos bucket.');
                }
                if (uploadError.message.includes('row-level security policy')) {
                    throw new Error('Permission denied. Please ensure you have the correct permissions to upload files.');
                }
                throw new Error(`Upload failed: ${uploadError.message}`);
            }

            console.log('Upload successful:', data);

            // Get the public URL
            const { data: urlData } = supabase.storage
                .from('brand-logos')
                .getPublicUrl(filePath);

            console.log('Public URL:', urlData.publicUrl);
            return urlData.publicUrl;
        } catch (error) {
            console.error('Error uploading logo:', error);
            const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
            toast.error(`Failed to upload logo: ${errorMessage}`);
            return null;
        } finally {
            uploadingLogo = false;
        }
    }

    async function handleAddBrand() {
        try {
            if (!newBrand.name?.trim()) {
                toast.error('Brand name is required');
                return;
            }

            // Check if brand name already exists
            const { data: existingBrand, error: checkError } = await supabase
                .from('brands')
                .select('id')
                .eq('name', newBrand.name.trim())
                .eq('is_deleted', false)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking brand name:', checkError);
                throw checkError;
            }

            if (existingBrand) {
                toast.error('A brand with this name already exists');
                return;
            }

            let logoUrl = newBrand.logo_url;

            // If a file was selected, upload it
            if (selectedFile) {
                console.log('Uploading selected file for add modal:', selectedFile.name);
                const uploadedUrl = await uploadLogo(selectedFile);
                if (uploadedUrl) {
                    logoUrl = uploadedUrl;
                } else {
                    toast.error('Failed to upload logo');
                    return;
                }
            }

            const { error } = await supabase
                .from('brands')
                .insert([{ 
                    name: newBrand.name.trim(),
                    description: newBrand.description.trim(),
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
            await fetchBrands();
        } catch (error) {
            console.error('Error adding brand:', error);
            const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
            toast.error(`Failed to add brand: ${errorMessage}`);
        }
    }

    async function handleEditBrand() {
        if (!selectedBrand) return;

        try {
            if (!selectedBrand.name?.trim()) {
                toast.error('Brand name is required');
                return;
            }

            // Check if brand name already exists (excluding current brand)
            const { data: existingBrand, error: checkError } = await supabase
                .from('brands')
                .select('id')
                .eq('name', selectedBrand.name.trim())
                .eq('is_deleted', false)
                .neq('id', selectedBrand.id)
                .single();

            if (checkError && checkError.code !== 'PGRST116') {
                console.error('Error checking brand name:', checkError);
                throw checkError;
            }

            if (existingBrand) {
                toast.error('A brand with this name already exists');
                return;
            }

            let logoUrl = selectedBrand.logo_url;

            // If a new file was selected, upload it
            if (selectedEditFile) {
                console.log('Uploading selected file for edit modal:', selectedEditFile.name);
                
                // First, delete the old logo if it exists
                if (selectedBrand.logo_url) {
                    console.log('Deleting old logo before uploading new one');
                    await deleteOldLogo(selectedBrand.logo_url);
                }
                
                // Upload the new logo
                const uploadedUrl = await uploadLogo(selectedEditFile);
                if (uploadedUrl) {
                    logoUrl = uploadedUrl;
                } else {
                    toast.error('Failed to upload logo');
                    return;
                }
            }

            const { error } = await supabase
                .from('brands')
                .update({
                    name: selectedBrand.name.trim(),
                    description: selectedBrand.description.trim(),
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
            await fetchBrands();
        } catch (error) {
            console.error('Error updating brand:', error);
            toast.error('Failed to update brand');
        }
    }

    async function handleDeleteBrand(brandId: string) {
        if (!confirm('Are you sure you want to delete this brand?')) return;

        try {
            // Find the brand to get its logo URL before deletion
            const brandToDelete = brands.find(b => b.id === brandId);
            
            const { error } = await supabase
                .from('brands')
                .update({ is_deleted: true })
                .eq('id', brandId);

            if (error) throw error;

            // Delete the logo from storage if it exists
            if (brandToDelete?.logo_url) {
                console.log('Deleting logo for deleted brand');
                await deleteOldLogo(brandToDelete.logo_url);
            }

            toast.success('Brand deleted successfully');
            await fetchBrands();
        } catch (error) {
            console.error('Error deleting brand:', error);
            toast.error('Failed to delete brand');
        }
    }

    // Reset state when closing modals
    function handleCloseAddModal() {
        showAddModal = false;
        newBrand = { name: '', description: '', logo_url: '' };
        selectedFile = null;
        if (previewUrl) {
            URL.revokeObjectURL(previewUrl);
            previewUrl = null;
        }
    }

    function handleCloseEditModal() {
        showEditModal = false;
        selectedBrand = null;
        selectedEditFile = null;
        if (editPreviewUrl) {
            URL.revokeObjectURL(editPreviewUrl);
            editPreviewUrl = null;
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

    <div class="mb-4">
        <SearchBar placeholder="Search brands..." on:search={handleSearch} />
    </div>

    {#if loading}
        <div class="flex justify-center items-center h-64">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        </div>
    {:else if error}
        <div class="text-center py-4 text-red-600">{error}</div>
    {:else if brands.length === 0}
        <div class="text-center py-4 text-gray-500">No brands found</div>
    {:else}
        <div class="bg-white rounded-lg shadow overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Logo</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created At</th>
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
                                        <span class="text-gray-500 text-xs">No logo</span>
                                    </div>
                                {/if}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">{brand.name}</td>
                            <td class="px-6 py-4 whitespace-nowrap">{brand.description}</td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                {new Date(brand.created_at).toLocaleDateString()}
                            </td>
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

        <div class="mt-4">
            <Pagination
                {currentPage}
                {totalPages}
                onPageChange={handlePageChange}
            />
        </div>
    {/if}
</div>

<!-- Add Brand Modal -->
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
            <h2 id="add-modal-title" class="text-xl font-bold mb-4">Add New Brand</h2>
            <form on:submit|preventDefault={handleAddBrand}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="name">
                        Name *
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
                    <label class="block text-gray-700 text-sm font-bold mb-2">
                        Brand Logo
                    </label>
                    <div data-modal="add">
                        <ImageUpload
                            bind:this={addImageUpload}
                            currentImageUrl={newBrand.logo_url}
                            modalType="add"
                            dragAndDrop={true}
                            on:fileSelect={handleFileSelect}
                            on:remove={handleRemoveImage}
                            on:error={handleUploadError}
                        />
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
                        Add Brand
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
            <h2 id="edit-modal-title" class="text-xl font-bold mb-4">Edit Brand</h2>
            <form on:submit|preventDefault={handleEditBrand}>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="edit-name">
                        Name *
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
                    <label class="block text-gray-700 text-sm font-bold mb-2">
                        Brand Logo
                    </label>
                    <div data-modal="edit">
                        <ImageUpload
                            bind:this={editImageUpload}
                            currentImageUrl={selectedBrand.logo_url}
                            modalType="edit"
                            dragAndDrop={true}
                            on:fileSelect={handleFileSelect}
                            on:remove={handleRemoveImage}
                            on:error={handleUploadError}
                        />
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