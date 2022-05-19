USE AutoPartsStore;

DROP PROCEDURE IF EXISTS good_info;

DELIMITER $$;
CREATE PROCEDURE good_info(IN supply VARCHAR(30))
BEGIN
    SELECT good_name, supplier_name, supplier_price, store_price, delivery_days
    FROM catalogue_view
    WHERE good_name = supply;
END $$;

CALL good_info('Аккумулятор');
