-- ============================================
-- 07_build_seller_view.sql
-- Tujuan : View kinerja penjual untuk halaman Pareto di Power BI
-- Grain  : SATU BARIS = SATU PENJUAL
-- Catatan: Sengaja diringkas per penjual (bukan per pesanan) supaya
--          Power BI tidak berisiko menghitung ganda pesanan yang
--          melibatkan lebih dari satu penjual.
-- ============================================

CREATE OR REPLACE VIEW analytics.dim_seller_performance AS
SELECT s.seller_id,
       s.seller_state,
       s.seller_city,
       COUNT(*)                                                     AS total_pesanan,
       COUNT(*) FILTER (WHERE f.is_late)                            AS pesanan_telat,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_late) / COUNT(*), 2) AS persen_telat
FROM analytics.fact_order_delivery f
JOIN (SELECT DISTINCT order_id, seller_id FROM raw.order_items) i
     ON i.order_id = f.order_id
JOIN raw.sellers s
     ON s.seller_id = i.seller_id
WHERE f.in_analysis_period
  AND NOT f.has_sequence_anomaly
GROUP BY s.seller_id, s.seller_state, s.seller_city;



SELECT COUNT(*) AS jumlah_penjual,
       SUM(pesanan_telat) AS total_pesanan_telat
FROM analytics.dim_seller_performance;