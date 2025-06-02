<script lang="ts">
    import { cn } from '$lib/utils';
    import type { HTMLAttributes } from 'svelte/elements';

    type $$Props = HTMLAttributes<HTMLDivElement>;

    let className: $$Props['class'] = '';
    export { className as class };
</script>

<div
    class={cn(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
        className
    )}
    {...$$restProps}
>
    <slot />
</div> 