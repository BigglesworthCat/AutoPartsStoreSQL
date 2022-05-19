USE AutoPartsStore;

DROP PROCEDURE IF EXISTS unsold_goods;

DELIMITER $$;
CREATE PROCEDURE unsold_goods()
BEGIN
    SET @unsold = (SELECT SUM(sku_amount)
                   FROM storage_view);

    SET @total_ordered = (SELECT SUM(sku_amount)
                          FROM store_orders_view
                          WHERE store_order_status_name = 'Прийнято');

    SELECT TRUNCATE(@unsold / @total_ordered * 100, 3) AS 'Частка нереалізованого товару товару (%)',
           CONCAT(@unsold, '/', @total_ordered)        AS 'Частка нереалізованого товару (в од.)';
END $$;

CALL unsold_goods();