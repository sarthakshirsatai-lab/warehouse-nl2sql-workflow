-- Warehouse/Inventory Query Workflow — Phase 1 schema
-- Mumbai-region simulated warehouse database. See PRD Section 7.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS stock_movements;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS warehouses;

CREATE TABLE warehouses (
    warehouse_code  TEXT PRIMARY KEY,      -- WH-MUM-{NN}
    location_area   TEXT NOT NULL,         -- real Mumbai logistics hub area
    capacity_units  INTEGER NOT NULL
);

CREATE TABLE suppliers (
    supplier_id         TEXT PRIMARY KEY,  -- SUP-{3-digit}
    supplier_name       TEXT NOT NULL,
    avg_lead_time_days  INTEGER NOT NULL,
    reliability_rating  INTEGER NOT NULL CHECK (reliability_rating BETWEEN 1 AND 5)
);

CREATE TABLE products (
    sku_id               TEXT PRIMARY KEY,     -- SKU-{5-digit}
    sku_name             TEXT NOT NULL,
    category             TEXT NOT NULL,        -- fixed: 'Beauty'
    sub_category         TEXT NOT NULL,
    uom                  TEXT NOT NULL CHECK (uom IN ('EA','BOX','KG','LTR')),
    unit_cost            REAL NOT NULL,         -- INR, no currency symbol stored
    reorder_level        INTEGER NOT NULL,
    primary_supplier_id  TEXT NOT NULL REFERENCES suppliers(supplier_id)
);

CREATE TABLE inventory (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,  -- surrogate key; multiple batches per warehouse+SKU allowed
    warehouse_code       TEXT NOT NULL REFERENCES warehouses(warehouse_code),
    sku_id               TEXT NOT NULL REFERENCES products(sku_id),
    quantity_on_hand     INTEGER NOT NULL,
    last_restocked_date  TEXT NOT NULL,   -- ISO date
    batch_number         TEXT NOT NULL
);

CREATE TABLE stock_movements (
    movement_id     TEXT PRIMARY KEY,     -- MOV-{6-digit}
    warehouse_code  TEXT NOT NULL REFERENCES warehouses(warehouse_code),
    sku_id          TEXT NOT NULL REFERENCES products(sku_id),
    movement_type   TEXT NOT NULL CHECK (movement_type IN ('Inbound','Outbound','Adjustment')),
    quantity        INTEGER NOT NULL,
    movement_date   TEXT NOT NULL         -- ISO date
);

CREATE INDEX idx_inventory_wh_sku ON inventory(warehouse_code, sku_id);
CREATE INDEX idx_movements_wh_sku ON stock_movements(warehouse_code, sku_id);
CREATE INDEX idx_movements_date ON stock_movements(movement_date);
