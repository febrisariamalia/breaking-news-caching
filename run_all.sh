#!/usr/bin/env bash
# Jalankan dari root repo:  ./run_all.sh   (butuh docker compose + k6)
# Opsional: CONFIGS="B" SCENARIOS="miss" LEVELS="1 10 100" DURATION=30s REPEAT=3 ./run_all.sh
set -u
CONFIGS=${CONFIGS:-"A B C"}
SCENARIOS=${SCENARIOS:-"hit miss mixed"}
LEVELS=${LEVELS:-"1 10 50 100 250 500 1000"}
DURATION=${DURATION:-60s}
REPEAT=${REPEAT:-1}
URL=http://localhost/news/berita-nasional-001

for cfg in $CONFIGS; do
  echo "=== Konfigurasi $cfg: start ==="
  docker compose -f configs/$cfg/docker-compose.yml -p news-app up -d --build
  for i in $(seq 1 60); do
    curl -sf http://localhost/health >/dev/null && break; sleep 2
  done
  sleep 15   # beri waktu probe Varnish menandai backend sehat

  for sc in $SCENARIOS; do
    for vu in $LEVELS; do
      for run in $(seq 1 $REPEAT); do
        out=results/$cfg/$sc; mkdir -p $out
        curl -s -o /dev/null $URL                       # warm-up
        echo "--- cfg=$cfg scenario=$sc VU=$vu run=$run ---"
        k6 run -q -e SCENARIO=$sc -e VUS=$vu -e DURATION=$DURATION \
          --summary-export $out/vu_${vu}_run${run}.json k6/load_test.js
        docker stats --no-stream --format '{{.Name}},{{.CPUPerc}},{{.MemUsage}}' \
          > $out/stats_vu_${vu}_run${run}.csv
        sleep 5
      done
    done
  done

  docker compose -f configs/$cfg/docker-compose.yml -p news-app down -v
done
python3 analyze.py
