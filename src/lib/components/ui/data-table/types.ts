export interface Column {
    header: string;
    accessorKey?: string;
    cell?: (props: { row: { original: any } }) => string;
}

export interface DataTableProps {
    columns: Column[];
    data: any[];
    loading?: boolean;
} 