export interface Brand {
    id: string;
    name: string;
    description: string | null;
    logo_url: string | null;
    is_deleted: boolean;
    created_at: string;
    updated_at: string;
} 