-- Create color categories enum
CREATE TYPE color_category AS ENUM (
    'primary',     -- Basic colors like black, white, red, blue
    'neutral',     -- Beige, gray, brown, etc.
    'pastel',      -- Light, soft colors
    'metallic',    -- Gold, silver, bronze, etc.
    'pattern',     -- Multi-colored patterns
    'custom'       -- Special or custom colors
);

-- Modify colors table
ALTER TABLE colors 
    ADD COLUMN category color_category NOT NULL DEFAULT 'primary',
    ADD COLUMN display_order integer NOT NULL DEFAULT 0,
    ADD COLUMN description text,
    ADD COLUMN is_active boolean NOT NULL DEFAULT true;

-- Create unique constraint for name + category combination
ALTER TABLE colors ADD CONSTRAINT colors_name_category_key UNIQUE (name, category);

-- Create index for better querying
CREATE INDEX idx_colors_category ON colors(category);

-- Add common colors
INSERT INTO colors (name, hex_code, category, display_order, description) VALUES
-- Primary Colors
('Black', '#000000', 'primary', 1, 'Pure black'),
('White', '#FFFFFF', 'primary', 2, 'Pure white'),
('Red', '#FF0000', 'primary', 3, 'Classic red'),
('Blue', '#0000FF', 'primary', 4, 'Classic blue'),
('Green', '#008000', 'primary', 5, 'Classic green'),
('Yellow', '#FFFF00', 'primary', 6, 'Classic yellow'),
('Purple', '#800080', 'primary', 7, 'Classic purple'),
('Orange', '#FFA500', 'primary', 8, 'Classic orange'),
('Pink', '#FFC0CB', 'primary', 9, 'Classic pink'),

-- Neutral Colors
('Gray', '#808080', 'neutral', 1, 'Medium gray'),
('Light Gray', '#D3D3D3', 'neutral', 2, 'Light gray'),
('Dark Gray', '#404040', 'neutral', 3, 'Dark gray'),
('Beige', '#F5F5DC', 'neutral', 4, 'Light beige'),
('Brown', '#8B4513', 'neutral', 5, 'Classic brown'),
('Tan', '#D2B48C', 'neutral', 6, 'Light brown'),
('Navy', '#000080', 'neutral', 7, 'Dark blue'),
('Burgundy', '#800020', 'neutral', 8, 'Deep red'),
('Olive', '#808000', 'neutral', 9, 'Olive green'),

-- Pastel Colors
('Pastel Pink', '#FFB6C1', 'pastel', 1, 'Soft pink'),
('Pastel Blue', '#ADD8E6', 'pastel', 2, 'Soft blue'),
('Pastel Green', '#98FB98', 'pastel', 3, 'Soft green'),
('Pastel Yellow', '#FFFFE0', 'pastel', 4, 'Soft yellow'),
('Pastel Purple', '#E6E6FA', 'pastel', 5, 'Soft purple'),
('Mint', '#98FF98', 'pastel', 6, 'Fresh mint'),
('Lavender', '#E6E6FA', 'pastel', 7, 'Soft lavender'),
('Peach', '#FFDAB9', 'pastel', 8, 'Soft peach'),
('Sky Blue', '#87CEEB', 'pastel', 9, 'Light blue'),

-- Metallic Colors
('Gold', '#FFD700', 'metallic', 1, 'Classic gold'),
('Silver', '#C0C0C0', 'metallic', 2, 'Classic silver'),
('Bronze', '#CD7F32', 'metallic', 3, 'Classic bronze'),
('Rose Gold', '#B76E79', 'metallic', 4, 'Modern rose gold'),
('Champagne', '#F7E7CE', 'metallic', 5, 'Light gold'),
('Copper', '#B87333', 'metallic', 6, 'Classic copper'),
('Platinum', '#E5E4E2', 'metallic', 7, 'Light silver'),
('Gunmetal', '#2C3539', 'metallic', 8, 'Dark metallic'),
('Brass', '#B5A642', 'metallic', 9, 'Yellow-gold metallic'),

-- Pattern Colors
('Striped', NULL, 'pattern', 1, 'Multiple colors in stripes'),
('Plaid', NULL, 'pattern', 2, 'Multiple colors in plaid pattern'),
('Floral', NULL, 'pattern', 3, 'Multiple colors in floral pattern'),
('Animal Print', NULL, 'pattern', 4, 'Multiple colors in animal print'),
('Geometric', NULL, 'pattern', 5, 'Multiple colors in geometric pattern'),
('Tie-Dye', NULL, 'pattern', 6, 'Multiple colors in tie-dye pattern'),
('Camouflage', NULL, 'pattern', 7, 'Multiple colors in camouflage pattern'),
('Polka Dot', NULL, 'pattern', 8, 'Multiple colors in polka dot pattern'),
('Abstract', NULL, 'pattern', 9, 'Multiple colors in abstract pattern'); 