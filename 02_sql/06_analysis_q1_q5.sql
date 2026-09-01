-- ============================================
-- 06_analysis_q1_q5.sql
-- Tujuan : Menjawab 5 pertanyaan bisnis case study
-- Sumber : analytics.fact_order_delivery
-- Filter  : in_analysis_period = true (Jan 2017 - Ags 2018, 96.203 pesanan)
-- ============================================


-- ============================================
-- Q1: SEBERAPA PARAH KETERLAMBATANNYA?
-- ============================================

-- Q1a. Angka dasar
SELECT COUNT(*)                                                        AS total_pesanan,
       COUNT(*) FILTER (WHERE is_late)                                 AS pesanan_telat,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / COUNT(*), 2)    AS persen_telat,
       ROUND(100.0 * COUNT(*) FILTER (WHERE NOT is_late) / COUNT(*), 2) AS otd_rate,
       ROUND(AVG(delay_days) FILTER (WHERE is_late), 2)                AS rata2_hari_telat,
       ROUND(MAX(delay_days), 2)                                       AS telat_terparah,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lead_time_days)::numeric, 2) AS median_lead_time
FROM analytics.fact_order_delivery
WHERE in_analysis_period;

-- Q1b. Tren bulanan
-- DATE_TRUNC('month', tanggal) = potong tanggal jadi awal bulannya,
-- supaya semua pesanan di bulan yang sama masuk satu kelompok.
SELECT DATE_TRUNC('month', purchase_ts)::date                       AS bulan,
       COUNT(*)                                                      AS total_pesanan,
       COUNT(*) FILTER (WHERE is_late)                               AS pesanan_telat,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / COUNT(*), 2)  AS persen_telat
FROM analytics.fact_order_delivery
WHERE in_analysis_period
GROUP BY 1
ORDER BY 1;

-- Q1c
SELECT ROUND(AVG(delay_days), 2) AS rata2,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delay_days)::numeric, 2) AS median
FROM analytics.fact_order_delivery
WHERE in_analysis_period AND NOT has_sequence_anomaly AND is_late;

/* KESIMPULAN Q1 - Seberapa parah?

   - Dari 96.203 pesanan (Jan 2017 - Ags 2018), 7.822 telat (8,13%).
     OTD Rate = 91,87%.
   - Sekali telat, telatnya jauh: rata-rata 9,55 hari, terparah 188,98 hari.
     Waktu kirim normal (median) 10,21 hari.
   - Tidak merata sepanjang waktu. Baseline 3-5%, tapi ada 3 bulan kritis:
       Nov 2017 = 14,31%  |  Feb 2018 = 15,99%  |  Mar 2018 = 21,36%
     Terbaik Jun 2018 = 1,36%.
   - Nov 2017 diikuti lonjakan volume +63% (4.478 -> 7.288) = masalah kapasitas
     Black Friday. Feb-Mar 2018 volumenya NORMAL tapi telatnya lebih parah,
     jadi BUKAN masalah kapasitas.
   - Sejak Apr 2018 kinerja membaik dan bertahan.

   Implikasi: dua krisis, dua penyebab berbeda. Dibongkar di Q2.
*/

/* KESIMPULAN Q1c - Sebaran keterlambatan
   - Rata-rata telat 9,55 hari, tapi median hanya 5,81 hari.
   - Selisih 3,74 hari membuktikan sebarannya miring: separuh pesanan telat
     meleset <= 5,81 hari, sementara segelintir kasus ekstrem (terparah
     188,98 hari) menarik rata-rata jauh ke atas.
   - Median 5,81 hari jatuh di kelompok "telat 4-7 hari" (Q5b), yaitu titik
     di mana ulasan 1-2 bintang melonjak dari 19,22% ke 61,29%.
     Artinya keterlambatan yang khas pun SUDAH cukup parah untuk merusak
     kepuasan pelanggan - bukan cuma kasus ekstremnya.
   - Kedua angka dilaporkan bersama: rata-rata untuk menaksir total beban,
     median untuk menggambarkan pengalaman pelanggan pada umumnya.
*/



-- ============================================
-- Q2: DI TAHAP MANA KETERLAMBATAN TERJADI?
-- Tahapan: (1) beli -> ke kurir   (2) kurir -> pelanggan
-- 23 pesanan berurutan tanggal mustahil dikecualikan.
-- ============================================

-- Q2a. Bandingkan pesanan telat vs tepat waktu
SELECT is_late,
       COUNT(*) AS jumlah_pesanan,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY handover_days)::numeric,  2) AS median_ke_kurir,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY transit_days)::numeric,   2) AS median_transit,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lead_time_days)::numeric, 2) AS median_total
