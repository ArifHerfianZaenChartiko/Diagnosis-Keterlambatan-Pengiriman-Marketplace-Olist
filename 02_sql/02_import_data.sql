-- ============================================
-- 02_import_data.sql
-- Tujuan   : Impor 7 CSV ke skema raw
-- PENTING  : Jalankan lewat psql, BUKAN Query Tool pgAdmin.
--            \copy adalah perintah klien psql, bukan SQL.
-- Cara     : psql -U postgres -d olist_ops -f "path\ke\02_import_data.sql"
-- Catatan  : Urutan bebas karena constraint belum dipasang.
-- ============================================

-- Query lewat psql
\copy raw.customers FROM 'C:/Users/msibr/OneDrive/Data Analyst/10. Portofolio/Project 1/01_data_raw/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.sellers FROM 'C:/Users/msibr/OneDrive/Data Analyst/10. Portofolio/Project 1/01_data_raw/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.products FROM 'C:/Users/msibr/OneDrive/Data Analyst/10. Portofolio/Project 1/01_data_raw/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.orders FROM 'C:/Users/msibr/OneDrive/Data Analyst/10. Portofolio/Project 1/01_data_raw/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.order_items FROM 'C:/Users/msibr/OneDrive/Data Analyst/10. Portofolio/Project 1/01_data_raw/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.order_reviews FROM 'C:/Users/msibr/OneDrive/Data Analyst/10. Portofolio/Project 1/01_data_raw/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.product_category_name_translation FROM 'C:/Users/msibr/OneDrive/Data Analyst/10. Portofolio/Project 1/01_data_raw/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true)


-- Validasi sudah terimport atau belum (cek jumlah barisnya juga)
SELECT 'customers'   AS tabel, COUNT(*) AS jumlah FROM raw.customers
UNION ALL SELECT 'sellers',      COUNT(*) FROM raw.sellers
UNION ALL SELECT 'products',     COUNT(*) FROM raw.products
UNION ALL SELECT 'orders',       COUNT(*) FROM raw.orders
UNION ALL SELECT 'order_items',  COUNT(*) FROM raw.order_items
UNION ALL SELECT 'order_reviews',COUNT(*) FROM raw.order_reviews
UNION ALL SELECT 'translation',  COUNT(*) FROM raw.product_category_name_translation
ORDER BY tabel;