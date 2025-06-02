import { writable } from 'svelte/store';

type ToastType = 'success' | 'error' | 'info' | 'warning';

interface Toast {
    id: number;
    type: ToastType;
    message: string;
}

function createToastStore() {
    const { subscribe, update } = writable<Toast[]>([]);
    let id = 0;

    function add(type: ToastType, message: string) {
        const toast: Toast = { id: id++, type, message };
        update(toasts => [...toasts, toast]);
        setTimeout(() => {
            update(toasts => toasts.filter(t => t.id !== toast.id));
        }, 3000);
    }

    return {
        subscribe,
        success: (message: string) => add('success', message),
        error: (message: string) => add('error', message),
        info: (message: string) => add('info', message),
        warning: (message: string) => add('warning', message)
    };
}

export const toast = createToastStore(); 