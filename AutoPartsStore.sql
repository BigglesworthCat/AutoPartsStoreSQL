CREATE TABLE IF NOT EXISTS customers_orders_statuses
(
    customer_order_status_id   INT AUTO_INCREMENT
        PRIMARY KEY,
    customer_order_status_name VARCHAR(20) NOT NULL,
    CONSTRAINT customers_orders_statuses_key
        UNIQUE (customer_order_status_name)
)
    AUTO_INCREMENT = 3;

CREATE TABLE IF NOT EXISTS goods
(
    good_id   INT AUTO_INCREMENT
        PRIMARY KEY,
    good_name VARCHAR(30) NOT NULL,
    CONSTRAINT goods_key
        UNIQUE (good_name)
)
    AUTO_INCREMENT = 17;

CREATE TABLE IF NOT EXISTS overheads
(
    overhead_id   INT AUTO_INCREMENT
        PRIMARY KEY,
    overhead_name VARCHAR(20)   NOT NULL,
    overhead_cost INT DEFAULT 0 NOT NULL,
    CONSTRAINT overheads_key
        UNIQUE (overhead_name),
    CONSTRAINT overheads_check
        CHECK (`overhead_cost` >= 0)
)
    AUTO_INCREMENT = 4;

CREATE TABLE IF NOT EXISTS store_orders_statuses
(
    store_order_status_id   INT AUTO_INCREMENT
        PRIMARY KEY,
    store_order_status_name VARCHAR(20) NOT NULL,
    CONSTRAINT store_orders_statuses_key
        UNIQUE (store_order_status_name)
)
    AUTO_INCREMENT = 2;

CREATE TABLE IF NOT EXISTS suppliers_categories
(
    supplier_category_id   INT AUTO_INCREMENT
        PRIMARY KEY,
    supplier_category_name VARCHAR(20) NOT NULL,
    CONSTRAINT suppliers_categories_key
        UNIQUE (supplier_category_name)
)
    AUTO_INCREMENT = 5;

CREATE TABLE IF NOT EXISTS suppliers_statuses
(
    supplier_status_id   INT AUTO_INCREMENT
        PRIMARY KEY,
    supplier_status_name VARCHAR(20) NOT NULL,
    CONSTRAINT suppliers_statuses_key
        UNIQUE (supplier_status_name)
)
    AUTO_INCREMENT = 2;

CREATE TABLE IF NOT EXISTS suppliers
(
    supplier_id          INT AUTO_INCREMENT
        PRIMARY KEY,
    supplier_name        VARCHAR(20)   NOT NULL,
    supplier_category_id INT DEFAULT 1 NOT NULL,
    supplier_status_id   INT DEFAULT 1 NOT NULL,
    CONSTRAINT suppliers_key
        UNIQUE (supplier_name),
    CONSTRAINT suppliers_suppliers_categories_supplier_category_id_fk
        FOREIGN KEY (supplier_category_id) REFERENCES suppliers_categories (supplier_category_id)
            ON UPDATE CASCADE,
    CONSTRAINT suppliers_suppliers_statuses_supplier_status_id_fk
        FOREIGN KEY (supplier_status_id) REFERENCES suppliers_statuses (supplier_status_id)
            ON UPDATE CASCADE
)
    AUTO_INCREMENT = 27;

CREATE TABLE IF NOT EXISTS catalogue
(
    sku_id         INT AUTO_INCREMENT
        PRIMARY KEY,
    good_id        INT           NOT NULL,
    supplier_id    INT           NOT NULL,
    supplier_price INT DEFAULT 0 NOT NULL,
    store_price    INT DEFAULT 0 NOT NULL,
    delivery_days  INT DEFAULT 1 NOT NULL,
    CONSTRAINT catalogue_key
        UNIQUE (good_id, supplier_id),
    CONSTRAINT catalogue_goods_good_id_fk
        FOREIGN KEY (good_id) REFERENCES goods (good_id)
            ON UPDATE CASCADE,
    CONSTRAINT catalogue_suppliers_supplier_id_fk
        FOREIGN KEY (supplier_id) REFERENCES suppliers (supplier_id)
            ON UPDATE CASCADE,
    CONSTRAINT catalog_check
        CHECK ((`supplier_price` >= 0) AND (`store_price` >= 0) AND (`delivery_days` >= 0))
)
    AUTO_INCREMENT = 146;

