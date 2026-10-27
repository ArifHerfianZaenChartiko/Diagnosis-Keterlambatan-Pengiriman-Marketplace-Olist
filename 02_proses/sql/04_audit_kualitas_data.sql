-- ============================================
-- 04_data_quality_audit.sql
-- Tujuan : Memeriksa kesehatan data sebelum analisis
-- ============================================


-- AUDIT 1: Sebaran status pesanan
-- Menentukan berapa pesanan yang layak dianalisis (hanya 'delivered').
SELECT order_status, COUNT(*) AS jumlah
FROM raw.orders
GROUP BY order_status
ORDER BY jumlah DESC;


-- AUDIT 2: Tanggal yang kosong
-- COUNT(*) FILTER (WHERE ...) artinya: hitung baris yang memenuhi syarat itu saja.
SELECT COUNT(*) AS total_pesanan,
       COUNT(*) FILTER (WHERE order_approved_at IS NULL)             AS disetujui_kosong,
       COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL)  AS ke_kurir_kosong,
       COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS terkirim_kosong
FROM raw.orders;


-- AUDIT 3: Rentang waktu data
SELECT MIN(order_purchase_timestamp) AS paling_awal,
       MAX(order_purchase_timestamp) AS paling_akhir
FROM raw.orders;


-- AUDIT 4: Urutan tanggal yang tidak masuk akal
-- Alur normal: dibeli -> disetujui -> diserahkan ke kurir -> diterima pelanggan
SELECT COUNT(*) FILTER (WHERE order_delivered_carrier_date < order_approved_at)
           AS ke_kurir_sebelum_disetujui,
       COUNT(*) FILTER (WHERE order_delivered_customer_date < order_delivered_carrier_date)
           AS terkirim_sebelum_ke_kurir,
       COUNT(*) FILTER (WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL)
           AS delivered_tanpa_tanggal,
       COUNT(*) FILTER (WHERE order_status <> 'delivered' AND order_delivered_customer_date IS NOT NULL)
           AS bukan_delivered_tapi_terkirim
FROM raw.orders;


-- AUDIT 5: Pesanan yang punya lebih dari satu ulasan
-- Penting untuk Q5: satu pesanan harus punya satu skor, bukan dua.
SELECT COUNT(*) AS pesanan_banyak_ulasan
FROM (
    SELECT order_id
    FROM raw.order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS x;

/*
TEMUAN
1. 1.359 pesanan diserahkan ke kurir sebelum pembayaran disetujui.
   Secara alur seharusnya mustahil: barang tidak dikirim sebelum bayar.
   Dua kemungkinan: pencatatan persetujuan pembayaran dilakukan menyusul (bukan saat kejadian), atau penjual mengirim duluan sambil menunggu. Yang mana pun, tanggal order_approved_at tidak bisa dipercaya penuh.
   Keputusan: hitung waktu tahapan dari order_purchase_timestamp (waktu beli), bukan dari order_approved_at. Tahap approval kita catat sebagai temuan, tapi tidak dijadikan dasar perhitungan.

2. 23 pesanan diterima pelanggan sebelum diserahkan ke kurir
   Ini mustahil secara fisik. Murni salah catat.
   Keputusan: kecualikan dari analisis tahapan (0,02% — dampaknya nihil), tapi catat di laporan.

3. 8 pesanan berstatus delivered tapi tanpa tanggal terima
   Statusnya bilang sampai, tanggalnya tidak ada. Tidak bisa dihitung tepat/telat.
   Keputusan: populasi analisis = status delivered DAN tanggal terima terisi → 96.470 pesanan.

4. 6 pesanan berstatus canceled tapi punya tanggal terima
   Kecil, dan sudah otomatis terkecualikan karena kita hanya ambil delivered. Cukup dicatat.
*/

-- AUDIT 6: Dari pesanan berulasan ganda, berapa yang skornya berbeda?
SELECT COUNT(*) AS skor_berbeda
FROM (
    SELECT order_id
    FROM raw.order_reviews
    GROUP BY order_id
    HAVING COUNT(DISTINCT review_score) > 1
) AS x;