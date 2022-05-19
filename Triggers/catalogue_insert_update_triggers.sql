USE AutoPartsStore;

DROP TRIGGER IF EXISTS insert_catalogue;
DROP TRIGGER IF EXISTS update_catalogue;

DELIMITER $$;
CREATE TRIGGER insert_catalogue
    BEFORE INSERT
    ON catalogue
    FOR EACH ROW
BEGIN
    SET NEW.store_price = NEW.supplier_price * 1.2;
END $$;

DELIMITER $$;
CREATE TRIGGER update_catalogue
    BEFORE UPDATE
    ON catalogue
    FOR EACH ROW
BEGIN
    IF OLD.store_price = 0 THEN
        SET NEW.store_price = NEW.supplier_price * 1.2;
    END IF;
END $$;