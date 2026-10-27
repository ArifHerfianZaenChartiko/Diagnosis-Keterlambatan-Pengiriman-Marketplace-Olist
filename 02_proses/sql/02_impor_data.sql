-- ============================================
-- 02_impor_data.sql
-- Tujuan   : Impor 7 CSV ke skema raw
-- PENTING  : Jalankan lewat psql, BUKAN jendela Query Tool di pgAdmin.
--            \copy adalah perintah klien psql, bukan SQL.
-- Cara     : jalankan dari folder utama proyek (path CSV di bawah relatif ke sana)
--            psql -U postgres -d olist_ops -f 02_proses/sql/02_impor_data.sql
-- Catatan  : Urutan bebas karena kunci relasi belum dipasang.
-- ============================================

-- Perintah impor lewat psql
\copy raw.customers FROM '01_data_dan_pertanyaan/data_mentah/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.sellers FROM '01_data_dan_pertanyaan/data_mentah/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.products FROM '01_data_dan_pertanyaan/data_mentah/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.orders FROM '01_data_dan_pertanyaan/data_mentah/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.order_items FROM '01_data_dan_pertanyaan/data_mentah/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.order_reviews FROM '01_data_dan_pertanyaan/data_mentah/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.product_category_name_translation FROM '01_data_dan_pertanyaan/data_mentah/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true)


-- Validasi sudah terimpor atau belum (cek jumlah barisnya juga)
SELECT 'customers'   AS tabel, COUNT(*) AS jumlah FROM raw.customers
UNION ALL SELECT 'sellers',      COUNT(*) FROM raw.sellers
UNION ALL SELECT 'products',     COUNT(*) FROM raw.products
UNION ALL SELECT 'orders',       COUNT(*) FROM raw.orders
UNION ALL SELECT 'order_items',  COUNT(*) FROM raw.order_items
UNION ALL SELECT 'order_reviews',COUNT(*) FROM raw.order_reviews
UNION ALL SELECT 'translation',  COUNT(*) FROM raw.product_category_name_translation
ORDER BY tabel;