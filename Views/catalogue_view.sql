USE AutoPartsStore;

CREATE OR REPLACE VIEW catalogue_view
AS
SELECT sku_id, good_name, supplier_name, supplier_category_name, supplier_price, store_price, delivery_days
FROM catalogue
INNER JOIN goods g ON catalogue.good_id = g.good_id
INNER JOIN suppliers s ON catalogue.supplier_id = s.supplier_id
INNER JOIN suppliers_categories sc ON s.supplier_category_id = sc.supplier_category_id;