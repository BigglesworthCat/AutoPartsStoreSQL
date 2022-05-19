USE AutoPartsStore;

DROP PROCEDURE IF EXISTS suppliers_by_good;
DROP PROCEDURE IF EXISTS suppliers_by_good_in_period;

DELIMITER $$;
CREATE PROCEDURE suppliers_by_good(IN good VARCHAR(30), IN supplier VARCHAR(30))
BEGIN
    SELECT supplier_name
    FROM catalogue_view
    WHERE good_name = good
      AND supplier_category_name = supplier;

    SELECT COUNT(*)
    FROM catalogue_view
    WHERE good_name = good
      AND supplier_category_name = supplier;
END $$;

DELIMITER $$;
CREATE PROCEDURE suppliers_by_good_in_period(IN supply VARCHAR(30), IN partner VARCHAR(30), IN amount INT,
                                             IN since_date DATE, IN until_date DATE)
BEGIN
    SELECT supplier_name
    FROM store_orders_view
    WHERE good_name = supply
      AND store_order_status_name = 'Прийнято'
      AND supplier_category_name = partner
      AND sku_amount >= amount
      AND store_order_date BETWEEN since_date AND until_date;

    SELECT COUNT(*)
    FROM store_orders_view
    WHERE good_name = supply
      AND store_order_status_name = 'Прийнято'
      AND supplier_category_name = partner
      AND sku_amount >= amount
      AND store_order_date BETWEEN since_date AND until_date;
END $$;


CALL suppliers_by_good('Аккумулятор', 'Дилер');
CALL suppliers_by_good_in_period('Аккумулятор', 'Дилер', 3, '2022-01-01', NOW());