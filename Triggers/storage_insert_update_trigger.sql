USE AutoPartsStore;

DROP TRIGGER IF EXISTS insert_storage;
DROP TRIGGER IF EXISTS update_storage;

DELIMITER $$;
CREATE TRIGGER insert_storage
    BEFORE INSERT
    ON storage
    FOR EACH ROW
BEGIN
    insert_loop:
    WHILE NEW.sku_amount > 0
        DO
            SET @ordered_id = (SELECT customer_order_status_id
                               FROM customers_orders_statuses
                               WHERE customer_order_status_name = 'Заявку прийнято');
            SET @payed_id = (SELECT customer_order_status_id
                             FROM customers_orders_statuses
                             WHERE customer_order_status_name = 'Оплачено');


            SET @customer_order_id =
                    (SELECT customer_order_id
                     FROM customers_orders
                     WHERE customers_orders.sku_id = NEW.sku_id
                       AND customers_orders.sku_amount <= NEW.sku_amount
                       AND customer_order_status_id = @ordered_id
                     ORDER BY customer_order_date
                     LIMIT 1);

            IF @customer_order_id IS NOT NULL THEN
                SET @order_amount = (SELECT sku_amount
                                     FROM customers_orders
                                     WHERE customer_order_id = @customer_order_id);

                UPDATE customers_orders
                SET customer_order_status_id = @payed_id
                WHERE customer_order_id = @customer_order_id;

                SET NEW.sku_amount = NEW.sku_amount - @order_amount;
            ELSE
                LEAVE insert_loop;
            END IF;
        END WHILE insert_loop;
END $$;

DELIMITER $$;
CREATE TRIGGER update_storage
    BEFORE UPDATE
    ON storage
    FOR EACH ROW
BEGIN
    update_loop:
    WHILE NEW.sku_amount > 0
        DO
            SET @ordered_id = (SELECT customer_order_status_id
                               FROM customers_orders_statuses
                               WHERE customer_order_status_name = 'Заявку прийнято');
            SET @payed_id = (SELECT customer_order_status_id
                             FROM customers_orders_statuses
                             WHERE customer_order_status_name = 'Оплачено');


            SET @customer_order_id =
                    (SELECT customer_order_id
                     FROM customers_orders
                     WHERE customers_orders.sku_id = NEW.sku_id
                       AND customers_orders.sku_amount <= NEW.sku_amount
                       AND customer_order_status_id = @ordered_id
                     ORDER BY customer_order_date
                     LIMIT 1);

            IF @customer_order_id IS NOT NULL THEN
                SET @order_amount = (SELECT sku_amount
                                     FROM customers_orders
                                     WHERE customer_order_id = @customer_order_id);

                UPDATE customers_orders
                SET customer_order_status_id = @payed_id
                WHERE customer_order_id = @customer_order_id;

                SET NEW.sku_amount = NEW.sku_amount - @order_amount;
            ELSE
                LEAVE update_loop;
            END IF;
        END WHILE update_loop;
END $$;