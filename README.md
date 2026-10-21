# Multi-Tier Edge Caching System: Portal Berita Nasional (Breaking News)

**Kelompok 5:**
- Mira
- Febri
- Ria
- Careen

## Deskripsi Proyek
Infrastruktur portal berita ini dirancang untuk bertahan dari lonjakan trafik mendadak (skenario *Breaking News*) hingga 1000 Virtual Users (VU). Sistem memanfaatkan arsitektur *multi-tier caching* untuk melindungi database dari ancaman *crash*.

**Komponen Utama:**
- **Varnish Cache:** *Front-end Edge Caching* (menangani 90%+ *cache hit* di depan).
- **Nginx & Web App:** *Backend Origin* yang dilengkapi *internal rate-limiting*.
- **Redis:** *Application Data Cache* untuk kueri yang lolos dari Varnish.

## Cara Menjalankan (Deployment)
1. Pastikan Docker dan Docker Compose telah terpasang di sistem Anda.
2. Buka terminal di dalam direktori proyek ini, lalu jalankan:
   ```bash
   docker-compose up -d
3. Akses portal berita melalui browser di http://localhost.