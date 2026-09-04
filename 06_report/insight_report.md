# Diagnosis Keterlambatan Pengiriman Marketplace Olist

Periode Jan 2017 – Ags 2018

Disusun oleh Operations Analyst untuk Head of Logistics & Fulfillment

---

## 1. Ringkasan Eksekutif

Dari 96.184 pesanan yang dikirimkan sepanjang Jan 2017 – Ags 2018, sebanyak 7.822 tiba melewati tanggal yang dijanjikan. On-Time Delivery Rate berada di 91,87%.

Angka itu terdengar sehat, tetapi menyembunyikan tiga hal yang tidak terlihat dari ringkasan bulanan.

**Pertama, sekali telat, telatnya jauh.** Rata-rata keterlambatan 9,55 hari, dengan kasus terparah 188,98 hari. Keterlambatan di Olist bukan meleset beberapa jam, melainkan meleset lebih dari seminggu.

**Kedua, masalahnya ada di jalan, bukan di gudang.** Pesanan yang telat menghabiskan 23,93 hari dalam perjalanan kurir, dibanding 6,93 hari pada pesanan tepat waktu. Dari total selisih 19,44 hari antara pesanan telat dan tepat waktu, 87% terjadi di tahap pengiriman kurir dan hanya 7% di gudang penjual. Pembinaan penjual tidak akan menyentuh akar masalahnya.

**Ketiga, kerusakannya terjadi lebih cepat dari dugaan.** Skor ulasan jatuh dari 4,30 menjadi 2,57 ketika pesanan telat. Titik patahnya ada antara hari ke-3 dan ke-7: ulasan 1–2 bintang melonjak dari 19,22% menjadi 61,29%. Setelah hari ke-8, kerusakannya jenuh — telat 10 hari dan telat 60 hari sama-sama menghasilkan sekitar 78% ulasan buruk.

Konsekuensinya untuk strategi operasional: **target yang tepat bukan "nol keterlambatan", melainkan "jangan sampai telat lebih dari 3 hari".** Menekan keterlambatan parah menjadi keterlambatan ringan menyelamatkan sebagian besar kepuasan pelanggan dengan biaya yang jauh lebih murah daripada mengejar ketepatan sempurna.

Dampak yang bisa dihitung dari periode ini: 3.435 pelanggan kecewa yang seharusnya tidak ada, melekat pada pesanan senilai BRL 1.123.857.

---

## 2. Latar Belakang dan Pertanyaan

Olist adalah marketplace yang menghubungkan penjual kecil di Brasil dengan pembeli, dengan pengiriman ditangani mitra kurir. Setiap pesanan membawa tanggal perkiraan tiba yang dijanjikan kepada pembeli saat checkout. Sebuah pesanan disebut terlambat bila tanggal terima aktual melewati tanggal janji tersebut.

Analisis ini menjawab lima pertanyaan:

|     | Pertanyaan                                                                                       |
| --- | ------------------------------------------------------------------------------------------------ |
| Q1  | Seberapa parah keterlambatannya? Berapa persen pesanan telat, seberapa lama, dan kapan memburuk. |
| Q2  | Di tahap mana keterlambatan terjadi? Gudang penjual atau pengiriman kurir.                       |
| Q3  | Siapa atau apa penyumbang terbesarnya? Penjual, wilayah tujuan, atau jenis produk.               |
| Q4  | Kapan risikonya memuncak? Pola musiman dan penyebab krisis Feb–Mar 2018.                         |
| Q5  | Berapa kerugiannya? Dampak keterlambatan terhadap kepuasan pelanggan.                            |

Urutannya disusun menyempit: dari mengukur besarnya masalah, mempersempit ke tahap dan pelaku, lalu menutup dengan nilai kerugiannya.

---

## 3. Data dan Metode

|                |                                                                        |
| -------------- | ---------------------------------------------------------------------- |
| Sumber         | PostgreSQL, view `analytics.fact_order_delivery`                       |
| Basis analisis | 96.184 pesanan                                                         |
| Periode        | 1 Jan 2017 – 31 Ags 2018                                               |
| Cakupan        | Hanya pesanan berstatus `delivered` dengan tanggal terima terisi       |
| Dikecualikan   | 19 pesanan dengan urutan tanggal mustahil                              |
| Skor ulasan    | Diambil dari ulasan terbaru per pesanan                                |
| Validasi       | Angka dicek silang di PostgreSQL, Python, dan Excel — hasilnya identik |