FROM analytics.fact_order_delivery
WHERE in_analysis_period
  AND NOT has_sequence_anomaly
GROUP BY is_late
ORDER BY is_late;

-- Q2b. Waktu tiap tahapan per bulan  [SUDAH DIJALANKAN]
SELECT DATE_TRUNC('month', purchase_ts)::date AS bulan,
       COUNT(*) AS jumlah_pesanan,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY handover_days)::numeric, 2) AS median_ke_kurir,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY transit_days)::numeric,  2) AS median_transit
FROM analytics.fact_order_delivery
WHERE in_analysis_period
  AND NOT has_sequence_anomaly
GROUP BY 1
ORDER BY 1;

/* KESIMPULAN Q2 - Telat terjadi di tahap mana?

   - Pesanan tepat waktu: ke kurir 2,13 | transit 6,93 | total 9,71 hari
     Pesanan telat      : ke kurir 3,43 | transit 23,93 | total 29,15 hari
   - Dari selisih 19,44 hari, transit menyumbang ~17 hari (87%), gudang
     penjual hanya ~1,3 hari (7%). Transit pesanan telat 3,5x lebih lama,
     gudang hanya 1,6x.
   - Per bulan (baseline: ke kurir 2,2 | transit 7,0):
       Nov 2017  ke kurir 3,16 (+44%)  -> yang memburuk GUDANG PENJUAL
       Feb 2018  transit 11,02 (+57%)  -> yang memburuk PENGIRIMAN KURIR
       Mar 2018  transit  9,88 (+41%), ke kurir normal 2,37
       Ags 2018  ke kurir 1,76 | transit 4,95 -> membaik jauh di bawah baseline
   - Dugaan Q1 terbukti: Nov 2017 = kapasitas gudang saat musim puncak;
     Feb-Mar 2018 = jaringan pengiriman kurir.

   Kesimpulan: keterlambatan terjadi di TAHAP PENGIRIMAN KURIR.
   Perbaikan sejak Apr 2018 membuktikan masalah ini bisa diselesaikan.
*/




-- ============================================
-- Q3: SIAPA / APA PENYUMBANG TERBESAR?
-- Bagian 1: konsentrasi keterlambatan di sisi penjual
-- Grain di sini = pasangan (pesanan, penjual), karena satu pesanan
-- bisa melibatkan lebih dari satu penjual.
-- ============================================

-- Q3a. Seberapa terkonsentrasi masalahnya?
WITH per_penjual AS (
    SELECT i.seller_id,
           COUNT(*)                         AS total_pesanan,
           COUNT(*) FILTER (WHERE f.is_late) AS pesanan_telat
    FROM analytics.fact_order_delivery f
    JOIN (SELECT DISTINCT order_id, seller_id FROM raw.order_items) i
      ON i.order_id = f.order_id
    WHERE f.in_analysis_period
      AND NOT f.has_sequence_anomaly
    GROUP BY i.seller_id
)
SELECT COUNT(*)                                  AS jumlah_penjual,
       SUM(pesanan_telat)                        AS total_pesanan_telat,
       COUNT(*) FILTER (WHERE pesanan_telat > 0) AS penjual_pernah_telat
FROM per_penjual;


-- Q3b. 20 penjual penyumbang keterlambatan terbanyak
-- SUM(...) OVER (ORDER BY ...) = jumlah berjalan (kumulatif) dari atas ke bawah.
-- SUM(...) OVER ()             = total keseluruhan, tanpa dipecah.
WITH per_penjual AS (
    SELECT i.seller_id,
           COUNT(*)                         AS total_pesanan,
           COUNT(*) FILTER (WHERE f.is_late) AS pesanan_telat
    FROM analytics.fact_order_delivery f
    JOIN (SELECT DISTINCT order_id, seller_id FROM raw.order_items) i
      ON i.order_id = f.order_id
    WHERE f.in_analysis_period
      AND NOT f.has_sequence_anomaly
    GROUP BY i.seller_id
),
peringkat AS (
    SELECT seller_id,
           total_pesanan,
           pesanan_telat,
           SUM(pesanan_telat) OVER (ORDER BY pesanan_telat DESC, seller_id) AS kumulatif,
           SUM(pesanan_telat) OVER ()                                       AS total_semua
    FROM per_penjual
)
SELECT seller_id,
       total_pesanan,
       pesanan_telat,
       ROUND(100.0 * pesanan_telat / total_pesanan, 2) AS persen_telat_penjual,
       ROUND(100.0 * kumulatif / total_semua, 2)       AS kontribusi_kumulatif
