USE AutoPartsStore;

DROP PROCEDURE IF EXISTS suppliers_part;

DELIMITER $$;
CREATE PROCEDURE suppliers_part(IN supplier VARCHAR(30), IN since_date DATE, IN until_date DATE)
BEGIN
    #     Кількість замовлених магазином позицій з каталогу що замовляються у постачальника
    SET @amount_part =
            (SELECT SUM(sku_amount)
             FROM store_orders_view
             WHERE store_order_status_name = 'Прийнято'
               AND supplier_name = supplier);

    SET @amount_total = (SELECT SUM(sku_amount)
                         FROM store_orders_view
                         WHERE store_order_status_name = 'Прийнято');

    #   Грошова сумма товарів замовлених у постачальника
    SET @cost_part =
            (SELECT SUM(sku_amount * supplier_price)
             FROM store_orders_view
             WHERE store_order_status_name = 'Прийнято'
               AND supplier_name = supplier);

    SET @profit_part = (SELECT SUM((sku_amount - defected_sku_amount) * (store_price - supplier_price))
                        FROM customers_orders_view
                        WHERE customer_order_status_name = 'Оплачено'
                          AND supplier_name = supplier
                          AND customer_order_date BETWEEN since_date AND until_date);

    SET @profit_total = (SELECT SUM((sku_amount - defected_sku_amount) * (store_price - supplier_price))
                         FROM customers_orders_view
                         WHERE customer_order_status_name = 'Оплачено'
                           AND customer_order_date BETWEEN since_date AND until_date);

    SELECT TRUNCATE(@amount_part / @amount_total * 100, 3) AS 'Частка товару (%)',
           TRUNCATE(@cost_part, 2)                         AS 'Грошова частка',
           CONCAT(@amount_part, '/', @amount_total)        AS 'Частка товару (в од.)',
           TRUNCATE(@profit_part / @profit_total * 100, 3) AS 'Частка прибутку (%)';
END $$;

CALL suppliers_part('Мустанг', '2022-01-01', NOW());