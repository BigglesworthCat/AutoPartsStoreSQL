USE AutoPartsStore;

DROP PROCEDURE IF EXISTS inventory_report;

DELIMITER $$;
CREATE PROCEDURE inventory_report()
BEGIN
    SELECT * FROM storage_view;
END $$;

CALL inventory_report();