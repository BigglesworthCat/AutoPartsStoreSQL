USE AutoPartsStore;

CREATE OR REPLACE VIEW inventory_reports_view
AS
SELECT inventory_report_date,
       inventory_reports.sku_id,
       good_name,
       supplier_name,
       sku_amount
FROM inventory_reports
INNER JOIN catalogue_view cv ON inventory_reports.sku_id = cv.sku_id