**Definisi tahapan.** Waktu tempuh sebuah pesanan dipecah menjadi dua ruas yang tidak tumpang tindih:

- **Ke kurir** = tanggal serah ke kurir − tanggal pembelian. Ini porsi penjual: waktu menyiapkan dan menyerahkan barang.
- **Transit** = tanggal terima pelanggan − tanggal serah ke kurir. Ini porsi jaringan pengiriman.

Pemisahan inilah yang memungkinkan pertanyaan Q2 dijawab secara tegas, bukan lewat dugaan.

**Penanganan anomali.** 19 pesanan tercatat diterima pelanggan lebih dulu daripada diserahkan ke kurir — mustahil secara fisik, dan menghasilkan waktu transit negatif. Pesanan ini ditandai `has_sequence_anomaly` dan dikeluarkan dari seluruh perhitungan. Seluruhnya kebetulan berstatus tepat waktu, sehingga jumlah pesanan telat tidak berubah.

**Rata-rata dan median dilaporkan bersama.** Rata-rata dipakai untuk menaksir beban total, median untuk menggambarkan pengalaman pelanggan pada umumnya. Keduanya diperlukan karena sebaran keterlambatan sangat miring.

---

## 4. Temuan

### 4.1 Seberapa parah keterlambatannya

Sepanjang Jan 2017 – Ags 2018, Olist mengirimkan 96.184 pesanan. Sebanyak 7.822 di antaranya tiba melewati tanggal yang dijanjikan, atau 8,13%. Dinyatakan sebagai ukuran kinerja, On-Time Delivery Rate berada di 91,87%. Angka itu terdengar sehat, tetapi artinya 8 dari setiap 100 pelanggan menerima barangnya terlambat.

Yang lebih penting adalah seberapa jauh melesetnya. Rata-rata keterlambatan mencapai 9,55 hari, sementara mediannya 5,81 hari, dengan kasus terparah 188,98 hari. Selisih 3,74 hari antara rata-rata dan median menunjukkan sebaran yang miring: separuh pesanan telat meleset tidak lebih dari 5,81 hari, sedangkan segelintir kasus ekstrem menarik rata-rata jauh ke atas. Sebagai pembanding, waktu kirim normal dari pembelian sampai diterima adalah 10,21 hari, sehingga keterlambatan yang khas menambah lebih dari separuh waktu tunggu yang seharusnya.

Keterlambatan juga tidak merata sepanjang waktu. Sebagian besar bulan berada di bawah 6%, dengan beberapa bulan naik ke kisaran 7–8%. Tiga bulan meledak jauh di atas itu: Nov 2017 mencapai 14,31%, Feb 2018 15,99%, dan Mar 2018 21,36% — dua sampai tiga kali lipat bulan normal terburuk sekalipun. Sebagai perbandingan, bulan terbaik adalah Jun 2018 dengan 1,36%.

Dua lonjakan itu punya latar yang berbeda. Nov 2017 dibarengi lonjakan volume 63%, dari 4.478 menjadi 7.288 pesanan — pola khas musim belanja Black Friday yang menekan kapasitas. Sebaliknya, Feb–Mar 2018 terjadi pada volume normal, namun keterlambatannya justru lebih parah. Artinya penyebab krisis kedua bukan kapasitas, dan harus dicari di tempat lain.

Sejak Apr 2018 kinerja membaik, meski naik-turun dan belum stabil sampai akhir periode analisis.

### 4.2 Di tahap mana keterlambatan terjadi

Membandingkan pesanan telat dengan pesanan tepat waktu pada kedua ruas perjalanan memberi jawaban yang tidak ambigu.

| Tahap                    | Tepat waktu   | Telat          | Rasio    |
| ------------------------ | ------------- | -------------- | -------- |
| Ke kurir (porsi penjual) | 2,13 hari     | 3,43 hari      | 1,6×     |
| Transit (porsi kurir)    | 6,93 hari     | 23,93 hari     | 3,5×     |
| **Total**                | **9,71 hari** | **29,15 hari** | **3,0×** |

