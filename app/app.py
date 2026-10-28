import json
import os

import redis
from flask import Flask, jsonify

app = Flask(__name__)

redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    decode_responses=True,
    socket_connect_timeout=2,
    socket_timeout=2,
)

ARTICLES = {
    "berita-nasional-001": {
        "id": "berita-nasional-001",
        "title": "Breaking News: Perkembangan Nasional",
        "category": "Nasional",
        "author": "Redaksi Portal Berita",
        "content": (
            "Artikel simulasi untuk menguji "
            "multi-tier caching dengan Varnish dan Redis."
        ),
    }
}


@app.get("/health")
def health():
    return jsonify({
        "status": "healthy",
        "service": "news-backend"
    }), 200


@app.get("/news/<article_id>")
def get_article(article_id):
    cache_key = f"article:{article_id}"

    # Tier 2: periksa cache Redis
    try:
        cached = redis_client.get(cache_key)

        if cached is not None:
            response = jsonify(json.loads(cached))
            response.headers["X-Redis-Cache"] = "HIT"
            return response, 200

    except redis.RedisError:
        app.logger.exception("Gagal membaca Redis")

    # Data sumber simulasi (origin)
    article = ARTICLES.get(article_id)

    if article is None:
        return jsonify({
            "error": "Artikel tidak ditemukan"
        }), 404

    # Simpan artikel ke Redis dengan TTL 300 detik
    try:
        redis_client.setex(
            cache_key,
            300,
            json.dumps(article)
        )
    except redis.RedisError:
        app.logger.exception("Gagal menyimpan ke Redis")

    response = jsonify(article)
    response.headers["X-Redis-Cache"] = "MISS"
    return response, 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
