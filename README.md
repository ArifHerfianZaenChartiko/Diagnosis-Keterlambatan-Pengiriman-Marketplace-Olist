# Diagnosis Keterlambatan Pengiriman Marketplace Olist

**End-to-end data analytics project** — dari data mentah sampai rekomendasi bisnis.
Studi kasus operasional untuk menjawab: *seberapa parah keterlambatan pengiriman Olist, di mana akar masalahnya, dan berapa kerugiannya?*

**Periode data:** Jan 2017 – Ags 2018 | **Basis analisis:** 96.184 pesanan | **Role:** Operations Data Analyst

---

## 1. Ringkasan Masalah & Temuan Utama

On-Time Delivery Rate Olist = **91,87%** (8,13% pesanan telat). Terlihat sehat, tapi ada 3 hal yang tersembunyi di balik angka itu:

| # | Temuan | Angka Kunci |
|---|--------|-------------|
| 1 | Sekali telat, telatnya jauh | Rata-rata **9,55 hari**, terparah **188,98 hari** |
| 2 | Masalah ada di jalan, bukan gudang | **87%** selisih waktu ada di transit kurir, hanya 7% di gudang penjual |
| 3 | Penyebabnya geografi, bukan penjual/produk | Maranhão **19,64%** telat vs Paraná **5,02%** (3,9x) |
| 4 | Ada titik jenuh kesabaran pelanggan | Ulasan buruk melonjak dari **19,22% → 61,29%** antara hari ke-3 dan ke-7 |
| 5 | Kerugian terukur | **3.435 pelanggan kecewa** yang seharusnya tidak ada, menempel di pesanan senilai **BRL 1.123.857** |

**Rekomendasi utama:** target operasional bukan "nol keterlambatan", melainkan **"jangan sampai telat lebih dari 3 hari"**, dan perbaikan diarahkan ke jaringan kurir wilayah Utara/Timur Laut — bukan ke pembinaan penjual atau penanganan produk.

Detail lengkap 5 pertanyaan bisnis (Q1–Q5) ada di [`06_report/insight_report.md`](06_report/insight_report.md) / `.pdf` / `.docx`.

---

## 2. Lima Pertanyaan Bisnis yang Dijawab

| Kode | Pertanyaan |
|------|------------|
| Q1 | Seberapa parah keterlambatannya? |
| Q2 | Di tahap mana terjadi — gudang penjual atau pengiriman kurir? |
| Q3 | Siapa/apa penyumbang terbesar — penjual, wilayah, atau produk? |
| Q4 | Kapan risiko memuncak, dan apa penyebab krisis Feb–Mar 2018? |
| Q5 | Berapa kerugiannya terhadap kepuasan pelanggan? |

---

## 3. Tools & Tech Stack

| Tahap | Tools |
|-------|-------|
| Database & modeling | **PostgreSQL** (schema `raw` + `analytics`) |
| Analisis & query bisnis | **SQL** (window function, `PERCENTILE_CONT`, `FILTER`, view) |
| Validasi silang | **Python** (Pandas, SQLAlchemy) via Jupyter Notebook |
| Cross-check angka | **Excel** |
| Visualisasi | **Power BI** |
| Laporan & presentasi | Markdown, Word, PowerPoint |
| Version control | **Git** |

---

## 4. Alur Kerja (Workflow)

Proyek ini dikerjakan berurutan, tiap tahap membangun di atas tahap sebelumnya:

```
01_data_raw     -> Data mentah Olist (7 file CSV, Sep 2016 - Okt 2018)
      |
02_sql          -> Database, audit kualitas data, fact table, analisis Q1-Q5
      |
03_python       -> Validasi silang angka SQL dengan Pandas
      |
04_excel        -> Cross-check kedua + ekspor data bersih
      |
05_dashboard    -> Dashboard Power BI (interaktif)
      |
06_report       -> Laporan insight tertulis (naratif lengkap)
      |
07_presentation -> Ringkasan eksekutif untuk stakeholder (PPTX)
```

### 4.1 SQL (`02_sql/`) — jantung analisis

| File | Isi |
|------|-----|
| `01_create_schema.sql` | Bangun database `olist_ops`, schema `raw` & `analytics`, 7 tabel sumber |
| `02_import_data.sql` | Import CSV ke tabel raw |
| `03_add_constraints.sql` | Pasang PK/FK **setelah** data masuk (dipakai sebagai uji integritas, bukan penghalang impor) — ketahuan 13 produk pakai kategori yang tidak ada di kamus terjemahan, diperbaiki dengan melengkapi kamus |
| `04_data_quality_audit.sql` | Audit kesehatan data: status pesanan, tanggal kosong, urutan tanggal mustahil, ulasan ganda |
| `05_build_fact_table.sql` | Bangun **view** `analytics.fact_order_delivery` — satu baris = satu pesanan, basis 96.470 pesanan |
| `06_analysis_q1_q5.sql` | Jawab kelima pertanyaan bisnis + kesimpulan tertulis di tiap bagian |
| `07_build_seller_view.sql` | View performa per penjual untuk dashboard |
| `08_build_state_ref.sql` | Tabel rujukan nama & wilayah provinsi Brasil |