> **Cara membaca tabel ini.** Ketiga angka pada setiap baris adalah median yang dihitung terpisah, bukan penjumlahan. Median dari sebuah total tidak sama dengan total dari median, sehingga baris Total sengaja tidak sama dengan hasil menjumlahkan dua baris di atasnya. Median dipakai, bukan rata-rata, karena sebaran waktu pengiriman sangat miring oleh kasus ekstrem.

Dari total selisih 19,44 hari, sekitar 17 hari atau 87% berasal dari tahap transit, dan sekitar 1,3 hari atau 7% dari gudang penjual. Sisa 6% adalah efek perhitungan median yang baru disebutkan, bukan tahap ketiga yang belum teridentifikasi. Gudang penjual memang ikut melambat pada pesanan yang telat, tetapi kontribusinya kecil dan tidak menjelaskan besarnya masalah.

Pemecahan per bulan memperkuat kesimpulan itu sekaligus membedakan kedua krisis. Terhadap tingkat dasar 2,2 hari ke kurir dan 7,0 hari transit:

| Bulan    | Ke kurir      | Transit      | Yang memburuk    |
| -------- | ------------- | ------------ | ---------------- |
| Nov 2017 | 3,16 (+44%)   | normal       | Gudang penjual   |
| Feb 2018 | normal        | 11,02 (+57%) | Pengiriman kurir |
| Mar 2018 | 2,37 (normal) | 9,88 (+41%)  | Pengiriman kurir |
| Ags 2018 | 1,76          | 4,95         | Keduanya membaik |

Dugaan dari 4.1 terbukti. Nov 2017 adalah masalah kapasitas gudang saat musim puncak, sedangkan Feb–Mar 2018 adalah masalah jaringan pengiriman kurir. Keduanya membutuhkan penanganan yang berbeda.

Kesimpulan bagian ini: **keterlambatan terjadi di tahap pengiriman kurir.** Perbaikan yang terjadi sejak Apr 2018 membuktikan masalah ini dapat diselesaikan.

### 4.3 Siapa atau apa penyumbang terbesarnya

**Penjual bukan akar masalahnya.** Dari 2.943 penjual aktif, 1.388 pernah mengirim pesanan terlambat, dan 20 penjual teratas menyumbang 23,98% dari seluruh keterlambatan. Angka konsentrasi itu terlihat mengkhawatirkan sampai penyebabnya diperiksa: penjual-penjual tersebut menangani 1.000–1.800 pesanan masing-masing dengan tingkat keterlambatan 10–11%, hanya sedikit di atas rata-rata keseluruhan 8,13%. Mereka muncul di puncak daftar karena volumenya besar, bukan karena kinerjanya buruk.

Penjual yang benar-benar bermasalah justru bervolume kecil dan tidak terlihat di daftar teratas — misalnya satu penjual dengan 389 pesanan dan 23,14% keterlambatan, serta satu lagi dengan 380 pesanan dan 16,58%. Jumlah mereka sedikit, sehingga program pembinaan penjual akan berdampak kecil terhadap angka keseluruhan.

**Wilayah tujuan adalah akar masalahnya.** Rentang antarprovinsi mencapai 3,9 kali lipat, dari 19,64% di Maranhão sampai 5,02% di Paraná. Yang menentukan bukan jarak semata, melainkan lama transit:

| Provinsi       | Telat  | Median transit |
| -------------- | ------ | -------------- |
| Maranhão (MA)  | 19,64% | 15,68 hari     |
| Pará (PA)      | 12,42% | 17,30 hari     |
| São Paulo (SP) | 5,90%  | 4,42 hari      |
| Paraná (PR)    | 5,02%  | 7,18 hari      |

Provinsi di utara dan timur laut — Maranhão, Ceará, Pará, Bahia — konsisten menempati posisi terburuk. Sebaliknya São Paulo menyerap 40.386 pesanan atau 42% dari seluruh volume, dengan kinerja terbaik kedua.

