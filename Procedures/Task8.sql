USE AutoPartsStore;

DROP PROCEDURE IF EXISTS overheads_part;

DELIMITER $$;
CREATE PROCEDURE overheads_part()
BEGIN
    SET @overheads_total =
            (SELECT SUM(overhead_cost)
             FROM overheads);

    SET @sell_total =
            (SELECT SUM((sku_amount - defected_sku_amount) * store_price)
             FROM customers_orders_view
             WHERE customer_order_status_name = 'Оплачено');

    SELECT TRUNCATE(@overheads_total / @sell_total * 100, 3) AS 'Накладні витрати відносно продажів (%)';
END $$;

CALL overheads_part();