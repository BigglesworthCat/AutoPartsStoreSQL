USE AutoPartsStore;

DROP TRIGGER IF EXISTS insert_store_orders;
DROP TRIGGER IF EXISTS update_store_orders;

DELIMITER $$;
CREATE TRIGGER insert_store_orders
    BEFORE INSERT
    ON store_orders
    FOR EACH ROW
BEGIN
    SET NEW.store_order_status_id = (SELECT store_order_status_id
                                     FROM store_orders_statuses
                                     WHERE store_order_status_name = 'Заявку надіслано');
    SET NEW.store_order_date = NOW();
END $$;

DELIMITER $$;
CREATE TRIGGER update_store_orders
    BEFORE UPDATE
    ON store_orders
    FOR EACH ROW
BEGIN
    SET NEW.store_order_id = OLD.store_order_id;
    SET NEW.sku_id = OLD.sku_id;
    SET NEW.sku_amount = OLD.sku_amount;
    SET NEW.store_order_date = OLD.store_order_date;

    SET @send_order_id = (SELECT store_order_status_id
                          FROM store_orders_statuses
                          WHERE store_order_status_name = 'Заявку надіслано');
    SET @taken_order_id = (SELECT store_order_status_id
                           FROM store_orders_statuses
                           WHERE store_order_status_name = 'Прийнято');

    IF OLD.store_order_status_id = @send_order_id AND NEW.store_order_status_id = @taken_order_id THEN
        SET @storage_sku_capacity = (SELECT cell_capacity FROM storage WHERE storage.sku_id = OLD.sku_id);
        SET @storage_sku_amount = (SELECT sku_amount FROM storage WHERE storage.sku_id = OLD.sku_id);

        INSERT INTO storage(sku_id, sku_amount, cell_capacity, replenishment_date)
        VALUES (OLD.sku_id, OLD.sku_amount, GREATEST(OLD.sku_amount * 2, 20), NOW())
        ON DUPLICATE KEY UPDATE storage.cell_capacity      = GREATEST((storage.sku_amount + OLD.sku_amount),
                                                                      storage.cell_capacity),
                                storage.sku_amount         = storage.sku_amount + OLD.sku_amount,
                                storage.replenishment_date = NOW();
    ELSE
        SET NEW.store_order_status_id = OLD.store_order_status_id;
    END IF;
END $$;