USE AutoPartsStore;

DROP PROCEDURE IF EXISTS ten_best_sold_goods;
DROP PROCEDURE IF EXISTS ten_cheapest_suppliers_by_good;

DELIMITER $$;
CREATE PROCEDURE ten_best_sold_goods()
BEGIN
    SELECT good_name, SUM(sku_amount) as sum
    FROM customers_orders_view
    WHERE customer_order_status_name = 'Оплачено'
    GROUP BY good_name
    ORDER BY sum DESC
    LIMIT 10;
END $$;

DELIMITER $$;
CREATE PROCEDURE ten_cheapest_suppliers_by_good(IN good VARCHAR(30))
BEGIN
    SELECT supplier_name, supplier_price
    FROM catalogue_view
    WHERE good_name = good
    ORDER BY supplier_price
    LIMIT 10;
END $$;

CALL ten_best_sold_goods();
CALL ten_cheapest_suppliers_by_good('Аккумулятор');