<script lang="ts">
    import { cn } from '$lib/utils';
    import type { HTMLAttributes } from 'svelte/elements';

    type $$Props = HTMLAttributes<HTMLDivElement>;

    let className: $$Props['class'] = '';
    export { className as class };

    export let value: string;
</script>

<div
    class={cn(
        'relative flex w-full cursor-default select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50',
        className
    )}
    data-value={value}
    {...$$restProps}
>
    <slot />
</div> 