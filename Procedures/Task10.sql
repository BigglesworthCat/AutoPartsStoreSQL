USE AutoPartsStore;

DROP PROCEDURE IF EXISTS suppliers_by_defected_sku;
DROP PROCEDURE IF EXISTS total_defected_sku;

DELIMITER $$;
CREATE PROCEDURE suppliers_by_defected_sku(IN since_date DATE, IN until_date DATE)
BEGIN
    SELECT good_name, supplier_name, SUM(defected_sku_amount) AS defected
    FROM customers_orders_view
    WHERE customer_order_status_name = 'Оплачено'
      AND customer_order_date BETWEEN since_date AND until_date
    GROUP BY sku_id
    HAVING defected != 0;
END $$;

DELIMITER $$;
CREATE PROCEDURE total_defected_sku(IN since_date DATE, IN until_date DATE)
BEGIN
    SET @total_defected = (SELECT SUM(defected)
                           FROM (SELECT SUM(defected_sku_amount) AS defected
                                 FROM customers_orders_view
                                 WHERE customer_order_status_name = 'Оплачено'
                                   AND customer_order_date BETWEEN since_date AND until_date
                                 GROUP BY sku_id) query);
    SELECT TRUNCATE(@total_defected, 0) AS 'Товарів з дефектами всього';
END $$;

CALL suppliers_by_defected_sku('2022-01-01', '2022-05-16');
CALL total_defected_sku('2022-01-01', '2022-05-16');