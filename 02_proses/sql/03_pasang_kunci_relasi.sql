-- ============================================
-- 03_add_constraints.sql
-- Tujuan  : Memasang PRIMARY KEY & FOREIGN KEY setelah data masuk
-- Alasan  : Constraint dipasang belakangan supaya FOREIGN KEY
--           berfungsi sebagai UJI INTEGRITAS data, bukan penghalang impor.
-- ============================================

-- Cek kandidat yang akan dijadikan PRIMARY KEY (Unik)
SELECT 'customers.customer_id' AS kandidat,
       COUNT(*) AS total_baris,
       COUNT(DISTINCT customer_id) AS nilai_berbeda
FROM raw.customers

UNION ALL
SELECT 'sellers.seller_id', COUNT(*), COUNT(DISTINCT seller_id)
FROM raw.sellers

UNION ALL
SELECT 'products.product_id', COUNT(*), COUNT(DISTINCT product_id)
FROM raw.products

UNION ALL
SELECT 'orders.order_id', COUNT(*), COUNT(DISTINCT order_id)
FROM raw.orders

UNION ALL
SELECT 'translation.category', COUNT(*), COUNT(DISTINCT product_category_name)
FROM raw.product_category_name_translation

UNION ALL
SELECT 'order_items.order_id', COUNT(*), COUNT(DISTINCT order_id)
FROM raw.order_items

UNION ALL
SELECT 'order_reviews.review_id', COUNT(*), COUNT(DISTINCT review_id)
FROM raw.order_reviews;

/*
Ada beberapa masalah karena terdapat SELISIH sehingga tidak bisa dijadikan PK (Tidak Unik)
-- Kolom order_id di tabel order_items terdapat SELISH, masalah jika dijadikan kandidat PK
-- Kolom riview_id di tabel order_riviews terdapaat SELISIH, masalah jika dijadikan kandidat pk
*/

-- ada kandidat yang kayanya unik untuk PK yaitu kombinasi order_id & order_item_id, di test dulu
SELECT COUNT(*) AS total_baris,
       COUNT(DISTINCT (order_id, order_item_id)) AS kombinasi_berbeda
FROM raw.order_items;
-- LOLOS

-- Coba cek kandidat lain untuk kolom reviews_id di tabel order_riviews
SELECT review_id, COUNT(*) AS jumlah
FROM raw.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
LIMIT 5;

-- Masukkan 1 sample output untuk test
SELECT *
FROM raw.order_reviews
WHERE review_id = '00130cbe1f9d422698c812ed8ded1919';

-- ada kandidat cocok yaitu kombinasi review_id & order_id
SELECT COUNT(*) AS total_baris,
       COUNT(DISTINCT (review_id, order_id)) AS kombinasi_berbeda
FROM raw.order_reviews;
--LOLOS


-- ---------- PRIMARY KEY ----------
-- Dasar penetapan: sudah diuji dengan membandingkan COUNT(*) vs COUNT(DISTINCT ...)

ALTER TABLE raw.customers
    ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id);

ALTER TABLE raw.sellers
    ADD CONSTRAINT pk_sellers PRIMARY KEY (seller_id);

ALTER TABLE raw.products
    ADD CONSTRAINT pk_products PRIMARY KEY (product_id);

ALTER TABLE raw.orders
    ADD CONSTRAINT pk_orders PRIMARY KEY (order_id);

ALTER TABLE raw.product_category_name_translation
    ADD CONSTRAINT pk_category PRIMARY KEY (product_category_name);

-- Gabungan 2 kolom: satu baris = satu barang di dalam satu pesanan
ALTER TABLE raw.order_items
    ADD CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id);

-- Gabungan 2 kolom: satu ulasan bisa menempel ke beberapa pesanan
ALTER TABLE raw.order_reviews
    ADD CONSTRAINT pk_order_reviews PRIMARY KEY (review_id, order_id);


-- ---------- FOREIGN KEY ----------
-- Jalankan SATU PER SATU. Kalau ada yang gagal, itu temuan kualitas data.

ALTER TABLE raw.orders
    ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES raw.customers(customer_id);

ALTER TABLE raw.order_items
    ADD CONSTRAINT fk_items_order
    FOREIGN KEY (order_id) REFERENCES raw.orders(order_id);

ALTER TABLE raw.order_items
    ADD CONSTRAINT fk_items_product
    FOREIGN KEY (product_id) REFERENCES raw.products(product_id);

ALTER TABLE raw.order_items
    ADD CONSTRAINT fk_items_seller
    FOREIGN KEY (seller_id) REFERENCES raw.sellers(seller_id);

ALTER TABLE raw.order_reviews
    ADD CONSTRAINT fk_reviews_order
    FOREIGN KEY (order_id) REFERENCES raw.orders(order_id);

ALTER TABLE raw.products
    ADD CONSTRAINT fk_products_category      -- ERROR
    FOREIGN KEY (product_category_name)
    REFERENCES raw.product_category_name_translation(product_category_name);

-- Pembenahan error raw.products
--1. Cari semua kategori yang tidak ada di kamus
SELECT DISTINCT product_category_name
FROM raw.products
WHERE product_category_name IS NOT NULL
  AND product_category_name NOT IN (
      SELECT product_category_name
      FROM raw.product_category_name_translation
);

--2. Hitung dampak
SELECT COUNT(*) AS produk_terdampak
FROM raw.products
WHERE product_category_name IN ('pc_gamer', 'portateis_cozinha_e_preparadores_de_alimentos');
-- Terdampak 13 produk


-- Langkah penyelesaian yang diambil -> Lengkapi kamusnya (Data asli utuh, hubungan antar tabel jadi valid)
INSERT INTO raw.product_category_name_translation
    (product_category_name, product_category_name_english)
VALUES
    ('pc_gamer', 'pc_gamer'),
    ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_food_preparers');

-- Cek jumlahnya sekarang 73 (sebelumnya 71)
SELECT COUNT(*) FROM raw.product_category_name_translation;

-- Ulangi FOREIGN KEY yang tadi gagal
ALTER TABLE raw.products
    ADD CONSTRAINT fk_products_category
    FOREIGN KEY (product_category_name)
    REFERENCES raw.product_category_name_translation(product_category_name);