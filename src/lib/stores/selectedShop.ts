import { writable } from 'svelte/store';

export const selectedShop = writable<string | null>(null); 