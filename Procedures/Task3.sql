USE AutoPartsStore;

DROP PROCEDURE IF EXISTS sales_in_period;
DROP PROCEDURE IF EXISTS sales_by_amount;

DELIMITER $$;
CREATE PROCEDURE sales_in_period(IN good VARCHAR(30), IN since_date DATE, IN until_date DATE)
BEGIN

    SELECT customer_order_id, good_name, sku_amount, customer_order_date
    FROM customers_orders_view
    WHERE good_name = good
      AND customer_order_status_name = 'Оплачено'
      AND customer_order_date BETWEEN since_date AND until_date;

    SELECT COUNT(*)
    FROM customers_orders_view
    WHERE good_name = good
      AND customer_order_status_name = 'Оплачено'
      AND customer_order_date BETWEEN since_date AND until_date;
END $$;

DELIMITER $$;
CREATE PROCEDURE sales_by_amount(IN good VARCHAR(30), IN amount INT)
BEGIN
    SELECT customer_order_id, good_name, sku_amount, customer_order_date
    FROM customers_orders_view
    WHERE good_name = good
      AND customers_orders_view.sku_amount >= amount;

    SELECT COUNT(*)
    FROM customers_orders_view
    WHERE good_name = good
      AND sku_amount >= amount;
END $$;

CALL sales_in_period('Аккумулятор', '2022-01-01', NOW());
CALL sales_by_amount('Аккумулятор', 3);