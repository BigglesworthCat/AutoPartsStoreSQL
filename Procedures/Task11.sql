USE AutoPartsStore;

DROP PROCEDURE IF EXISTS sells_in_day;
DROP PROCEDURE IF EXISTS total_sells_in_day;

DELIMITER $$;
CREATE PROCEDURE sells_in_day(IN sale_day DATE)
BEGIN
    SELECT customer_order_id,
           good_name,
           supplier_name,
           sku_amount,
           defected_sku_amount,
           result_sku_amount * store_price AS Sum
    FROM customers_orders_view
    WHERE customer_order_date = sale_day
      AND customer_order_status_name = 'Оплачено';
END $$;

DELIMITER $$;
CREATE PROCEDURE total_sells_in_day(IN sale_day DATE)
BEGIN
        SET @total_revenue =
            (SELECT SUM(result_sku_amount * store_price)
             FROM customers_orders_view
             WHERE customer_order_date = sale_day
               AND customer_order_status_name = 'Оплачено');

    SET @total_amount =
            (SELECT SUM(result_sku_amount)
             FROM customers_orders_view
             WHERE customer_order_date = sale_day
               AND customer_order_status_name = 'Оплачено');

    SELECT TRUNCATE(@total_amount, 0), TRUNCATE(@total_revenue, 0);
END $$;

CALL sells_in_day('2022-01-01');
CALL total_sells_in_day('2022-01-01');