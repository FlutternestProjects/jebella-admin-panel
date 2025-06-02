<script lang="ts">
    import { cn } from '$lib/utils';
    import type { HTMLButtonAttributes } from 'svelte/elements';

    type $$Props = HTMLButtonAttributes;

    let className: $$Props['class'] = '';
    export { className as class };
</script>

<button
    class={cn(
        'inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
        'bg-primary text-primary-foreground hover:bg-primary/90',
        'h-10 px-4 py-2',
        className
    )}
    {...$$restProps}
>
    <slot />
</button> 