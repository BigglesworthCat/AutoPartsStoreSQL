USE AutoPartsStore;

DROP PROCEDURE IF EXISTS cash_report_in_date;
DROP PROCEDURE IF EXISTS total_cash_report_in_date;
DROP PROCEDURE IF EXISTS cash_report_in_period;
DROP PROCEDURE IF EXISTS total_cash_report_in_period;

DELIMITER $$;
CREATE PROCEDURE cash_report_in_date(IN report_date DATE)
BEGIN
    SELECT * FROM cash_report_view WHERE operation_date = report_date;
END $$;

DELIMITER $$;
CREATE PROCEDURE total_cash_report_in_date(IN report_date DATE)
BEGIN
    SET @total_store_purchase = (SELECT SUM(store_purchase) FROM cash_report_view WHERE operation_date = report_date);
    SET @total_customers_purchase =
            (SELECT SUM(customers_purchase) FROM cash_report_view WHERE operation_date = report_date);

    SELECT TRUNCATE(@total_store_purchase, 0), TRUNCATE(@total_customers_purchase, 0);
END $$;

DELIMITER $$;
CREATE PROCEDURE cash_report_in_period(IN since_date DATE, IN until_date DATE)
BEGIN
    SELECT *
    FROM cash_report_view
    WHERE operation_date BETWEEN since_date AND until_date;
END $$;

CREATE PROCEDURE total_cash_report_in_period(IN since_date DATE, IN until_date DATE)
BEGIN
    SET @total_store_purchase =
            (SELECT SUM(store_purchase) FROM cash_report_view WHERE operation_date BETWEEN since_date AND until_date);
    SET @total_customers_purchase = (SELECT SUM(customers_purchase)
                                     FROM cash_report_view
                                     WHERE operation_date BETWEEN since_date AND until_date);

    SELECT TRUNCATE(@total_store_purchase, 0), TRUNCATE(@total_customers_purchase, 0);
END $$;

CALL cash_report_in_date('2022-01-01');
CALL total_cash_report_in_date('2022-01-01');
CALL cash_report_in_period('2022-01-01', NOW());
CALL total_cash_report_in_period('2022-01-01', NOW());