FROM peringkat
ORDER BY pesanan_telat DESC
LIMIT 20;


-- Q3c. Keterlambatan per provinsi tujuan
SELECT customer_state,
       COUNT(*)                                                     AS total_pesanan,
       COUNT(*) FILTER (WHERE is_late)                              AS pesanan_telat,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / COUNT(*), 2) AS persen_telat,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY transit_days)::numeric, 2) AS median_transit
FROM analytics.fact_order_delivery
WHERE in_analysis_period
  AND NOT has_sequence_anomaly
GROUP BY customer_state
HAVING COUNT(*) >= 500
ORDER BY persen_telat DESC;


-- Q3d. Keterlambatan per kategori produk
-- Grain di sini = item, karena kategori menempel pada produk.
SELECT tr.product_category_name_english                             AS kategori,
       COUNT(*)                                                     AS total_item,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_late) / COUNT(*), 2) AS persen_telat,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.product_weight_g)::numeric, 0) AS median_berat_gram
FROM analytics.fact_order_delivery f
JOIN raw.order_items i ON i.order_id = f.order_id
JOIN raw.products    p ON p.product_id = i.product_id
LEFT JOIN raw.product_category_name_translation tr
       ON tr.product_category_name = p.product_category_name
WHERE f.in_analysis_period
  AND NOT f.has_sequence_anomaly
GROUP BY tr.product_category_name_english
HAVING COUNT(*) >= 1000
ORDER BY persen_telat DESC
LIMIT 10;

/* KESIMPULAN Q3 - Penyebabnya GEOGRAFI, bukan penjual atau produk

   PENJUAL (Q3a-b)
   - 2.943 penjual, 1.388 pernah telat. Top 20 menyumbang 23,98%.
   - TAPI konsentrasi ini sebagian besar efek VOLUME, bukan performa buruk:
     penjual teratas punya 1.000-1.800 pesanan dengan tingkat telat
     10-11%, hanya sedikit di atas rata-rata 8,13%.
   - Yang benar-benar bermasalah hanya segelintir, mis. penjual dengan
     389 pesanan tapi 23,14% telat, dan 380 pesanan dengan 16,58% telat.
   - Kesimpulan: pembinaan penjual berdampak kecil. Bukan akar masalah.

   WILAYAH (Q3c) - INI AKAR MASALAHNYA
   - Rentangnya 3,9x: MA 19,64% vs PR 5,02%.
   - Tingkat telat mengikuti lama transit:
       MA 19,64% (transit 15,68 hari) | PA 12,42% (transit 17,30)
       SP  5,90% (transit  4,42 hari) | PR  5,02% (transit  7,18)
   - Provinsi utara/timur laut (MA, CE, PA, BA) konsisten terburuk.
   - Pengecualian yang perlu diselidiki: RJ telat 13,52% padahal
     transitnya hanya 8,38 hari. Volumenya besar (12.310 pesanan).
     Dugaan: tanggal janji terlalu optimis untuk RJ, bukan soal jarak.
   - SP menyerap 40.386 pesanan (42% total) dengan kinerja terbaik kedua.

   PRODUK (Q3d) - BUKAN FAKTOR
   - Rentang antar kategori sangat sempit: 8,29% - 9,75%.
     Semuanya dekat rata-rata 8,13%.
   - Berat tidak berpengaruh: electronics (200 g) justru tertinggi 9,75%,
     sementara office_furniture (10.975 g) 8,91%.
   - Kesimpulan: jenis dan berat produk tidak menentukan keterlambatan.

   IMPLIKASI: perbaikan harus diarahkan ke JARINGAN PENGIRIMAN ke wilayah
   utara/timur laut, bukan ke pembinaan penjual atau penanganan produk.
*/




-- ============================================
-- Q4: KAPAN RISIKO MEMUNCAK?
-- ============================================

-- Q4a. Apakah janji pengirimannya sendiri berubah?
-- buffer = jarak hari antara tanggal beli dan tanggal yang dijanjikan
SELECT DATE_TRUNC('month', purchase_ts)::date AS bulan,
       COUNT(*)                                                     AS jumlah_pesanan,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / COUNT(*), 2) AS persen_telat,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (
             ORDER BY EXTRACT(EPOCH FROM (estimated_ts - purchase_ts))/86400.0)::numeric, 1
       ) AS median_buffer_janji
