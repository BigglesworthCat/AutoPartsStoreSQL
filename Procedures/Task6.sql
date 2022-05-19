USE AutoPartsStore;

DROP PROCEDURE IF EXISTS good_average_sales_by_months;

DELIMITER $$;
CREATE PROCEDURE good_average_sales_by_months()
BEGIN
    SET @min_date = (SELECT DISTINCT customer_order_date
                     FROM customers_orders_view
                     WHERE customer_order_status_name = 'Оплачено'
                       AND customer_order_date <= ALL (SELECT customer_order_date
                                                       FROM customers_orders_view
                                                       WHERE customer_order_status_name = 'Оплачено'));

    SET @max_date = (SELECT DISTINCT customer_order_date
                     FROM customers_orders_view
                     WHERE customer_order_status_name = 'Оплачено'
                       AND customer_order_date >= ALL (SELECT customer_order_date
                                                       FROM customers_orders_view
                                                       WHERE customer_order_status_name = 'Оплачено'));

    SET @moths = TIMESTAMPDIFF(MONTH, @min_date, @max_date) + 1;

    SELECT good_name, SUM(sku_amount) / @moths
    FROM customers_orders_view
    WHERE customer_order_status_name = 'Оплачено'
    GROUP BY good_name;
END $$;

CALL good_average_sales_by_months();

