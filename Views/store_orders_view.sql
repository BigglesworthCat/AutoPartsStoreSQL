USE AutoPartsStore;

CREATE OR REPLACE VIEW store_orders_view
AS
SELECT store_order_id,
       store_orders.sku_id,
       good_name,
       supplier_name,
       supplier_category_name,
       sku_amount,
       supplier_price,
       store_price,
       store_order_status_name,
       store_order_date
FROM store_orders
         INNER JOIN store_orders_statuses sos ON store_orders.store_order_status_id = sos.store_order_status_id
         INNER JOIN catalogue_view cv ON store_orders.sku_id = cv.sku_id;