export type InventoryStatus = 'in_stock' | 'low_stock' | 'out_of_stock' | 'discontinued' | 'on_hold';
export type InventoryMovementType = 'purchase' | 'sale' | 'return' | 'adjustment' | 'transfer' | 'damage' | 'expiry';

export interface Inventory {
    id: string;
    shop_id: string;
    product_variant_id: string;
    product_name: string;
    sku: string;
    quantity: number;
    min_quantity: number;
    max_quantity: number;
    status: InventoryStatus;
    location: string | null;
    batch_number: string | null;
    expiry_date: string | null;
    cost_price: number | null;
    selling_price: number | null;
    notes: string | null;
    is_deleted: boolean;
    created_at: string;
    updated_at: string;
}

export interface InventoryMovement {
    id: string;
    inventory_id: string;
    movement_type: InventoryMovementType;
    quantity: number;
    reference_id: string | null;
    reference_type: string | null;
    notes: string | null;
    is_deleted: boolean;
    created_at: string;
    updated_at: string;
    created_by: string;
}

export interface InventoryAlert {
    id: string;
    inventory_id: string;
    alert_type: string;
    message: string;
    is_resolved: boolean;
    resolved_at: string | null;
    resolved_by: string | null;
    is_deleted: boolean;
    created_at: string;
    updated_at: string;
}

export interface InventoryTransfer {
    id: string;
    from_shop_id: string;
    to_shop_id: string;
    status: 'pending' | 'in_transit' | 'completed' | 'cancelled';
    notes: string | null;
    is_deleted: boolean;
    created_at: string;
    updated_at: string;
    created_by: string;
    completed_at: string | null;
    completed_by: string | null;
}

export interface InventoryTransferItem {
    id: string;
    transfer_id: string;
    product_variant_id: string;
    quantity: number;
    notes: string | null;
    is_deleted: boolean;
    created_at: string;
    updated_at: string;
} 