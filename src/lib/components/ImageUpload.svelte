<script lang="ts">
    import { createEventDispatcher } from 'svelte';
    import { toast } from '$lib/toast';

    export let currentImageUrl: string | null = null;
    export let accept = 'image/*';
    export let maxSize = 1048576; // 1MB
    export let modalType: 'add' | 'edit' = 'add';
    export let dragAndDrop = false;

    const dispatch = createEventDispatcher<{
        fileSelect: { file: File; modalType: 'add' | 'edit' };
        error: { message: string };
        remove: void;
    }>();

    let previewUrl: string | null = null;
    let fileInput: HTMLInputElement;
    let isDragging = false;
    let hasImage = false;

    $: hasImage = !!(previewUrl || currentImageUrl);

    function handleFileSelect(event: Event) {
        const input = event.target as HTMLInputElement;
        if (!input.files?.length) return;

        const file = input.files[0];
        if (!file) return;

        validateAndProcessFile(file);
    }

    function validateAndProcessFile(file: File) {
        // Validate file type
        if (!file.type.startsWith('image/')) {
            toast.error('Please select an image file');
            return;
        }

        // Validate file size
        if (file.size > maxSize) {
            toast.error('Image size should be less than 1MB');
            return;
        }

        // Create preview URL
        if (previewUrl) {
            URL.revokeObjectURL(previewUrl);
        }
        previewUrl = URL.createObjectURL(file);

        // Dispatch file selection event with modal type
        dispatch('fileSelect', { file, modalType });
    }

    function handleDragOver(event: DragEvent) {
        event.preventDefault();
        if (dragAndDrop) {
            isDragging = true;
        }
    }

    function handleDragLeave(event: DragEvent) {
        event.preventDefault();
        if (dragAndDrop) {
            isDragging = false;
        }
    }

    function handleDrop(event: DragEvent) {
        event.preventDefault();
        isDragging = false;

        if (!dragAndDrop) return;

        const files = event.dataTransfer?.files;
        if (!files?.length) return;

        const file = files[0];
        validateAndProcessFile(file);
    }

    function handleRemove() {
        if (previewUrl) {
            URL.revokeObjectURL(previewUrl);
            previewUrl = null;
        }
        if (fileInput) {
            fileInput.value = '';
        }
        dispatch('remove');
    }

    // Cleanup preview URL when component is destroyed
    import { onDestroy } from 'svelte';
    onDestroy(() => {
        if (previewUrl) {
            URL.revokeObjectURL(previewUrl);
        }
    });
</script>

<div class="relative">
    <div class="flex items-center space-x-4">
        {#if hasImage}
            <div class="relative">
                <img
                    src={previewUrl || currentImageUrl}
                    alt="Preview"
                    class="h-20 w-20 object-cover rounded"
                />
                <button
                    type="button"
                    class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                    on:click={handleRemove}
                >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                    </svg>
                </button>
            </div>
        {/if}
        <div class="flex-1">
            <input
                type="file"
                bind:this={fileInput}
                accept={accept}
                on:change={handleFileSelect}
                class="hidden"
                id="file-upload"
            />
            {#if dragAndDrop}
                <div
                    class="image-upload"
                    class:drag-active={isDragging}
                    on:dragover={handleDragOver}
                    on:dragleave={handleDragLeave}
                    on:drop={handleDrop}
                >
                    <label
                        for="file-upload"
                        class="upload-area"
                    >
                        <div class="upload-content">
                            <svg class="upload-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M4 4a2 2 0 00-2 2v8a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1.586a1 1 0 01-.707-.293l-1.121-1.121A2 2 0 0011.172 3H8.828a2 2 0 00-1.414.586L6.293 4.293A1 1 0 015.586 4H4zm6 9a3 3 0 100-6 3 3 0 000 6z" clip-rule="evenodd" />
                            </svg>
                            <p class="upload-text">Drag and drop your image here</p>
                            <p class="upload-hint">or click to browse</p>
                        </div>
                    </label>
                </div>
            {:else}
                <label
                    for="file-upload"
                    class="cursor-pointer inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                    <svg class="-ml-1 mr-2 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M4 4a2 2 0 00-2 2v8a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1.586a1 1 0 01-.707-.293l-1.121-1.121A2 2 0 0011.172 3H8.828a2 2 0 00-1.414.586L6.293 4.293A1 1 0 015.586 4H4zm6 9a3 3 0 100-6 3 3 0 000 6z" clip-rule="evenodd" />
                    </svg>
                    Choose Image
                </label>
            {/if}
        </div>
    </div>
</div>

<style>
    .image-upload {
        border: 2px dashed #cbd5e0;
        border-radius: 0.5rem;
        padding: 1.5rem;
        text-align: center;
        transition: all 0.2s;
        background: #f7fafc;
        outline: none;
    }

    .image-upload:focus {
        border-color: #4299e1;
        box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.2);
    }

    .image-upload.drag-active {
        border-color: #4299e1;
        background: #ebf8ff;
    }

    .current-image {
        margin-bottom: 1rem;
        display: flex;
        justify-content: center;
        position: relative;
    }

    .current-image img {
        max-height: 200px;
        max-width: 100%;
        object-fit: contain;
        border-radius: 0.25rem;
        border: 1px solid #e2e8f0;
    }

    .remove-button {
        position: absolute;
        top: -0.5rem;
        right: -0.5rem;
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 9999px;
        padding: 0.25rem;
        color: #4a5568;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
    }

    .remove-button:hover {
        background: #f7fafc;
        color: #e53e3e;
        border-color: #e53e3e;
    }

    .upload-area {
        cursor: pointer;
        display: block;
    }

    .upload-content {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.5rem;
    }

    .upload-icon {
        width: 3rem;
        height: 3rem;
        color: #a0aec0;
    }

    .upload-text {
        font-size: 1rem;
        color: #4a5568;
        margin: 0;
    }

    .upload-hint {
        font-size: 0.875rem;
        color: #718096;
        margin: 0;
    }

    .error-message {
        color: #e53e3e;
        font-size: 0.875rem;
        margin-top: 0.5rem;
    }

    .hidden {
        display: none;
    }
</style> 