Satu pengecualian layak diselidiki terpisah: **Rio de Janeiro mencatat 13,52% keterlambatan padahal transitnya hanya 8,38 hari** — jauh lebih cepat dari Maranhão maupun Pará. Dengan volume 12.310 pesanan, ini bukan kasus kecil. Dugaan yang paling masuk akal adalah tanggal janji yang terlalu optimis untuk Rio de Janeiro, bukan persoalan jarak atau jaringan.

**Jenis produk bukan faktor.** Perbedaan tingkat keterlambatan antarkategori produk tidak menunjukkan pola yang cukup kuat untuk ditindaklanjuti, termasuk setelah berat produk diperhitungkan.

> **Catatan pembacaan.** Peringkat provinsi di atas dibatasi pada provinsi dengan minimal 500 pesanan, supaya provinsi bervolume kecil tidak menguasai daftar hanya karena penyebutnya sedikit. Dasbor tidak memakai batas tersebut, sehingga puncaknya berbeda: Alagoas 23,99% dari 396 pesanan dan Piauí 16,00% dari 475 pesanan. Keduanya benar, hanya menjawab pertanyaan yang berbeda — laporan ini menyoroti provinsi bervolume besar yang bermasalah, dasbor menampilkan seluruh provinsi.

### 4.4 Kapan risikonya memuncak

**Janji pengiriman makin ketat dari waktu ke waktu.** Selisih antara tanggal janji dan tanggal pembelian menyusut terus, dari 39,0 hari pada Jan 2017 menjadi 13,4 hari pada Ags 2018 — turun 66%. Olist secara sadar menjanjikan pengiriman yang makin cepat.

Perbaikan setelah Mar 2018 nyata tetapi belum stabil. Apr turun ke 5,31%, naik lagi ke 8,24% pada Mei, lalu mencapai titik terbaik sepanjang periode pada Jun dengan 1,36%. Yang penting, perbaikan ini terjadi meskipun janjinya makin ketat — jadi ini hasil operasional yang nyata, bukan hasil melonggarkan target.

Namun ada peringatan di ujung periode. Pada Ags 2018 selisih janji berada di titik terendah, 13,4 hari, dan keterlambatan justru naik kembali ke 10,39%. Janji mulai melewati batas kemampuan operasional. Pola serupa terlihat pada Mar 2018, ketika selisih janji justru diperketat dari 24,3 menjadi 21,3 hari tepat saat gangguan pengiriman sedang berlangsung, sehingga memperparah angka keterlambatan bulan itu.

**Krisis Mar 2018 bersifat nasional.** Seluruh 11 provinsi yang dianalisis memburuk tanpa kecuali:

| Provinsi            | Kenaikan tingkat telat |
| ------------------- | ---------------------- |
| Espírito Santo (ES) | +29,7 poin             |
| Bahia (BA)          | +17,7 poin             |
| Rio de Janeiro (RJ) | +17,6 poin             |
| Minas Gerais (MG)   | +17,5 poin             |
| São Paulo (SP)      | +7,0 poin              |

Bahkan São Paulo, provinsi dengan kinerja paling stabil, naik dari 4,7% menjadi 11,7% atas 2.971 pesanan. Keseragaman ini menutup kemungkinan bahwa krisis berasal dari satu wilayah, satu penjual, atau satu mitra lokal. Yang terjadi adalah gangguan jaringan pengiriman berskala nasional.

**Hari pembelian tidak berpengaruh.** Tingkat keterlambatan berkisar sempit antara 7,50% dan 9,07%, dengan Senin tertinggi dan Minggu terendah. Selisihnya tidak cukup besar untuk dijadikan dasar tindakan.

### 4.5 Berapa kerugiannya

**Dampaknya besar dan terukur.** Skor ulasan rata-rata jatuh dari 4,30 pada pesanan tepat waktu menjadi 2,57 pada pesanan terlambat. Proporsi ulasan 1–2 bintang melonjak dari 9,19% menjadi 54,06%, hampir enam kali lipat, sementara ulasan 5 bintang anjlok dari 62,45% menjadi 22,24%.

**Ada ambang batas kesabaran pelanggan.** Memecah pesanan terlambat berdasarkan lamanya keterlambatan mengungkap pola yang tidak linear:

