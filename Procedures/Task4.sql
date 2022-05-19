USE AutoPartsStore;

DROP PROCEDURE IF EXISTS storage_info;

DELIMITER $$;
CREATE PROCEDURE storage_info()
BEGIN
    SELECT cell_id, good_name, supplier_name, cell_capacity
FROM storage_view;
END $$;

CALL storage_info();