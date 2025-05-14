-- Create size types enum
CREATE TYPE size_type AS ENUM ('alpha', 'numeric', 'custom');

-- Create size categories enum
CREATE TYPE size_category AS ENUM (
    'tops',           -- For shirts, t-shirts, etc.
    'bottoms',        -- For pants, shorts, etc.
    'dresses',        -- For dresses, jumpsuits, etc.
    'shoes',          -- For footwear
    'accessories',    -- For belts, hats, etc.
    'unisex'          -- For unisex items
);

-- Drop existing unique constraint if it exists
ALTER TABLE sizes DROP CONSTRAINT IF EXISTS sizes_label_key;

-- Modify sizes table
ALTER TABLE sizes 
    ADD COLUMN size_type size_type NOT NULL DEFAULT 'alpha',
    ADD COLUMN category size_category NOT NULL DEFAULT 'unisex',
    ADD COLUMN numeric_value integer,
    ADD COLUMN display_order integer NOT NULL DEFAULT 0,
    ADD COLUMN description text,
    ADD COLUMN is_active boolean NOT NULL DEFAULT true;

-- Create unique constraint for label + category combination
ALTER TABLE sizes ADD CONSTRAINT sizes_label_category_key UNIQUE (label, category);

-- Create index for better querying
CREATE INDEX idx_sizes_category_type ON sizes(category, size_type);

-- Add some common sizes
INSERT INTO sizes (label, size_type, category, numeric_value, display_order, description) VALUES
-- Alpha sizes for tops
('XXS', 'alpha', 'tops', NULL, 1, 'Extra Extra Small'),
('XS', 'alpha', 'tops', NULL, 2, 'Extra Small'),
('S', 'alpha', 'tops', NULL, 3, 'Small'),
('M', 'alpha', 'tops', NULL, 4, 'Medium'),
('L', 'alpha', 'tops', NULL, 5, 'Large'),
('XL', 'alpha', 'tops', NULL, 6, 'Extra Large'),
('XXL', 'alpha', 'tops', NULL, 7, 'Extra Extra Large'),
('3XL', 'alpha', 'tops', NULL, 8, 'Triple Extra Large'),

-- Numeric sizes for shoes
('36', 'numeric', 'shoes', 36, 1, 'EU 36 / US 5.5'),
('37', 'numeric', 'shoes', 37, 2, 'EU 37 / US 6'),
('38', 'numeric', 'shoes', 38, 3, 'EU 38 / US 6.5'),
('39', 'numeric', 'shoes', 39, 4, 'EU 39 / US 7'),
('40', 'numeric', 'shoes', 40, 5, 'EU 40 / US 7.5'),
('41', 'numeric', 'shoes', 41, 6, 'EU 41 / US 8'),
('42', 'numeric', 'shoes', 42, 7, 'EU 42 / US 8.5'),
('43', 'numeric', 'shoes', 43, 8, 'EU 43 / US 9'),
('44', 'numeric', 'shoes', 44, 9, 'EU 44 / US 9.5'),
('45', 'numeric', 'shoes', 45, 10, 'EU 45 / US 10'),

-- Numeric sizes for bottoms
('28', 'numeric', 'bottoms', 28, 1, 'Waist 28 inches'),
('29', 'numeric', 'bottoms', 29, 2, 'Waist 29 inches'),
('30', 'numeric', 'bottoms', 30, 3, 'Waist 30 inches'),
('31', 'numeric', 'bottoms', 31, 4, 'Waist 31 inches'),
('32', 'numeric', 'bottoms', 32, 5, 'Waist 32 inches'),
('33', 'numeric', 'bottoms', 33, 6, 'Waist 33 inches'),
('34', 'numeric', 'bottoms', 34, 7, 'Waist 34 inches'),
('35', 'numeric', 'bottoms', 35, 8, 'Waist 35 inches'),
('36', 'numeric', 'bottoms', 36, 9, 'Waist 36 inches'),
('38', 'numeric', 'bottoms', 38, 10, 'Waist 38 inches'),
('40', 'numeric', 'bottoms', 40, 11, 'Waist 40 inches'),
('42', 'numeric', 'bottoms', 42, 12, 'Waist 42 inches'),

-- Custom sizes for accessories
('One Size', 'custom', 'accessories', NULL, 1, 'Fits all sizes'),
('Small', 'custom', 'accessories', NULL, 2, 'Small size'),
('Medium', 'custom', 'accessories', NULL, 3, 'Medium size'),
('Large', 'custom', 'accessories', NULL, 4, 'Large size'); 