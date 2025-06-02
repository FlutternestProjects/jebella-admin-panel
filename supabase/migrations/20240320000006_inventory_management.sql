-- Create inventory status enum
CREATE TYPE inventory_status AS ENUM (
    'in_stock',        -- Available for sale
    'low_stock',       -- Below minimum threshold
    'out_of_stock',    -- No stock available
    'discontinued',    -- No longer being sold
    'on_hold'          -- Temporarily unavailable
);

-- Create inventory movement type enum
CREATE TYPE inventory_movement_type AS ENUM (
    'purchase',        -- Initial stock purchase
    'sale',           -- Stock sold
    'return',         -- Customer return
    'adjustment',     -- Manual adjustment
    'transfer',       -- Transfer between shops
    'damage',         -- Damaged stock
    'expiry'          -- Expired stock
);

-- Create inventory table
CREATE TABLE inventory (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES seller_shops(id),
    product_variant_id uuid NOT NULL REFERENCES product_variants(id),
    quantity integer NOT NULL DEFAULT 0,
    min_quantity integer NOT NULL DEFAULT 0,
    max_quantity integer NOT NULL DEFAULT 0,
    status inventory_status NOT NULL DEFAULT 'in_stock',
    location text,                    -- Physical location in warehouse/shop
    batch_number text,                -- For tracking batches
    expiry_date timestamp with time zone, -- For perishable items
    cost_price numeric,               -- Cost price for this batch
    selling_price numeric,            -- Shop-specific selling price
    notes text,
    is_deleted boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Create inventory movements table for tracking all stock changes
CREATE TABLE inventory_movements (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    inventory_id uuid NOT NULL REFERENCES inventory(id),
    movement_type inventory_movement_type NOT NULL,
    quantity integer NOT NULL,         -- Positive for additions, negative for reductions
    reference_id uuid,                -- Reference to related entity (order, transfer, etc.)
    reference_type text,              -- Type of reference (order, transfer, etc.)
    notes text,
    is_deleted boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    created_by uuid NOT NULL REFERENCES users(id)
);

-- Create inventory alerts table for low stock notifications
CREATE TABLE inventory_alerts (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    inventory_id uuid NOT NULL REFERENCES inventory(id),
    alert_type text NOT NULL,         -- low_stock, expiry, etc.
    message text NOT NULL,
    is_resolved boolean NOT NULL DEFAULT false,
    resolved_at timestamp with time zone,
    resolved_by uuid REFERENCES users(id),
    is_deleted boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Create inventory transfers table for shop-to-shop transfers
CREATE TABLE inventory_transfers (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    from_shop_id uuid NOT NULL REFERENCES seller_shops(id),
    to_shop_id uuid NOT NULL REFERENCES seller_shops(id),
    status text NOT NULL DEFAULT 'pending', -- pending, in_transit, completed, cancelled
    notes text,
    is_deleted boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    created_by uuid NOT NULL REFERENCES users(id),
    completed_at timestamp with time zone,
    completed_by uuid REFERENCES users(id)
);

-- Create inventory transfer items table
CREATE TABLE inventory_transfer_items (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    transfer_id uuid NOT NULL REFERENCES inventory_transfers(id),
    product_variant_id uuid NOT NULL REFERENCES product_variants(id),
    quantity integer NOT NULL,
    notes text,
    is_deleted boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Create indexes for better querying
CREATE INDEX idx_inventory_shop ON inventory(shop_id);
CREATE INDEX idx_inventory_product ON inventory(product_variant_id);
CREATE INDEX idx_inventory_status ON inventory(status);
CREATE INDEX idx_inventory_movements_inventory ON inventory_movements(inventory_id);
CREATE INDEX idx_inventory_movements_type ON inventory_movements(movement_type);
CREATE INDEX idx_inventory_alerts_inventory ON inventory_alerts(inventory_id);
CREATE INDEX idx_inventory_transfers_shops ON inventory_transfers(from_shop_id, to_shop_id);

-- Add triggers for inventory status updates
CREATE OR REPLACE FUNCTION update_inventory_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Update status based on quantity
    IF NEW.quantity <= 0 THEN
        NEW.status := 'out_of_stock';
    ELSIF NEW.quantity <= NEW.min_quantity THEN
        NEW.status := 'low_stock';
    ELSE
        NEW.status := 'in_stock';
    END IF;
    
    -- Create alert for low stock
    IF NEW.quantity <= NEW.min_quantity AND OLD.quantity > NEW.min_quantity THEN
        INSERT INTO inventory_alerts (inventory_id, alert_type, message)
        VALUES (NEW.id, 'low_stock', 'Stock level has fallen below minimum threshold');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inventory_status_trigger
    BEFORE UPDATE ON inventory
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_status();

-- Add trigger for inventory movement tracking
CREATE OR REPLACE FUNCTION track_inventory_movement()
RETURNS TRIGGER AS $$
BEGIN
    -- Record the movement
    INSERT INTO inventory_movements (
        inventory_id,
        movement_type,
        quantity,
        notes,
        created_by
    ) VALUES (
        NEW.id,
        CASE 
            WHEN NEW.quantity > OLD.quantity THEN 'purchase'
            WHEN NEW.quantity < OLD.quantity THEN 'sale'
            ELSE 'adjustment'
        END,
        NEW.quantity - OLD.quantity,
        'Automatic movement tracking',
        auth.uid()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inventory_movement_trigger
    AFTER UPDATE ON inventory
    FOR EACH ROW
    WHEN (OLD.quantity IS DISTINCT FROM NEW.quantity)
    EXECUTE FUNCTION track_inventory_movement();

-- Add updated_at triggers for all tables
CREATE TRIGGER set_timestamp_inventory
    BEFORE UPDATE ON inventory
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_inventory_movements
    BEFORE UPDATE ON inventory_movements
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_inventory_alerts
    BEFORE UPDATE ON inventory_alerts
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_inventory_transfers
    BEFORE UPDATE ON inventory_transfers
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_inventory_transfer_items
    BEFORE UPDATE ON inventory_transfer_items
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp(); 