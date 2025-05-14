<script lang="ts">
    import { createEventDispatcher } from 'svelte';

    export let currentImageUrl: string | null = null;
    export let accept = 'image/*';
    export let maxSize = 1048576; // 1MB in bytes

    let dragActive = false;
    let fileInput: HTMLInputElement;
    let error: string | null = null;
    let previewUrl: string | null = null;

    const dispatch = createEventDispatcher<{
        fileSelect: { file: File };
        error: { message: string };
        remove: void;
    }>();

    function handleDragEnter(e: DragEvent) {
        e.preventDefault();
        e.stopPropagation();
        dragActive = true;
    }

    function handleDragLeave(e: DragEvent) {
        e.preventDefault();
        e.stopPropagation();
        dragActive = false;
    }

    function handleDragOver(e: DragEvent) {
        e.preventDefault();
        e.stopPropagation();
    }

    function handleDrop(e: DragEvent) {
        e.preventDefault();
        e.stopPropagation();
        dragActive = false;

        const files = e.dataTransfer?.files;
        if (!files?.length) return;

        handleFile(files[0]);
    }

    function handleFileSelect(e: Event) {
        const input = e.target as HTMLInputElement;
        if (!input.files?.length) return;
        handleFile(input.files[0]);
    }

    function handleFile(file: File) {
        error = null;

        // Check file size
        if (file.size > maxSize) {
            error = `File size must be less than ${maxSize / 1024 / 1024}MB`;
            dispatch('error', { message: error });
            return;
        }

        // Check file type
        if (!file.type.startsWith('image/')) {
            error = 'Please select an image file';
            dispatch('error', { message: error });
            return;
        }

        // Create preview URL
        if (previewUrl) {
            URL.revokeObjectURL(previewUrl);
        }
        previewUrl = URL.createObjectURL(file);
        dispatch('fileSelect', { file });
    }

    function triggerFileInput() {
        // Reset the file input value to allow selecting the same file again
        fileInput.value = '';
        fileInput.click();
    }

    function handleRemove(e: MouseEvent) {
        e.stopPropagation();
        if (previewUrl) {
            URL.revokeObjectURL(previewUrl);
            previewUrl = null;
        }
        // Reset the file input value
        fileInput.value = '';
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

<div
    class="image-upload"
    class:drag-active={dragActive}
    on:dragenter={handleDragEnter}
    on:dragleave={handleDragLeave}
    on:dragover={handleDragOver}
    on:drop={handleDrop}
    role="button"
    tabindex="0"
    on:keydown={(e) => e.key === 'Enter' && triggerFileInput()}
>
    <input
        type="file"
        bind:this={fileInput}
        {accept}
        on:change={handleFileSelect}
        class="hidden"
    />

    {#if previewUrl || currentImageUrl}
        <div class="current-image">
            <img src={previewUrl || currentImageUrl} alt="Preview" />
            <button
                type="button"
                class="remove-button"
                on:click={handleRemove}
                aria-label="Remove image"
            >
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M6 18L18 6M6 6l12 12"
                    />
                </svg>
            </button>
        </div>
    {:else}
        <div class="upload-area" on:click={triggerFileInput}>
            <div class="upload-content">
                <svg
                    class="upload-icon"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                    />
                </svg>
                <p class="upload-text">
                    {#if dragActive}
                        Drop your image here
                    {:else}
                        Drag and drop an image here, or click to select
                    {/if}
                </p>
                <p class="upload-hint">Max file size: {maxSize / 1024 / 1024}MB. Supported formats: JPG, PNG, GIF</p>
            </div>
        </div>
    {/if}

    {#if error}
        <p class="error-message">{error}</p>
    {/if}
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