vcl 4.1;

import directors;

# Probe kesehatan. Nginx meneruskan /health ke app, jadi Nginx dianggap sehat
# hanya jika rantai Nginx -> App juga sehat.
probe health_probe {
    .url = "/health";
    .interval = 3s;
    .timeout = 1s;
    .window = 5;
    .threshold = 3;
}

backend nginx1 {
    .host = "nginx1";
    .port = "8080";
    .connect_timeout = 3s;
    .first_byte_timeout = 10s;
    .between_bytes_timeout = 5s;
    .probe = health_probe;
}

backend nginx2 {
    .host = "nginx2";
    .port = "8080";
    .connect_timeout = 3s;
    .first_byte_timeout = 10s;
    .between_bytes_timeout = 5s;
    .probe = health_probe;
}

# Jalur darurat: langsung ke aplikasi (melewati Nginx).
backend app1 {
    .host = "app1";
    .port = "5000";
    .connect_timeout = 3s;
    .first_byte_timeout = 10s;
    .between_bytes_timeout = 5s;
    .probe = health_probe;
}

backend app2 {
    .host = "app2";
    .port = "5000";
    .connect_timeout = 3s;
    .first_byte_timeout = 10s;
    .between_bytes_timeout = 5s;
    .probe = health_probe;
}

backend app3 {
    .host = "app3";
    .port = "5000";
    .connect_timeout = 3s;
    .first_byte_timeout = 10s;
    .between_bytes_timeout = 5s;
    .probe = health_probe;
}

backend app4 {
    .host = "app4";
    .port = "5000";
    .connect_timeout = 3s;
    .first_byte_timeout = 10s;
    .between_bytes_timeout = 5s;
    .probe = health_probe;
}

sub vcl_init {
    # Tier 1: Nginx, dibagi rata, yang sakit otomatis dilewati.
    new nginx_pool = directors.round_robin();
    nginx_pool.add_backend(nginx1);
    nginx_pool.add_backend(nginx2);

    # Tier 2: Web App langsung (bypass Nginx).
    new app_pool = directors.round_robin();
    app_pool.add_backend(app1);
    app_pool.add_backend(app2);
    app_pool.add_backend(app3);
    app_pool.add_backend(app4);

    # Prioritas: Nginx dulu; jika seluruh pool Nginx sakit, pindah ke App.
    new tier = directors.fallback();
    tier.add_backend(nginx_pool.backend());
    tier.add_backend(app_pool.backend());
}

sub vcl_recv {
    set req.backend_hint = tier.backend();

    # Health check tidak disimpan di cache.
    if (req.url == "/health") {
        return (pass);
    }

    # Hanya GET dan HEAD yang dapat masuk ke cache.
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Hanya artikel publik yang boleh di-cache.
    if (req.url ~ "^/news/") {
        unset req.http.Cookie;
        unset req.http.Authorization;
        return (hash);
    }

    return (pass);
}

sub vcl_backend_response {
    # Catat backend yang melayani (berguna untuk demo failover).
    set beresp.http.X-Backend = beresp.backend.name;

    if (bereq.url ~ "^/news/" && beresp.status == 200) {
        set beresp.ttl = 60s;
        # Grace: objek kedaluwarsa tetap disajikan (stale) selama backend
        # bermasalah, hingga 1 jam setelah TTL habis.
        set beresp.grace = 1h;
        unset beresp.http.Set-Cookie;
    }
}

# Bila semua backend gagal dan tidak ada objek stale, kembalikan 503 yang rapi.
sub vcl_backend_error {
    set beresp.http.Content-Type = "application/json; charset=utf-8";
    set beresp.status = 503;
    synthetic({"{"error":"Layanan sementara tidak tersedia" }"});
    return (deliver);
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    set resp.http.X-Cache-Hits = obj.hits;
}
