import http from 'k6/http';
import { sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Env: SCENARIO=hit|miss|mixed  VUS=<n>  DURATION=60s  BASE_URL=http://localhost  THINK=0
const BASE = __ENV.BASE_URL || 'http://localhost';
const SCENARIO = __ENV.SCENARIO || 'hit';
const THINK = parseFloat(__ENV.THINK || '0');
const PATH = '/news/berita-nasional-001';

const cacheHit = new Rate('cache_hit');
// Hanya status 200 dianggap sukses; 429/502/503 dihitung gagal.
http.setResponseCallback(http.expectedStatuses(200));

export const options = {
  vus: parseInt(__ENV.VUS || '10'),
  duration: __ENV.DURATION || '60s',
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

function pickUrl() {
  if (SCENARIO === 'miss') return `${BASE}${PATH}?r=${Math.random()}`;
  if (SCENARIO === 'mixed') {
    return Math.random() < 0.1 ? `${BASE}${PATH}?r=${Math.random()}` : `${BASE}${PATH}`;
  }
  return `${BASE}${PATH}`;
}

export default function () {
  const res = http.get(pickUrl());
  cacheHit.add(res.headers['X-Cache'] === 'HIT');
  if (THINK > 0) sleep(THINK);
}