CREATE DEFINER = root@localhost TRIGGER insert_catalogue
    BEFORE INSERT
    ON catalogue
    FOR EACH ROW
BEGIN
    SET NEW.store_price = NEW.supplier_price * 1.2;
END;

CREATE DEFINER = root@localhost TRIGGER update_catalogue
    BEFORE UPDATE
    ON catalogue
    FOR EACH ROW
BEGIN
    IF OLD.store_price = 0 THEN
        SET NEW.store_price = NEW.supplier_price * 1.2;
    END IF;
END;

CREATE TABLE IF NOT EXISTS customers_orders
(
    customer_order_id        INT AUTO_INCREMENT
        PRIMARY KEY,
    sku_id                   INT                       NOT NULL,
    sku_amount               INT  DEFAULT 1            NOT NULL,
    defected_sku_amount      INT  DEFAULT 0            NULL,
    customer_order_status_id INT  DEFAULT 1            NOT NULL,
    customer_order_date      DATE DEFAULT '2022-01-01' NOT NULL,
    CONSTRAINT customers_orders_catalogue_sku_id_fk
        FOREIGN KEY (sku_id) REFERENCES catalogue (sku_id)
            ON UPDATE CASCADE,
    CONSTRAINT customers_orders_statuses_id_fk
        FOREIGN KEY (customer_order_status_id) REFERENCES customers_orders_statuses (customer_order_status_id)
            ON UPDATE CASCADE,
    CONSTRAINT customer_order_check
        CHECK ((`sku_amount` >= 1) AND (`defected_sku_amount` BETWEEN 0 AND `sku_amount`))
)
    AUTO_INCREMENT = 18;

CREATE DEFINER = root@localhost TRIGGER insert_customers_orders
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
END;

CREATE DEFINER = root@localhost TRIGGER update_customers_orders
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
END;