**Keputusan kualitas data penting (lihat komentar di `04_data_quality_audit.sql`):**
- 1.359 pesanan tercatat diserahkan ke kurir *sebelum* disetujui pembayarannya → waktu tahapan dihitung dari **tanggal beli**, bukan tanggal disetujui.
- 19 pesanan dalam periode analisis punya urutan tanggal mustahil (diterima sebelum diserahkan ke kurir) → dikeluarkan via flag `has_sequence_anomaly` (23 adalah total anomali di seluruh dataset mentah, 4 di antaranya di luar periode Jan 2017–Ags 2018 sehingga tidak mengurangi basis 96.184).
- 547 pesanan punya ulasan ganda (202 skornya beda) → diambil **ulasan terbaru** per pesanan.
- Basis akhir analisis: pesanan `delivered` dengan tanggal terima terisi, periode Jan 2017–Ags 2018 = **96.184 pesanan**.

### 4.2 Python (`03_python/01_validation.ipynb`)
Menarik data dari `analytics.fact_order_delivery` lewat SQLAlchemy, lalu menghitung ulang metrik Q1/Q2/Q5 pakai Pandas untuk **cross-check independen** terhadap hasil SQL. Semua angka cocok. Hasil bersih diekspor ke `04_excel/fact_delivery.csv` (format Indonesia: separator `;`, desimal `,`).

### 4.3 Excel (`04_excel/`)
`01_crosscheck_metrics.xlsx` — verifikasi ketiga atas angka yang sama, memakai pivot table/formula manual di luar SQL dan Python.

### 4.4 Dashboard Power BI (`05_dashboard/`)
`olist_ops_dashboard.pbix` (+ ekspor PDF & screenshot). Menyajikan versi interaktif dari temuan Q1–Q4 untuk eksplorasi mandiri oleh stakeholder.

### 4.5 Laporan (`06_report/`)
`insight_report.md/.pdf/.docx` — laporan naratif lengkap: latar belakang, metode, temuan per pertanyaan, dan rekomendasi. Ini dokumen paling detail di proyek ini.

### 4.6 Presentasi (`07_presentation/`)
`Diagnosis_Keterlambatan_Pengiriman_Olist.pptx` (13 slide) — versi ringkas untuk dipresentasikan ke Head of Logistics & Fulfillment, ditutup dengan 6 rekomendasi terurut dari dampak terbesar.

---

## 5. Enam Rekomendasi (diurutkan dari dampak terbesar)

1. **Arahkan perbaikan ke jaringan kurir** — 87% selisih waktu telat ada di transit, pembinaan penjual hanya menyentuh 7%.
2. **Ubah target jadi "≤3 hari"**, bukan "nol keterlambatan" — kerusakan kepuasan melonjak di hari ke-3–7, jenuh setelah hari ke-8.
3. **Tetapkan batas bawah buffer janji pengiriman** — buffer turun 66% dalam 20 bulan; di titik terendah (13,4 hari) keterlambatan naik lagi ke 10,39%.
4. **Prioritaskan wilayah Utara & Timur Laut** (Maranhão, Ceará, Pará, Bahia) — konsisten terburuk, Maranhão hampir 4x Paraná.
5. **Selidiki Rio de Janeiro secara terpisah** — telat 13,52% padahal transit hanya 8,38 hari (12.310 pesanan), menunjuk ke rumus estimasi tanggal janji, bukan kecepatan kirim.
6. **Siapkan dua protokol musiman berbeda** — Nov 2017 = masalah kapasitas gudang, Feb–Mar 2018 = gangguan jaringan kurir nasional. Satu solusi untuk keduanya akan meleset.

---

## 6. Struktur Folder

```
Diagnosis Keterlambatan Pengiriman Marketplace Olist/
├── 01_data_raw/            # 7 CSV mentah dari Olist
├── 02_sql/                 # Schema, audit, fact table, analisis Q1-Q5
├── 03_python/              # Notebook validasi silang (Pandas)
├── 04_excel/               # Cross-check metrik + data bersih (fact_delivery.csv)
├── 05_dashboard/           # Dashboard Power BI (.pbix, .pdf, screenshot)
├── 06_report/              # Laporan insight (.md, .pdf, .docx)
├── 07_presentation/        # Slide eksekutif (.pptx)
└── README.md
```

## 7. Cara Reproduksi

1. `CREATE DATABASE olist_ops;` lalu jalankan `02_sql/01_create_schema.sql`.
2. Import 7 CSV di `01_data_raw/` sesuai `02_import_data.sql`.
3. Jalankan `03_add_constraints.sql` → `04_data_quality_audit.sql` → `05_build_fact_table.sql` berurutan.
4. Jalankan `06_analysis_q1_q5.sql`, `07_build_seller_view.sql`, `08_build_state_ref.sql`.
5. (Opsional) Jalankan `03_python/01_validation.ipynb` untuk validasi silang.
6. Buka `05_dashboard/olist_ops_dashboard.pbix` di Power BI Desktop, arahkan sumber data ke database lokal.

## 8. Sumber Data

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle).

---
*Validasi angka dilakukan 3 kali secara independen: PostgreSQL, Python (Pandas), dan Excel — hasil identik.*
