USE AutoPartsStore;

DROP PROCEDURE IF EXISTS velocity_of_good;

DELIMITER $$;
CREATE PROCEDURE velocity_of_good(IN good VARCHAR(20), IN since_date DATE, IN until_date DATE)
BEGIN
    SET @total_good_profit = (SELECT SUM(result_sku_amount * store_price)
                              FROM customers_orders_view
                              WHERE good_name = good
                                AND customer_order_date BETWEEN since_date AND until_date);

    SET @average_reserve = (SELECT SUM(sku_amount * store_price) / 2
                            FROM inventory_reports_view
                                     INNER JOIN catalogue c ON inventory_reports_view.sku_id = c.sku_id
                            WHERE good_name = good
                              AND (inventory_report_date = since_date OR inventory_report_date = until_date));

    SELECT TRUNCATE(@total_good_profit / @average_reserve, 2);
END $$;

CALL velocity_of_good('Аккумулятор', '2022-02-01', '2022-03-01');