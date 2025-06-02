<script lang="ts">
    import { cn } from '$lib/utils';
    import type { HTMLAttributes } from 'svelte/elements';

    type $$Props = HTMLAttributes<HTMLSpanElement>;

    let className: $$Props['class'] = '';
    export { className as class };
</script>

<span
    class={cn(
        'block truncate',
        className
    )}
    {...$$restProps}
>
    <slot />
</span> 