-- =============================================================================
-- 01_create_schema.sql
-- Tujuan    : Membuat skema raw & analytics + 7 tabel sumber
-- Sumber    : 01_data_raw/*.csv (Olist, Sep 2016 - Okt 2018)
-- Prasyarat : CREATE DATABASE olist_ops;  (dijalankan di database postgres)
-- Catatan   : Constraint sengaja belum dipasang. Lihat 03_add_constraints.sql
--             NOT NULL tidak dipakai karena data sumber banyak yang kosong.
-- =============================================================================

-- Membuat database olist_ops (jalankan di database postgres)
CREATE DATABASE olist_ops;

-- Pindah ke database olist_ops

-- Membuat skema raw dan analytics untuk pemisahan data mentah dan diolah
CREATE SCHEMA raw;
CREATE SCHEMA analytics;

-- Membuat Tabel data raw
-- 1. Pelanggan
CREATE TABLE raw.customers (
    customer_id               VARCHAR(32),
    customer_unique_id        VARCHAR(32),
    customer_zip_code_prefix  VARCHAR(5),
    customer_city             VARCHAR(60),
    customer_state            VARCHAR(2)
);

-- 2. Penjual
CREATE TABLE raw.sellers (
    seller_id                 VARCHAR(32),
    seller_zip_code_prefix    VARCHAR(5),
    seller_city               VARCHAR(60),
    seller_state              VARCHAR(2)
);

-- 3. Produk
-- Catatan: 'lenght' memang salah eja di data aslinya, sengaja dipertahankan.
CREATE TABLE raw.products (
    product_id                  VARCHAR(32),
    product_category_name       VARCHAR(60),
    product_name_lenght         INTEGER,
    product_description_lenght  INTEGER,
    product_photos_qty          INTEGER,
    product_weight_g            INTEGER,
    product_length_cm           INTEGER,
    product_height_cm           INTEGER,
    product_width_cm            INTEGER
);

-- 4. Pesanan - tabel inti analisis operasional
CREATE TABLE raw.orders (
    order_id                       VARCHAR(32),
    customer_id                    VARCHAR(32),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       TIMESTAMP,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP
);

-- 5. Item pesanan - satu pesanan bisa berisi banyak baris
CREATE TABLE raw.order_items (
    order_id             VARCHAR(32),
    order_item_id        INTEGER,
    product_id           VARCHAR(32),
    seller_id            VARCHAR(32),
    shipping_limit_date  TIMESTAMP,
    price                NUMERIC(10,2),
    freight_value        NUMERIC(10,2)
);

-- 6. Ulasan pelanggan
-- Kolom komentar dipakai TEXT karena panjangnya tidak terbatas.
CREATE TABLE raw.order_reviews (
    review_id                VARCHAR(32),
    order_id                 VARCHAR(32),
    review_score             INTEGER,
    review_comment_title     TEXT,
    review_comment_message   TEXT,
    review_creation_date     TIMESTAMP,
    review_answer_timestamp  TIMESTAMP
);

-- 7. Kamus kategori produk (Portugis -> Inggris)
CREATE TABLE raw.product_category_name_translation (
    product_category_name          VARCHAR(60),
    product_category_name_english  VARCHAR(60)
);