USE AutoPartsStore;

DROP TRIGGER IF EXISTS insert_customers_orders;
DROP TRIGGER IF EXISTS update_customers_orders;

DELIMITER $$;
CREATE TRIGGER insert_customers_orders
    BEFORE INSERT
    ON customers_orders
    FOR EACH ROW
BEGIN
    SET NEW.customer_order_date = NOW();

    SET @cell_in_storage = (SELECT cell_id
                            FROM storage
                            WHERE storage.sku_id = NEW.sku_id
                              AND storage.sku_amount >= NEW.sku_amount);

    IF @cell_in_storage IS NOT NULL THEN
        SET NEW.customer_order_status_id = (SELECT customer_order_status_id
                                            FROM customers_orders_statuses
                                            WHERE customer_order_status_name = 'Оплачено');
        UPDATE storage
        SET sku_amount = sku_amount - NEW.sku_amount
        WHERE sku_id = NEW.sku_id;
    ELSE
        SET NEW.customer_order_status_id = (SELECT customer_order_status_id
                                            FROM customers_orders_statuses
                                            WHERE customer_order_status_name = 'Заявку прийнято');
        SET NEW.defected_sku_amount = 0;
    END IF;
END $$;

DELIMITER $$;
CREATE TRIGGER update_customers_orders
    BEFORE UPDATE
    ON customers_orders
    FOR EACH ROW
BEGIN
    SET NEW.customer_order_id = OLD.customer_order_id;
    SET NEW.sku_id = OLD.sku_id;
    SET NEW.sku_amount = OLD.sku_amount;
    SET NEW.customer_order_date = OLD.customer_order_date;

    SET @send_order_id = (SELECT customer_order_status_id
                          FROM customers_orders_statuses
                          WHERE customer_order_status_name = 'Заявку прийнято');
    SET @taken_order_id = (SELECT customer_order_status_id
                           FROM customers_orders_statuses
                           WHERE customer_order_status_name = 'Оплачено');

    IF OLD.customer_order_status_id = @send_order_id AND NEW.customer_order_status_id = @send_order_id THEN
        SET NEW.defected_sku_amount = 0;
    END IF;

    IF OLD.customer_order_status_id = @taken_order_id AND NEW.customer_order_status_id = @send_order_id THEN
        SET NEW.customer_order_status_id = OLD.customer_order_status_id;
    END IF;
END $$;