<script lang="ts">
    import type { DataTableProps } from './types';
    import { Loader2 } from 'lucide-svelte';

    export let columns: DataTableProps['columns'] = [];
    export let data: DataTableProps['data'] = [];
    export let loading: DataTableProps['loading'] = false;
</script>

<div class="relative overflow-x-auto">
    {#if loading}
        <div class="absolute inset-0 bg-white/50 flex items-center justify-center">
            <Loader2 class="w-6 h-6 animate-spin" />
        </div>
    {/if}
    
    <table class="w-full text-sm text-left">
        <thead class="text-xs uppercase bg-gray-50">
            <tr>
                {#each columns as column}
                    <th scope="col" class="px-6 py-3">
                        {column.header}
                    </th>
                {/each}
            </tr>
        </thead>
        <tbody>
            {#if data.length === 0}
                <tr>
                    <td colspan={columns.length} class="px-6 py-4 text-center text-gray-500">
                        No data available
                    </td>
                </tr>
            {:else}
                {#each data as row}
                    <tr class="bg-white border-b hover:bg-gray-50">
                        {#each columns as column}
                            <td class="px-6 py-4">
                                {#if column.cell}
                                    {@html column.cell({ row: { original: row } })}
                                {:else if column.accessorKey}
                                    {row[column.accessorKey]}
                                {/if}
                            </td>
                        {/each}
                    </tr>
                {/each}
            {/if}
        </tbody>
    </table>
</div> 