| Kondisi                  | Skor ulasan | Ulasan 1–2 bintang |
| ------------------------ | ----------- | ------------------ |
| Tepat waktu              | 4,30        | 9,19%              |
| Telat 1–3 hari           | 3,76        | 19,22%             |
| Telat 4–7 hari           | 2,32        | **61,29%**         |
| Telat 8–15 hari          | 1,73        | 78,58%             |
| Telat lebih dari 15 hari | 1,72        | 78,30%             |

Titik patahnya berada antara hari ke-3 dan ke-7: ulasan buruk melompat tiga kali lipat, dari 19,22% ke 61,29%. Setelah hari ke-8 kerusakannya jenuh — pesanan yang telat 10 hari dan yang telat 60 hari sama-sama menghasilkan sekitar 78% ulasan buruk. Pelanggan sudah terlanjur kecewa, dan tambahan keterlambatan tidak lagi mengubah penilaiannya.

Temuan ini bersambung dengan 4.1: median keterlambatan Olist adalah 5,81 hari, yang jatuh tepat di dalam kelompok 4–7 hari. Artinya keterlambatan yang **khas** pun sudah cukup parah untuk merusak kepuasan pelanggan — persoalannya bukan hanya pada kasus ekstrem.

**Biaya yang bisa dihitung.** Pesanan terlambat menghasilkan 4.139 ulasan buruk. Seandainya pesanan tersebut tiba tepat waktu, dengan tingkat ulasan buruk 9,19% hanya sekitar 704 ulasan buruk yang wajar muncul. Selisihnya, **3.435 pelanggan kecewa yang seharusnya tidak ada**, sepenuhnya disebabkan keterlambatan.

Pesanan yang terlambat itu bernilai **BRL 1.123.857**. Angka ini adalah nilai pesanan yang terdampak, bukan kerugian finansial langsung — barangnya tetap terkirim dan tetap dibayar. Fungsinya sebagai ukuran skala pendapatan yang berisiko terhadap kepercayaan pelanggan, bukan sebagai nilai kerugian yang harus ditanggung.

---

## 5. Rekomendasi

**1. Arahkan perbaikan ke jaringan kurir, bukan ke pembinaan penjual.**
Dasarnya 4.2: 87% selisih waktu antara pesanan telat dan tepat waktu terjadi di tahap transit. Program pembinaan penjual menyentuh ruas yang hanya menyumbang 7%, sehingga dampaknya terhadap angka keseluruhan akan kecil sekalipun berhasil.

**2. Ubah target dari "nol keterlambatan" menjadi "tidak telat lebih dari 3 hari".**
Dasarnya 4.5: kerusakan kepuasan pelanggan melonjak antara hari ke-3 dan ke-7, lalu jenuh setelah hari ke-8. Menarik pesanan yang telat 10 hari menjadi telat 3 hari menyelamatkan sebagian besar kepuasan, dan jauh lebih murah daripada mengejar ketepatan sempurna pada seluruh pesanan.

**3. Tetapkan batas bawah selisih janji pengiriman.**
Dasarnya 4.4: selisih janji menyusut 66% dalam 20 bulan, dan pada Ags 2018 di angka 13,4 hari keterlambatan naik kembali ke 10,39%. Perlu ditetapkan batas bawah yang tidak boleh dilewati, agar janji kepada pembeli tidak melampaui kemampuan operasional.

**4. Prioritaskan wilayah utara dan timur laut.**
Dasarnya 4.3: Maranhão, Ceará, Pará, dan Bahia konsisten terburuk, dengan Maranhão hampir empat kali lipat Paraná. Penambahan titik distribusi atau mitra kurir alternatif di wilayah ini menyasar bagian masalah yang terbesar.

**5. Selidiki Rio de Janeiro secara terpisah.**
Dasarnya 4.3: RJ mencatat 13,52% keterlambatan padahal transitnya hanya 8,38 hari, atas volume 12.310 pesanan. Pola ini menunjuk ke penetapan tanggal janji, bukan ke kecepatan pengiriman. Perbaikan di sini kemungkinan besar cukup dilakukan lewat penyesuaian rumus estimasi, tanpa biaya operasional tambahan.