FROM analytics.fact_order_delivery
WHERE in_analysis_period
  AND NOT has_sequence_anomaly
GROUP BY 1
ORDER BY 1;


-- Q4b. Krisis Mar 2018: merata di semua wilayah, atau terkonsentrasi?
-- Pembanding: Jan + Apr 2018 (bulan normal yang mengapitnya)
SELECT *,
       ROUND(mar_persen - baseline_persen, 1) AS selisih_poin
FROM (
    SELECT customer_state,
           COUNT(*) FILTER (WHERE purchase_ts >= '2018-03-01'
                              AND purchase_ts <  '2018-04-01') AS pesanan_mar,
           ROUND(100.0 * COUNT(*) FILTER (WHERE is_late
                              AND purchase_ts >= '2018-03-01'
                              AND purchase_ts <  '2018-04-01')
                 / NULLIF(COUNT(*) FILTER (WHERE purchase_ts >= '2018-03-01'
                              AND purchase_ts <  '2018-04-01'), 0), 1) AS mar_persen,
           ROUND(100.0 * COUNT(*) FILTER (WHERE is_late
                              AND purchase_ts <  '2018-03-01'
                               OR is_late AND purchase_ts >= '2018-04-01')
                 / NULLIF(COUNT(*) FILTER (WHERE purchase_ts <  '2018-03-01'
                                             OR purchase_ts >= '2018-04-01'), 0), 1) AS baseline_persen
    FROM analytics.fact_order_delivery
    WHERE NOT has_sequence_anomaly
      AND purchase_ts >= '2018-01-01'
      AND purchase_ts <  '2018-05-01'
    GROUP BY customer_state
    HAVING COUNT(*) FILTER (WHERE purchase_ts >= '2018-03-01'
                              AND purchase_ts <  '2018-04-01') >= 100
) x
ORDER BY selisih_poin DESC;


-- Q4c. Apakah hari pembelian berpengaruh?
-- 0 = Minggu, 1 = Senin, ... 6 = Sabtu
SELECT EXTRACT(DOW FROM purchase_ts)::int                          AS hari,
       COUNT(*)                                                     AS jumlah_pesanan,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / COUNT(*), 2) AS persen_telat
FROM analytics.fact_order_delivery
WHERE in_analysis_period
  AND NOT has_sequence_anomaly
GROUP BY 1
ORDER BY 1;


/* KESIMPULAN Q4 - Kapan risiko memuncak?

   JANJI PENGIRIMAN MAKIN KETAT (Q4a)
   - Buffer janji menyusut terus: 39,0 hari (Jan 2017) -> 13,4 hari (Ags 2018),
     turun 66%. Olist makin agresif menjanjikan kecepatan.
   - Perbaikan Apr-Jul 2018 (telat 1,36%-5,31%) terjadi MESKI janjinya makin
     ketat. Ini perbaikan operasional nyata, bukan sekadar longgarkan target.
   - Peringatan: Ags 2018 buffer terendah 13,4 hari, tapi telat naik lagi
     ke 10,39%. Janji mulai melewati batas kemampuan operasional.
   - Mar 2018 buffer justru diperketat (24,3 -> 21,3) tepat saat gangguan
     terjadi, sehingga memperparah angka keterlambatan.

   KRISIS MAR 2018 BERSIFAT NASIONAL (Q4b)
   - SELURUH 11 provinsi memburuk, tanpa kecuali:
       ES +29,7 poin | BA +17,7 | RJ +17,6 | MG +17,5 | SP +7,0
   - Bahkan SP yang paling kuat (2.971 pesanan) ikut naik 4,7% -> 11,7%.
   - Artinya ini gangguan jaringan pengiriman berskala nasional,
     bukan masalah satu wilayah atau satu penjual.

   HARI PEMBELIAN TIDAK BERPENGARUH (Q4c)
   - Rentangnya sempit 7,50% - 9,07%. Senin tertinggi (9,07%), Minggu
     terendah (7,50%). Selisih tidak cukup besar untuk ditindaklanjuti.

   IMPLIKASI: dua tuas perbaikan. (1) Perkuat ketahanan jaringan kurir
   terhadap gangguan nasional. (2) Tetapkan batas bawah buffer janji
   supaya target pengiriman tidak melampaui kemampuan operasional.
*/




-- ============================================
-- Q5: BERAPA KERUGIAN AKIBAT KETERLAMBATAN?
-- Ukuran dampak: skor ulasan pelanggan.
-- Hanya pesanan yang punya ulasan (646 pesanan tanpa ulasan dikecualikan).
-- ============================================

