USE AutoPartsStore;

DROP PROCEDURE IF EXISTS customers_bookings;
DROP PROCEDURE IF EXISTS total_customers_bookings;

CREATE PROCEDURE customers_bookings()
BEGIN
    SELECT customer_order_id,
           good_name,
           supplier_name,
           sku_amount,
           sku_amount * store_price,
           customer_order_date
    FROM customers_orders_view
    WHERE customer_order_status_name = 'Заявку прийнято';
END;

CREATE PROCEDURE total_customers_bookings()
BEGIN
    SET @total_bookings =
            (SELECT COUNT(*)
             FROM customers_orders_view
             WHERE customer_order_status_name = 'Заявку прийнято');

    SET @total_sum =
            (SELECT SUM(sku_amount * store_price)
             FROM customers_orders_view
             WHERE customer_order_status_name = 'Заявку прийнято');

    SELECT @total_bookings, TRUNCATE(@total_sum, 0);
END;

CALL customers_bookings();
CALL total_customers_bookings();