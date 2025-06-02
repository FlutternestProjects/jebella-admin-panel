<script lang="ts">
    import { createEventDispatcher } from 'svelte';
    import { cn } from '$lib/utils';
    import type { HTMLAttributes } from 'svelte/elements';

    type $$Props = HTMLAttributes<HTMLDivElement>;

    let className: $$Props['class'] = '';
    export { className as class };

    let value: string = '';
    export { value };

    const dispatch = createEventDispatcher<{
        change: { value: string };
    }>();

    function handleChange(event: Event) {
        const target = event.target as HTMLSelectElement;
        value = target.value;
        dispatch('change', { value });
    }
</script>

<div
    class={cn(
        'relative',
        className
    )}
    {...$$restProps}
>
    <slot {handleChange} {value} />
</div> 