-- Q5a. Skor ulasan: telat vs tepat waktu
SELECT is_late,
       COUNT(*)                                                              AS jumlah_pesanan,
       ROUND(AVG(review_score), 2)                                           AS skor_rata2,
       ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / COUNT(*), 2) AS persen_1_2_bintang,
       ROUND(100.0 * COUNT(*) FILTER (WHERE review_score  = 5) / COUNT(*), 2) AS persen_5_bintang
FROM analytics.fact_order_delivery
WHERE in_analysis_period
  AND NOT has_sequence_anomaly
  AND review_score IS NOT NULL
GROUP BY is_late
ORDER BY is_late;


-- Q5b. Apakah ada ambang batas kesabaran pelanggan?
SELECT CASE
         WHEN delay_days <= 0  THEN '1. tepat waktu'
         WHEN delay_days <= 3  THEN '2. telat 1-3 hari'
         WHEN delay_days <= 7  THEN '3. telat 4-7 hari'
         WHEN delay_days <= 15 THEN '4. telat 8-15 hari'
         ELSE                       '5. telat >15 hari'
       END                                                                   AS kelompok,
       COUNT(*)                                                              AS jumlah_pesanan,
       ROUND(AVG(review_score), 2)                                           AS skor_rata2,
       ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / COUNT(*), 2) AS persen_1_2_bintang
FROM analytics.fact_order_delivery
WHERE in_analysis_period
  AND NOT has_sequence_anomaly
  AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- Q5c. Estimasi dampak: berapa pelanggan kecewa yang SEHARUSNYA tidak ada?
-- Caranya: bandingkan jumlah ulasan buruk pada pesanan telat dengan
-- jumlah yang wajar terjadi seandainya pesanan itu tepat waktu.
SELECT COUNT(*) FILTER (WHERE is_late AND review_score <= 2)      AS ulasan_buruk_pesanan_telat,
       ROUND(COUNT(*) FILTER (WHERE is_late)
             * (COUNT(*) FILTER (WHERE NOT is_late AND review_score <= 2)::numeric
                / COUNT(*) FILTER (WHERE NOT is_late)), 0)        AS ekspektasi_jika_tepat_waktu,
       ROUND(SUM(order_value) FILTER (WHERE is_late), 0)          AS nilai_pesanan_telat_brl
FROM analytics.fact_order_delivery
WHERE in_analysis_period
  AND NOT has_sequence_anomaly
  AND review_score IS NOT NULL;


/* KESIMPULAN Q5 - Berapa kerugiannya?

   DAMPAKNYA BESAR DAN TERUKUR (Q5a)
   - Skor ulasan jatuh dari 4,30 (tepat waktu) ke 2,57 (telat).
   - Ulasan 1-2 bintang melonjak 9,19% -> 54,06%, hampir 6x lipat.
   - Ulasan 5 bintang anjlok 62,45% -> 22,24%.

   ADA AMBANG BATAS KESABARAN PELANGGAN (Q5b) - TEMUAN PALING PENTING
       tepat waktu   : skor 4,30 | 1-2 bintang  9,19%
       telat 1-3 hari: skor 3,76 | 1-2 bintang 19,22%
       telat 4-7 hari: skor 2,32 | 1-2 bintang 61,29%   <- LONJAKAN
       telat 8-15 hari: skor 1,73 | 1-2 bintang 78,58%
       telat >15 hari : skor 1,72 | 1-2 bintang 78,30%
   - Titik patahnya ada antara hari ke-3 dan ke-7: ulasan buruk melompat
     3x lipat (19,22% -> 61,29%).
   - Setelah 8 hari, kerusakannya jenuh - telat 10 hari dan telat 60 hari
     dampaknya sama saja (78%). Pelanggan sudah terlanjur kecewa.

   BIAYA YANG BISA DIHITUNG (Q5c)
   - 4.139 ulasan buruk pada pesanan telat, padahal seandainya tepat waktu
     hanya wajar muncul 704. Artinya 3.435 pelanggan kecewa yang
     SEHARUSNYA TIDAK ADA.
   - Nilai pesanan yang terlambat: BRL 1.123.857.

   IMPLIKASI OPERASIONAL: target perbaikan bukan "nol keterlambatan",
   melainkan "jangan sampai telat lebih dari 3 hari". Menekan keterlambatan
   parah menjadi keterlambatan ringan sudah menyelamatkan sebagian besar
   kepuasan pelanggan, dengan biaya jauh lebih murah daripada mengejar
   ketepatan sempurna.
*/