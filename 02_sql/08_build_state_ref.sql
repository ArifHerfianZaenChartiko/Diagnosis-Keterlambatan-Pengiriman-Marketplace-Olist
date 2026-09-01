-- ============================================
-- 08_build_state_ref.sql
-- Tujuan : Tabel rujukan kode provinsi Brasil
-- Alasan : Dataset Olist hanya menyimpan kode 2 huruf tanpa kamus.
--          Nama & wilayah ditambahkan agar dashboard terbaca oleh
--          orang yang tidak hafal geografi Brasil.
-- Grain  : SATU BARIS = SATU PROVINSI
-- ============================================

DROP TABLE IF EXISTS analytics.dim_state;

CREATE TABLE analytics.dim_state (
    state_code  VARCHAR(2) PRIMARY KEY,
    state_name  VARCHAR(40),
    region      VARCHAR(20)
);

INSERT INTO analytics.dim_state (state_code, state_name, region) VALUES
('AC','Acre','Utara'),
('AP','Amapa','Utara'),
('AM','Amazonas','Utara'),
('PA','Para','Utara'),
('RO','Rondonia','Utara'),
('RR','Roraima','Utara'),
('TO','Tocantins','Utara'),
('AL','Alagoas','Timur Laut'),
('BA','Bahia','Timur Laut'),
('CE','Ceara','Timur Laut'),
('MA','Maranhao','Timur Laut'),
('PB','Paraiba','Timur Laut'),
('PE','Pernambuco','Timur Laut'),
('PI','Piaui','Timur Laut'),
('RN','Rio Grande do Norte','Timur Laut'),
('SE','Sergipe','Timur Laut'),
('DF','Distrito Federal','Tengah-Barat'),
('GO','Goias','Tengah-Barat'),
('MT','Mato Grosso','Tengah-Barat'),
('MS','Mato Grosso do Sul','Tengah-Barat'),
('ES','Espirito Santo','Tenggara'),
('MG','Minas Gerais','Tenggara'),
('RJ','Rio de Janeiro','Tenggara'),
('SP','Sao Paulo','Tenggara'),
('PR','Parana','Selatan'),
('RS','Rio Grande do Sul','Selatan'),
('SC','Santa Catarina','Selatan');

SELECT COUNT (*) 
FROM analytics.dim_state;