# Pertanyaan Bisnis dan Data

Dokumen ini adalah titik awal proyek: masalah yang ingin dijawab, pertanyaan yang diturunkan darinya, dan data yang tersedia untuk menjawabnya.

**Ditujukan untuk:** Kepala Divisi Logistik & Pemenuhan Pesanan

---

## 1. Latar Belakang

Olist adalah marketplace yang menghubungkan penjual kecil di Brasil dengan pembeli, dengan pengiriman ditangani mitra kurir. Setiap pesanan membawa tanggal perkiraan tiba yang dijanjikan kepada pembeli saat transaksi.

Sebuah pesanan disebut **terlambat** bila tanggal terima aktual melewati tanggal janji tersebut.

Masalah yang ingin dijawab: *seberapa parah keterlambatan pengiriman Olist, di mana akar masalahnya, dan berapa kerugiannya?*

## 2. Lima Pertanyaan

| Kode | Pertanyaan                             | Yang diukur                                         |
| ---- | -------------------------------------- | --------------------------------------------------- |
| P1   | Seberapa parah keterlambatannya?       | Persen pesanan telat, seberapa lama, kapan memburuk |
| P2   | Di tahap mana keterlambatan terjadi?   | Gudang penjual atau pengiriman kurir                |
| P3   | Siapa atau apa penyumbang terbesarnya? | Penjual, wilayah tujuan, atau jenis produk          |
| P4   | Kapan risikonya memuncak?              | Pola musiman dan penyebab krisis Feb–Mar 2018       |
| P5   | Berapa kerugiannya?                    | Dampak keterlambatan terhadap kepuasan pelanggan    |

Urutannya disusun menyempit: dari mengukur besarnya masalah, mempersempit ke tahap dan pelaku, lalu menutup dengan nilai kerugiannya.

## 3. Data yang Tersedia

Data mentah ada di folder [`data_mentah/`](data_mentah/), berupa 7 file CSV dengan rentang pesanan Sep 2016 – Okt 2018. Nama file dipertahankan sesuai aslinya agar tetap dapat dicocokkan dengan sumber.

| File                                    | Isi                                         | Baris   |
| --------------------------------------- | ------------------------------------------- | ------- |
| `olist_orders_dataset.csv`              | Pesanan, status, dan tanggal tiap tahapan   | 99.441  |
| `olist_order_items_dataset.csv`         | Barang di dalam tiap pesanan, harga, ongkir | 112.650 |
| `olist_order_reviews_dataset.csv`       | Ulasan dan skor pelanggan                   | 99.224  |
| `olist_customers_dataset.csv`           | Pelanggan dan lokasinya                     | 99.441  |
| `olist_sellers_dataset.csv`             | Penjual dan lokasinya                       | 3.095   |
| `olist_products_dataset.csv`            | Produk, kategori, berat, dan dimensi        | 32.951  |
| `product_category_name_translation.csv` | Kamus nama kategori produk (Portugis)       | 71      |

**Sumber:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle).

## 4. Cakupan Analisis

- **Periode:** 1 Jan 2017 – 31 Ags 2018.
- **Pesanan:** hanya yang berstatus terkirim dan tanggal terimanya tercatat.
- **Basis akhir:** 96.184 pesanan, setelah pemeriksaan kualitas data (lihat [`../proses/`](../proses/)).

Jawaban atas kelima pertanyaan ada di folder [`../hasil/`](../hasil/).