CREATE TABLE IF NOT EXISTS inventory_reports
(
    inventory_report_date DATE NOT NULL,
    sku_id                INT  NULL,
    sku_amount            INT  NOT NULL,
    CONSTRAINT inventory_reports_pk
        UNIQUE (inventory_report_date, sku_id),
    CONSTRAINT inventory_reports_catalogue_sku_id_fk
        FOREIGN KEY (sku_id) REFERENCES catalogue (sku_id)
            ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS storage
(
    cell_id            INT AUTO_INCREMENT
        PRIMARY KEY,
    sku_id             INT  DEFAULT 1            NULL,
    sku_amount         INT                       NOT NULL,
    cell_capacity      INT  DEFAULT 20           NOT NULL,
    replenishment_date DATE DEFAULT '2022-01-01' NOT NULL,
    CONSTRAINT storage_key
        UNIQUE (sku_id),
    CONSTRAINT storage_catalogue_sku_id_fk
        FOREIGN KEY (sku_id) REFERENCES catalogue (sku_id)
            ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT storage_check
        CHECK ((`cell_capacity` >= 0) AND (`sku_amount` BETWEEN 0 AND `cell_capacity`))
)
    AUTO_INCREMENT = 8;

CREATE DEFINER = root@localhost TRIGGER insert_storage
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
END;

CREATE DEFINER = root@localhost TRIGGER update_storage
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
END;

CREATE TABLE IF NOT EXISTS store_orders
(
    store_order_id        INT AUTO_INCREMENT
        PRIMARY KEY,
    sku_id                INT                       NOT NULL,
    sku_amount            INT  DEFAULT 1            NOT NULL,
    store_order_status_id INT  DEFAULT 1            NOT NULL,
    store_order_date      DATE DEFAULT '2022-01-01' NOT NULL,
    CONSTRAINT store_orders_catalogue_sku_id_fk
        FOREIGN KEY (sku_id) REFERENCES catalogue (sku_id)
            ON UPDATE CASCADE,
    CONSTRAINT store_orders_store_orders_statuses_store_order_status_id_fk
        FOREIGN KEY (store_order_status_id) REFERENCES store_orders_statuses (store_order_status_id)
            ON UPDATE CASCADE,
    CONSTRAINT store_orders_check
        CHECK (`sku_amount` >= 1)
)
    AUTO_INCREMENT = 18;

CREATE DEFINER = root@localhost TRIGGER insert_store_orders
    BEFORE INSERT
    ON store_orders
    FOR EACH ROW
BEGIN
    SET NEW.store_order_status_id = (SELECT store_order_status_id
                                     FROM store_orders_statuses
                                     WHERE store_order_status_name = 'Заявку надіслано');
    SET NEW.store_order_date = NOW();
END;

CREATE DEFINER = root@localhost TRIGGER update_store_orders
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
END;

CREATE OR REPLACE DEFINER = root@localhost VIEW cash_report_view AS
SELECT `AutoPartsStore`.`store_orders_view`.`good_name`                                                            AS `good_name`,
       `AutoPartsStore`.`store_orders_view`.`supplier_name`                                                        AS `supplier_customer_id`,
       (`AutoPartsStore`.`store_orders_view`.`sku_amount` *
        `AutoPartsStore`.`store_orders_view`.`supplier_price`)                                                     AS `store_purchase`,
       0                                                                                                           AS `customers_purchase`,
       `AutoPartsStore`.`store_orders_view`.`store_order_date`                                                     AS `operation_date`
FROM `AutoPartsStore`.`store_orders_view`
WHERE (`AutoPartsStore`.`store_orders_view`.`store_order_status_name` = 'Прийнято')
UNION
SELECT `AutoPartsStore`.`customers_orders_view`.`good_name`           AS `good_name`,
       `AutoPartsStore`.`customers_orders_view`.`supplier_name`       AS `supplier_name`,
       0                                                              AS `0`,
       (`AutoPartsStore`.`customers_orders_view`.`sku_amount` *
        `AutoPartsStore`.`customers_orders_view`.`store_price`)       AS `(sku_amount * store_price)`,
       `AutoPartsStore`.`customers_orders_view`.`customer_order_date` AS `customer_order_date`
FROM `AutoPartsStore`.`customers_orders_view`
WHERE (`AutoPartsStore`.`customers_orders_view`.`customer_order_status_name` = 'Оплачено');

CREATE OR REPLACE DEFINER = root@localhost VIEW catalogue_view AS
SELECT `AutoPartsStore`.`catalogue`.`sku_id`         AS `sku_id`,
       `g`.`good_name`                               AS `good_name`,
       `s`.`supplier_name`                           AS `supplier_name`,
       `sc`.`supplier_category_name`                 AS `supplier_category_name`,
       `AutoPartsStore`.`catalogue`.`supplier_price` AS `supplier_price`,
       `AutoPartsStore`.`catalogue`.`store_price`    AS `store_price`,
       `AutoPartsStore`.`catalogue`.`delivery_days`  AS `delivery_days`
FROM (((`AutoPartsStore`.`catalogue` JOIN `AutoPartsStore`.`goods` `g`
        ON ((`AutoPartsStore`.`catalogue`.`good_id` = `g`.`good_id`))) JOIN `AutoPartsStore`.`suppliers` `s`
       ON ((`AutoPartsStore`.`catalogue`.`supplier_id` = `s`.`supplier_id`))) JOIN `AutoPartsStore`.`suppliers_categories` `sc`
      ON ((`s`.`supplier_category_id` = `sc`.`supplier_category_id`)));

CREATE OR REPLACE DEFINER = root@localhost VIEW customers_orders_view AS
SELECT `AutoPartsStore`.`customers_orders`.`customer_order_id`                                                           AS `customer_order_id`,
       `AutoPartsStore`.`customers_orders`.`sku_id`                                                                      AS `sku_id`,
       `AutoPartsStore`.`cv`.`good_name`                                                                                 AS `good_name`,
       `AutoPartsStore`.`cv`.`supplier_name`                                                                             AS `supplier_name`,
       `AutoPartsStore`.`cv`.`supplier_category_name`                                                                    AS `supplier_category_name`,
       `AutoPartsStore`.`customers_orders`.`sku_amount`                                                                  AS `sku_amount`,
       `AutoPartsStore`.`customers_orders`.`defected_sku_amount`                                                         AS `defected_sku_amount`,
       IF((`AutoPartsStore`.`cv`.`supplier_category_name` IN ('Виробник', 'Дилер')),
          `AutoPartsStore`.`customers_orders`.`sku_amount`, (`AutoPartsStore`.`customers_orders`.`sku_amount` -
                                                             `AutoPartsStore`.`customers_orders`.`defected_sku_amount`)) AS `result_sku_amount`,
       `AutoPartsStore`.`cv`.`supplier_price`                                                                            AS `supplier_price`,
       `AutoPartsStore`.`cv`.`store_price`                                                                               AS `store_price`,
       `cos`.`customer_order_status_name`                                                                                AS `customer_order_status_name`,
       `AutoPartsStore`.`customers_orders`.`customer_order_date`                                                         AS `customer_order_date`
FROM ((`AutoPartsStore`.`customers_orders` JOIN `AutoPartsStore`.`customers_orders_statuses` `cos`
       ON ((`AutoPartsStore`.`customers_orders`.`customer_order_status_id` =
            `cos`.`customer_order_status_id`))) JOIN `AutoPartsStore`.`catalogue_view` `cv`
      ON ((`AutoPartsStore`.`customers_orders`.`sku_id` = `AutoPartsStore`.`cv`.`sku_id`)));

CREATE OR REPLACE DEFINER = root@localhost VIEW inventory_reports_view AS
SELECT `AutoPartsStore`.`inventory_reports`.`inventory_report_date` AS `inventory_report_date`,
       `AutoPartsStore`.`inventory_reports`.`sku_id`                AS `sku_id`,
       `AutoPartsStore`.`cv`.`good_name`                            AS `good_name`,
       `AutoPartsStore`.`cv`.`supplier_name`                        AS `supplier_name`,
       `AutoPartsStore`.`inventory_reports`.`sku_amount`            AS `sku_amount`
FROM (`AutoPartsStore`.`inventory_reports` JOIN `AutoPartsStore`.`catalogue_view` `cv`
      ON ((`AutoPartsStore`.`inventory_reports`.`sku_id` = `AutoPartsStore`.`cv`.`sku_id`)));

CREATE OR REPLACE DEFINER = root@localhost VIEW storage_view AS
SELECT `AutoPartsStore`.`storage`.`cell_id`            AS `cell_id`,
       `AutoPartsStore`.`storage`.`sku_id`             AS `sku_id`,
       `AutoPartsStore`.`cv`.`good_name`               AS `good_name`,
       `AutoPartsStore`.`cv`.`supplier_name`           AS `supplier_name`,
       `AutoPartsStore`.`cv`.`supplier_category_name`  AS `supplier_category_name`,
       `AutoPartsStore`.`storage`.`sku_amount`         AS `sku_amount`,
       `AutoPartsStore`.`storage`.`cell_capacity`      AS `cell_capacity`,
       `AutoPartsStore`.`storage`.`replenishment_date` AS `replenishment_date`
FROM (`AutoPartsStore`.`storage` JOIN `AutoPartsStore`.`catalogue_view` `cv`
      ON ((`AutoPartsStore`.`storage`.`sku_id` = `AutoPartsStore`.`cv`.`sku_id`)));

CREATE OR REPLACE DEFINER = root@localhost VIEW store_orders_view AS
SELECT `AutoPartsStore`.`store_orders`.`store_order_id`   AS `store_order_id`,
       `AutoPartsStore`.`store_orders`.`sku_id`           AS `sku_id`,
       `AutoPartsStore`.`cv`.`good_name`                  AS `good_name`,
       `AutoPartsStore`.`cv`.`supplier_name`              AS `supplier_name`,
       `AutoPartsStore`.`cv`.`supplier_category_name`     AS `supplier_category_name`,
       `AutoPartsStore`.`store_orders`.`sku_amount`       AS `sku_amount`,
       `AutoPartsStore`.`cv`.`supplier_price`             AS `supplier_price`,
       `AutoPartsStore`.`cv`.`store_price`                AS `store_price`,
       `sos`.`store_order_status_name`                    AS `store_order_status_name`,
       `AutoPartsStore`.`store_orders`.`store_order_date` AS `store_order_date`
FROM ((`AutoPartsStore`.`store_orders` JOIN `AutoPartsStore`.`store_orders_statuses` `sos`
       ON ((`AutoPartsStore`.`store_orders`.`store_order_status_id` =
            `sos`.`store_order_status_id`))) JOIN `AutoPartsStore`.`catalogue_view` `cv`
      ON ((`AutoPartsStore`.`store_orders`.`sku_id` = `AutoPartsStore`.`cv`.`sku_id`)));

CREATE
    DEFINER = root@localhost PROCEDURE cash_report_in_date(IN report_date DATE)
BEGIN
    SELECT * FROM cash_report_view WHERE operation_date = report_date;
END;

CREATE
    DEFINER = root@localhost PROCEDURE cash_report_in_period(IN since_date DATE, IN until_date DATE)
BEGIN
    SELECT *
    FROM cash_report_view
    WHERE operation_date BETWEEN since_date AND until_date;
END;

CREATE
    DEFINER = root@localhost PROCEDURE customers_bookings()
BEGIN
    SELECT customer_order_id,
           good_name,
           supplier_name,
           sku_amount,
           sku_amount * store_price,
           customer_order_date
    FROM customers_orders_view
    WHERE customer_order_status_name = 'Заявку прийнято';
END;

CREATE
    DEFINER = root@localhost PROCEDURE good_average_sales_by_months()
BEGIN
    SET @min_date = (SELECT DISTINCT customer_order_date
                     FROM customers_orders_view
                     WHERE customer_order_status_name = 'Оплачено'
                       AND customer_order_date <= ALL (SELECT customer_order_date
                                                       FROM customers_orders_view
                                                       WHERE customer_order_status_name = 'Оплачено'));

    SET @max_date = (SELECT DISTINCT customer_order_date
                     FROM customers_orders_view
                     WHERE customer_order_status_name = 'Оплачено'
                       AND customer_order_date >= ALL (SELECT customer_order_date
                                                       FROM customers_orders_view
                                                       WHERE customer_order_status_name = 'Оплачено'));

    SET @moths = TIMESTAMPDIFF(MONTH, @min_date, @max_date) + 1;

    SELECT good_name, SUM(sku_amount) / @moths
    FROM customers_orders_view
    WHERE customer_order_status_name = 'Оплачено'
    GROUP BY good_name;
END;

CREATE
    DEFINER = root@localhost PROCEDURE good_info(IN supply VARCHAR(30))
BEGIN
    SELECT good_name, supplier_name, supplier_price, store_price, delivery_days
    FROM catalogue_view
    WHERE good_name = supply;
END;

CREATE
    DEFINER = root@localhost PROCEDURE inventory_report()
BEGIN
    SELECT * FROM storage_view;
END;

CREATE
    DEFINER = root@localhost PROCEDURE overheads_part()
BEGIN
    SET @overheads_total =
            (SELECT SUM(overhead_cost)
             FROM overheads);

    SET @sell_total =
            (SELECT SUM((sku_amount - defected_sku_amount) * store_price)
             FROM customers_orders_view
             WHERE customer_order_status_name = 'Оплачено');

    SELECT TRUNCATE(@overheads_total / @sell_total * 100, 3) AS 'Накладні витрати відносно продажів (%)';
END;

CREATE
    DEFINER = root@localhost PROCEDURE sales_by_amount(IN good VARCHAR(30), IN amount INT)
BEGIN
    SELECT customer_order_id, good_name, sku_amount, customer_order_date
    FROM customers_orders_view
    WHERE good_name = good
      AND customers_orders_view.sku_amount >= amount;

    SELECT COUNT(*)
    FROM customers_orders_view
    WHERE good_name = good
      AND sku_amount >= amount;
END;

CREATE
    DEFINER = root@localhost PROCEDURE sales_in_period(IN good VARCHAR(30), IN since_date DATE, IN until_date DATE)
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
END;

CREATE
    DEFINER = root@localhost PROCEDURE sells_in_day(IN sale_day DATE)
BEGIN
    SELECT customer_order_id,
           good_name,
           supplier_name,
           sku_amount,
           defected_sku_amount,
           result_sku_amount * store_price AS Sum
    FROM customers_orders_view
    WHERE customer_order_date = sale_day
      AND customer_order_status_name = 'Оплачено';
END;

CREATE
    DEFINER = root@localhost PROCEDURE storage_free_space()
BEGIN
    SELECT SUM(cell_capacity - sku_amount) FROM storage_view;
END;

CREATE
    DEFINER = root@localhost PROCEDURE storage_info()
BEGIN
    SELECT cell_id, good_name, supplier_name, cell_capacity
FROM storage_view;
END;

CREATE
    DEFINER = root@localhost PROCEDURE suppliers_by_defected_sku(IN since_date DATE, IN until_date DATE)
BEGIN
    SELECT good_name, supplier_name, SUM(defected_sku_amount) AS defected
    FROM customers_orders_view
    WHERE customer_order_status_name = 'Оплачено'
      AND customer_order_date BETWEEN since_date AND until_date
    GROUP BY sku_id
    HAVING defected != 0;
END;

CREATE
    DEFINER = root@localhost PROCEDURE suppliers_by_good(IN good VARCHAR(30), IN supplier VARCHAR(30))
BEGIN
    SELECT supplier_name
    FROM catalogue_view
    WHERE good_name = good
      AND supplier_category_name = supplier;

    SELECT COUNT(*)
    FROM catalogue_view
    WHERE good_name = good
      AND supplier_category_name = supplier;
END;

CREATE
    DEFINER = root@localhost PROCEDURE suppliers_by_good_in_period(IN supply VARCHAR(30), IN partner VARCHAR(30),
                                                                   IN amount INT, IN since_date DATE,
                                                                   IN until_date DATE)
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
END;

CREATE
    DEFINER = root@localhost PROCEDURE suppliers_part(IN supplier VARCHAR(30), IN since_date DATE, IN until_date DATE)
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
END;

CREATE
    DEFINER = root@localhost PROCEDURE ten_best_sold_goods()
BEGIN
    SELECT good_name, SUM(sku_amount) as sum
    FROM customers_orders_view
    WHERE customer_order_status_name = 'Оплачено'
    GROUP BY good_name
    ORDER BY sum DESC
    LIMIT 10;
END;

CREATE
    DEFINER = root@localhost PROCEDURE ten_cheapest_suppliers_by_good(IN good VARCHAR(30))
BEGIN
    SELECT supplier_name, supplier_price
    FROM catalogue_view
    WHERE good_name = good
    ORDER BY supplier_price
    LIMIT 10;
END;

CREATE
    DEFINER = root@localhost PROCEDURE total_cash_report_in_date(IN report_date DATE)
BEGIN
    SET @total_store_purchase = (SELECT SUM(store_purchase) FROM cash_report_view WHERE operation_date = report_date);
    SET @total_customers_purchase =
            (SELECT SUM(customers_purchase) FROM cash_report_view WHERE operation_date = report_date);

    SELECT TRUNCATE(@total_store_purchase, 0), TRUNCATE(@total_customers_purchase, 0);
END;

CREATE
    DEFINER = root@localhost PROCEDURE total_cash_report_in_period(IN since_date DATE, IN until_date DATE)
BEGIN
    SET @total_store_purchase =
            (SELECT SUM(store_purchase) FROM cash_report_view WHERE operation_date BETWEEN since_date AND until_date);
    SET @total_customers_purchase = (SELECT SUM(customers_purchase)
                                     FROM cash_report_view
                                     WHERE operation_date BETWEEN since_date AND until_date);

    SELECT TRUNCATE(@total_store_purchase, 0), TRUNCATE(@total_customers_purchase, 0);
END;

CREATE
    DEFINER = root@localhost PROCEDURE total_customers_bookings()
BEGIN
    SET @total_bookings =
            (SELECT COUNT(*)
             FROM customers_orders_view
             WHERE customer_order_status_name = 'Заявку прийнято');

    SET @total_sum =
            (SELECT SUM(sku_amount * store_price)
             FROM customers_orders_view
             WHERE customer_order_status_name = 'Заявку прийнято');

    SELECT @total_bookings, TRUNCATE(@total_sum, 0);
END;

CREATE
    DEFINER = root@localhost PROCEDURE total_defected_sku(IN since_date DATE, IN until_date DATE)
BEGIN
    SET @total_defected = (SELECT SUM(defected)
                           FROM (SELECT SUM(defected_sku_amount) AS defected
                                 FROM customers_orders_view
                                 WHERE customer_order_status_name = 'Оплачено'
                                   AND customer_order_date BETWEEN since_date AND until_date
                                 GROUP BY sku_id) query);
    SELECT TRUNCATE(@total_defected, 0) AS 'Товарів з дефектами всього';
END;

CREATE
    DEFINER = root@localhost PROCEDURE total_sells_in_day(IN sale_day DATE)
BEGIN
        SET @total_revenue =
            (SELECT SUM(result_sku_amount * store_price)
             FROM customers_orders_view
             WHERE customer_order_date = sale_day
               AND customer_order_status_name = 'Оплачено');

    SET @total_amount =
            (SELECT SUM(result_sku_amount)
             FROM customers_orders_view
             WHERE customer_order_date = sale_day
               AND customer_order_status_name = 'Оплачено');

    SELECT TRUNCATE(@total_amount, 0), TRUNCATE(@total_revenue, 0);
END;

CREATE
    DEFINER = root@localhost PROCEDURE unsold_goods()
BEGIN
    SET @unsold = (SELECT SUM(sku_amount)
                   FROM storage_view);

    SET @total_ordered = (SELECT SUM(sku_amount)
                          FROM store_orders_view
                          WHERE store_order_status_name = 'Прийнято');

    SELECT TRUNCATE(@unsold / @total_ordered * 100, 3) AS 'Частка нереалізованого товару товару (%)',
           CONCAT(@unsold, '/', @total_ordered)        AS 'Частка нереалізованого товару (в од.)';
END;

CREATE
    DEFINER = root@localhost PROCEDURE velocity_of_good(IN good VARCHAR(20), IN since_date DATE, IN until_date DATE)
BEGIN
    SET @total_good_profit = (SELECT SUM(result_sku_amount * store_price)
                              FROM customers_orders_view
                              WHERE good_name = good
                                AND customer_order_date BETWEEN since_date AND until_date);

    SET @average_reserve = (SELECT SUM(sku_amount * store_price) / 2
                            FROM inventory_reports_view
                                     INNER JOIN catalogue c ON inventory_reports_view.sku_id = c.sku_id
                            WHERE good_name = good
                              AND (inventory_report_date = since_date OR inventory_report_date = until_date));

    SELECT @total_good_profit, @average_reserve;

    SELECT TRUNCATE(@total_good_profit / @average_reserve, 2);
END;


