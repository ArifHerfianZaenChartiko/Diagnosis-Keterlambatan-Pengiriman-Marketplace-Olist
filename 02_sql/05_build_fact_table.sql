-- ============================================
-- 05_build_fact_table.sql
-- Tujuan : Membangun analytics.fact_order_delivery
-- Bentuk : VIEW (bukan tabel fisik) - tidak menyalin data,
--          otomatis ikut kalau data sumber berubah.
-- Grain  : SATU BARIS = SATU PESANAN (order_id unik)
--
-- Batasan yang diterapkan (dasar: 04_data_quality_audit.sql):
--   1. Hanya order_status = 'delivered' DAN tanggal terima terisi -> 96.470 pesanan
--   2. Waktu tahapan dihitung dari tanggal BELI, bukan tanggal disetujui,
--      karena 1.359 pesanan tercatat ke kurir sebelum disetujui (Temuan #2)
--   3. Skor ulasan diambil dari ULASAN TERBARU per pesanan
--      (547 pesanan berulasan ganda, 202 di antaranya skornya berbeda)
--   4. Periode analisis Jan 2017 - Ags 2018 ditandai kolom in_analysis_period
--   5. 23 pesanan dengan urutan tanggal mustahil ditandai has_sequence_anomaly
-- ============================================

CREATE OR REPLACE VIEW analytics.fact_order_delivery AS

-- Ringkas dulu tabel item ke tingkat pesanan,
-- supaya join tidak menggandakan baris (1 pesanan bisa berisi banyak barang).
WITH item_agg AS (
    SELECT order_id,
           COUNT(*)                  AS item_count,
           COUNT(DISTINCT seller_id) AS seller_count,
           SUM(price)                AS order_value,
           SUM(freight_value)        AS freight_value
    FROM raw.order_items
    GROUP BY order_id
),

-- DISTINCT ON: ambil satu baris per order_id, yaitu baris teratas setelah diurutkan.
-- Urutannya tanggal ulasan terbaru dulu, jadi yang terambil adalah ulasan paling akhir.
latest_review AS (
    SELECT DISTINCT ON (order_id)
           order_id,
           review_score
    FROM raw.order_reviews
    ORDER BY order_id,
             review_creation_date DESC,
             review_answer_timestamp DESC
)

SELECT
    o.order_id,
    o.customer_id,
    c.customer_state,
    c.customer_city,

    o.order_purchase_timestamp      AS purchase_ts,
    o.order_delivered_carrier_date  AS carrier_ts,
    o.order_delivered_customer_date AS delivered_ts,
    o.order_estimated_delivery_date AS estimated_ts,

    -- EXTRACT(EPOCH FROM selisih) / 86400 = ubah selisih waktu menjadi satuan HARI
    ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))      / 86400.0, 2) AS lead_time_days,
    ROUND(EXTRACT(EPOCH FROM (o.order_delivered_carrier_date  - o.order_purchase_timestamp))      / 86400.0, 2) AS handover_days,
    ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date))  / 86400.0, 2) AS transit_days,
    ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400.0, 2) AS delay_days,

    (o.order_delivered_customer_date > o.order_estimated_delivery_date) AS is_late,

    i.item_count,
    i.seller_count,
    i.order_value,
    i.freight_value,
    r.review_score,

    (o.order_purchase_timestamp >= '2017-01-01'
     AND o.order_purchase_timestamp <  '2018-09-01') AS in_analysis_period,

    -- COALESCE -> FALSE: 1 pesanan tanpa tanggal serah kurir menghasilkan NULL,
    -- dan NULL itu bukan anomali, hanya data tidak lengkap.
    COALESCE(o.order_delivered_customer_date < o.order_delivered_carrier_date, FALSE) AS has_sequence_anomaly

FROM raw.orders o
JOIN      raw.customers c ON c.customer_id = o.customer_id
LEFT JOIN item_agg      i ON i.order_id    = o.order_id
LEFT JOIN latest_review r ON r.order_id    = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;



SELECT COUNT(*) AS total_baris,
       COUNT(*) FILTER (WHERE in_analysis_period)   AS dalam_periode,
       COUNT(*) FILTER (WHERE has_sequence_anomaly) AS anomali_urutan,
       COUNT(*) FILTER (WHERE review_score IS NULL) AS tanpa_ulasan
FROM analytics.fact_order_delivery;