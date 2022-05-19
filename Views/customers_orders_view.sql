USE AutoPartsStore;

CREATE OR REPLACE VIEW customers_orders_view
AS
SELECT customer_order_id,
       customers_orders.sku_id,
       good_name,
       supplier_name,
       supplier_category_name,
       sku_amount,
       defected_sku_amount,
       IF(supplier_category_name IN ('Виробник', 'Дилер'), sku_amount, sku_amount - customers_orders.defected_sku_amount) AS result_sku_amount,
       supplier_price,
       store_price,
       customer_order_status_name,
       customer_order_date
FROM customers_orders
         INNER JOIN customers_orders_statuses cos
                    ON customers_orders.customer_order_status_id = cos.customer_order_status_id
         INNER JOIN catalogue_view cv ON customers_orders.sku_id = cv.sku_id;