<script lang="ts">
    import { createEventDispatcher } from 'svelte';

    export let title: string = 'Confirm Action';
    export let message: string = 'Are you sure you want to proceed?';
    export let confirmText: string = 'Confirm';
    export let cancelText: string = 'Cancel';
    export let isOpen: boolean = false;

    const dispatch = createEventDispatcher();

    function handleConfirm() {
        dispatch('confirm');
        isOpen = false;
    }

    function handleCancel() {
        dispatch('cancel');
        isOpen = false;
    }

    function handleKeydown(event: KeyboardEvent) {
        if (event.key === 'Escape') {
            handleCancel();
        }
    }
</script>

{#if isOpen}
    <div 
        class="dialog-container"
        role="dialog"
        aria-modal="true"
        aria-labelledby="dialog-title"
        on:keydown={handleKeydown}
    >
        <div 
            class="dialog-overlay" 
            on:click={handleCancel}
            role="presentation"
        >
            <div 
                class="dialog-content" 
                on:click|stopPropagation
            >
                <h2 id="dialog-title" class="dialog-title">{title}</h2>
                <p class="dialog-message">{message}</p>
                <div class="dialog-actions">
                    <button 
                        class="cancel-button" 
                        on:click={handleCancel}
                        type="button"
                    >
                        {cancelText}
                    </button>
                    <button 
                        class="confirm-button" 
                        on:click={handleConfirm}
                        type="button"
                    >
                        {confirmText}
                    </button>
                </div>
            </div>
        </div>
    </div>
{/if}

<style>
    .dialog-container {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        z-index: 1000;
    }

    .dialog-overlay {
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .dialog-content {
        background: white;
        padding: 2rem;
        border-radius: 12px;
        width: 100%;
        max-width: 400px;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }

    .dialog-title {
        color: #2d3748;
        font-size: 1.25rem;
        margin-bottom: 1rem;
    }

    .dialog-message {
        color: #4a5568;
        margin-bottom: 1.5rem;
    }

    .dialog-actions {
        display: flex;
        justify-content: flex-end;
        gap: 1rem;
    }

    .cancel-button,
    .confirm-button {
        padding: 0.75rem 1.5rem;
        border-radius: 6px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s;
    }

    .cancel-button {
        background: white;
        color: #4a5568;
        border: 2px solid #e2e8f0;
    }

    .cancel-button:hover {
        background: #f7fafc;
    }

    .confirm-button {
        background: #e53e3e;
        color: white;
        border: none;
    }

    .confirm-button:hover {
        background: #c53030;
    }
</style> 