**6. Siapkan dua protokol musiman yang berbeda.**
Dasarnya 4.2: Nov 2017 adalah masalah kapasitas gudang, sedangkan Feb–Mar 2018 adalah gangguan jaringan kurir. Musim puncak membutuhkan penambahan kapasitas penanganan di sisi penjual, sementara gangguan jaringan membutuhkan rencana cadangan rute dan mitra. Menyiapkan satu protokol untuk keduanya akan meleset pada salah satunya.

---

## 6. Batasan Analisis

**Cakupan data.** Analisis ini hanya mencakup pesanan berstatus `delivered` yang tanggal terimanya terisi. Pesanan yang dibatalkan, hilang, atau tidak pernah sampai tidak masuk hitungan, sehingga angka keterlambatan di sini adalah batas bawah dari total pengalaman buruk pelanggan.

**Periode.** Data berakhir pada Ags 2018. Tren perbaikan sejak Apr 2018 belum dapat dipastikan bertahan, dan kenaikan pada Ags 2018 belum dapat dipastikan sebagai awal pembalikan arah atau sekadar fluktuasi satu bulan.

**Nilai kerugian.** BRL 1.123.857 adalah nilai pesanan yang terlambat, bukan kerugian yang benar-benar keluar. Data yang tersedia tidak memuat biaya kurir, biaya penanganan keluhan, maupun nilai pelanggan yang berhenti berbelanja, sehingga dampak finansial sesungguhnya tidak dapat dihitung dari sini.

**Ukuran kepuasan.** Kepuasan pelanggan diwakili oleh skor ulasan. 646 pesanan tanpa ulasan dikeluarkan dari perhitungan Q5. Pelanggan yang kecewa tetapi tidak menulis ulasan tidak terwakili.

**Ambang volume.** Peringkat provinsi pada 4.3 memakai batas minimal 500 pesanan. Provinsi bervolume kecil dengan tingkat keterlambatan tinggi — Alagoas dan Piauí — tidak muncul di peringkat tersebut meskipun angkanya lebih buruk.

**Hubungan sebab akibat.** Analisis ini menunjukkan keterkaitan yang kuat antara lama transit dan tingkat keterlambatan, serta antara keterlambatan dan skor ulasan. Penyebab gangguan jaringan pada Feb–Mar 2018 sendiri tidak dapat dipastikan dari data yang tersedia, karena tidak ada informasi mengenai mitra kurir, rute, maupun kejadian eksternal.

---

## 7. Lampiran

**Berkas pendukung**

| Berkas                                                   | Isi                                           |
| -------------------------------------------------------- | --------------------------------------------- |
| `02_sql/01_create_schema.sql` – `03_add_constraints.sql` | Pembuatan skema dan pemuatan data mentah      |
| `02_sql/04_data_quality_audit.sql`                       | Audit kualitas data                           |
| `02_sql/05_build_fact_table.sql`                         | Pembentukan tabel fakta dan penandaan anomali |
| `02_sql/06_analysis_q1_q5.sql`                           | Seluruh query dan kesimpulan Q1–Q5            |
| `02_sql/07_build_seller_view.sql`                        | View kinerja penjual                          |
| `02_sql/08_build_state_ref.sql`                          | Referensi nama dan wilayah provinsi           |
| `03_python/01_validation.ipynb`                          | Validasi silang angka                         |
| `05_dashboard/olist_ops_dashboard.pbix`                  | Dasbor Power BI                               |
| `05_dashboard/olist_ops_dashboard.pdf`                   | Dasbor dalam bentuk PDF                       |

**Definisi istilah**

| Istilah       | Arti                                                                                |
| ------------- | ----------------------------------------------------------------------------------- |
| OTD Rate      | On-Time Delivery Rate, persentase pesanan yang tiba pada atau sebelum tanggal janji |
| Ke kurir      | Selisih hari antara pembelian dan penyerahan barang ke kurir                        |
| Transit       | Selisih hari antara penyerahan ke kurir dan penerimaan oleh pelanggan               |
| Selisih janji | Selisih hari antara tanggal janji dan tanggal pembelian                             |
| BRL           | Real Brasil, mata uang yang dipakai pada data sumber                                |
