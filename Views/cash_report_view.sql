USE AutoPartsStore;

CREATE OR REPLACE VIEW cash_report_view
AS
SELECT good_name,
       supplier_name AS supplier_customer_id,
       (sku_amount * supplier_price) AS store_purchase,
       0                             AS customers_purchase,
       store_order_date              AS operation_date
FROM store_orders_view
WHERE store_order_status_name = 'Прийнято'
UNION
SELECT good_name,
       supplier_name,
       0,
       (sku_amount * store_price),
       customer_order_date
FROM customers_orders_view
WHERE customer_order_status_name = 'Оплачено';