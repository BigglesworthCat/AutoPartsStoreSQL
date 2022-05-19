USE AutoPartsStore;

CREATE OR REPLACE VIEW storage_view
AS
SELECT cell_id,
       storage.sku_id,
       good_name,
       supplier_name,
       supplier_category_name,
       sku_amount,
       cell_capacity,
       replenishment_date
FROM storage
INNER JOIN catalogue_view cv ON storage.sku_id = cv.sku_id;