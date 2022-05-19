USE AutoPartsStore;

DROP PROCEDURE IF EXISTS storage_free_space;

DELIMITER $$;
CREATE PROCEDURE storage_free_space()
BEGIN
    SELECT SUM(cell_capacity - sku_amount) FROM storage_view;
END $$;

CALL storage_free_space();