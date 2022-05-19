USE AutoPartsStore;

ALTER TABLE catalogue
ADD CONSTRAINT catalog_check CHECK ( supplier_price >=0 AND store_price >=0 AND delivery_days >= 0 );

ALTER TABLE storage
ADD CONSTRAINT storage_check CHECK ( cell_capacity >= 0 AND sku_amount BETWEEN 0 AND cell_capacity);

ALTER TABLE store_orders
ADD CONSTRAINT store_orders_check CHECK ( sku_amount >= 1 );

ALTER TABLE overheads
ADD CONSTRAINT overheads_check CHECK ( overheads.overhead_cost >= 0 );

ALTER TABLE customers_orders
ADD CONSTRAINT customer_order_check CHECK ( sku_amount >= 1 AND defected_sku_amount BETWEEN 0 AND sku_amount);
