
vcl 4.1;

backend default {
    .host = "nginx";
    .port = "8080";
    .connect_timeout = 3s;
    .first_byte_timeout = 10s;
    .between_bytes_timeout = 5s;
}

sub vcl_recv {
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
    if (bereq.url ~ "^/news/" && beresp.status == 200) {
        set beresp.ttl = 60s;
        unset beresp.http.Set-Cookie;
    }
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    set resp.http.X-Cache-Hits = obj.hits;
}
