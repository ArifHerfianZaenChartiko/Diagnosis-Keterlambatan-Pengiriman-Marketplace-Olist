# Proses Analisis

Folder ini berisi seluruh pekerjaan teknis di balik hasil di [`../hasil/`](../hasil/): pembangunan database, pemeriksaan kualitas data, analisis, dan validasi angka. Bagian ini ditujukan bagi tim data yang ingin memeriksa atau menjalankan ulang analisisnya.

Subfolder diberi nomor sesuai urutan pengerjaan:

```
data_mentah (CSV)
      |
01_sql/      -> database, audit kualitas data, tabel fakta, analisis P1–P5
      |
02_python/   -> validasi silang angka SQL dengan Pandas
      |
03_excel/    -> validasi ketiga + data bersih
```

---

## 1. SQL (`01_sql/`): inti analisis

Dijalankan di **PostgreSQL**, database `olist_ops`, dengan dua skema: `raw` untuk data mentah dan `analytics` untuk data olahan.

| File                              | Isi                                                                                                                                                                                                          |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `01_buat_skema.sql`               | Membuat skema `raw` & `analytics` serta 7 tabel sumber                                                                                                                                                       |
| `02_impor_data.sql`               | Mengimpor 7 CSV ke skema `raw`                                                                                                                                                                               |
| `03_pasang_kunci_relasi.sql`      | Memasang kunci primer & kunci relasi (PK/FK) **setelah** data masuk, sebagai uji integritas. Ketahuan 13 produk memakai kategori yang tidak ada di kamus terjemahan, lalu diperbaiki dengan melengkapi kamus |
| `04_audit_kualitas_data.sql`      | Memeriksa kesehatan data: status pesanan, tanggal kosong, urutan tanggal mustahil, ulasan ganda                                                                                                              |
| `05_bangun_tabel_fakta.sql`       | Membangun view (tabel virtual) `analytics.fact_order_delivery`: satu baris = satu pesanan, 96.470 pesanan                                                                                                    |
| `06_analisis_p1_p5.sql`           | Menjawab kelima pertanyaan bisnis, dengan kesimpulan tertulis di tiap bagian                                                                                                                                 |
| `07_bangun_ringkasan_penjual.sql` | View kinerja per penjual untuk dasbor                                                                                                                                                                        |
| `08_bangun_rujukan_provinsi.sql`  | Tabel rujukan nama & wilayah provinsi Brasil                                                                                                                                                                 |

Teknik yang dipakai antara lain `FILTER`, `PERCENTILE_CONT` (median dan persentil), fungsi jendela untuk jumlah kumulatif, `DISTINCT ON` untuk mengambil ulasan terbaru, dan view.

> Nama tabel dan kolom di database (misalnya `fact_order_delivery`, `seller_id`) mengikuti nama asli dataset dan tidak diterjemahkan, karena dasbor Power BI terhubung langsung ke nama-nama tersebut.

### Keputusan kualitas data

Rinciannya ada di komentar `04_audit_kualitas_data.sql`.

- **1.359 pesanan** tercatat diserahkan ke kurir *sebelum* pembayarannya disetujui, sehingga waktu tahapan dihitung dari **tanggal beli**, bukan tanggal disetujui.
- **19 pesanan** dalam periode analisis punya urutan tanggal mustahil (diterima sebelum diserahkan ke kurir), sehingga dikeluarkan lewat penanda `has_sequence_anomaly`. Total anomali di seluruh data mentah ada 23; 4 di antaranya di luar periode Jan 2017–Ags 2018, sehingga tidak mengurangi basis 96.184.
- **547 pesanan** punya ulasan ganda (202 di antaranya skornya berbeda), sehingga yang dipakai adalah **ulasan terbaru** per pesanan.
- **Basis akhir analisis:** pesanan berstatus terkirim (`delivered`) dengan tanggal terima terisi, periode Jan 2017–Ags 2018 = **96.184 pesanan**.

## 2. Python (`02_python/validasi_silang.ipynb`)

Menarik data dari `analytics.fact_order_delivery` lewat SQLAlchemy, lalu menghitung ulang 10 metrik P1, P2, dan P5 dengan Pandas sebagai **pemeriksaan silang yang independen** terhadap hasil SQL. Angka SQL pembandingnya diambil langsung lewat kueri di notebook (bukan diketik ulang), dan dibandingkan sebelum dibulatkan supaya beda cara pembulatan tidak terbaca sebagai selisih. Hasilnya: **10 dari 10 cocok**.

Notebook ini juga mengekspor data bersih ke `03_excel/data_pengiriman_bersih.csv` dengan format Indonesia (pemisah `;`, desimal `,`).

## 3. Excel (`03_excel/`)

`cek_silang_metrik.xlsx` adalah validasi ketiga atas angka yang sama. Data dimuat lewat Power Query dari `data_pengiriman_bersih.csv`, lalu dihitung ulang dengan rumus Excel di sheet `cek_silang`. Hasilnya: **7 dari 7 metrik cocok**.

> Power Query menyimpan lokasi CSV sebagai path lengkap. Jika folder proyek dipindah, perbarui sumbernya lewat **Data → Get Data → Data Source Settings**.

---

## Cara Menjalankan Ulang

Semua perintah dijalankan dari **folder utama proyek**.

1. Buat database: `CREATE DATABASE olist_ops;`, lalu jalankan `proses/01_sql/01_buat_skema.sql` di database tersebut.
2. Impor data lewat psql (path CSV di dalam skrip relatif terhadap folder utama):

   ```bash
   psql -U postgres -d olist_ops -f proses/01_sql/02_impor_data.sql
   ```

3. Jalankan berurutan: `03_pasang_kunci_relasi.sql` → `04_audit_kualitas_data.sql` → `05_bangun_tabel_fakta.sql`.
4. Jalankan `06_analisis_p1_p5.sql`, `07_bangun_ringkasan_penjual.sql`, dan `08_bangun_rujukan_provinsi.sql`.
5. (Opsional) Jalankan `proses/02_python/validasi_silang.ipynb` untuk validasi silang. Kata sandi PostgreSQL diminta saat dijalankan dan tidak disimpan di notebook.
6. Buka `hasil/dasbor/dasbor_keterlambatan_pengiriman.pbix` di Power BI Desktop, lalu arahkan sumber datanya ke database lokal.

Library Python yang dibutuhkan: `pandas`, `numpy`, `sqlalchemy`, `psycopg2`.
