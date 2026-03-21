/**
 * Cloudflare Pages Function — POST /api/track
 * UUID 기반 unique visitor 추적. 같은 UUID = 같은 사람 = 1 카운트.
 * KV binding: VISITORS (환경변수에서 설정 필요)
 */
export async function onRequestPost(context) {
  const { request, env } = context;

  const origin = request.headers.get('origin') || '';
  const cors = {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };

  try {
    const body = await request.json();
    const uuid = (body.uuid || '').trim();

    if (!uuid || uuid.length > 128 || !/^[a-f0-9-]+$/.test(uuid)) {
      return Response.json({ ok: false }, { status: 400, headers: cors });
    }

    if (!env.VISITORS) {
      return Response.json({ ok: false, error: 'KV not bound' }, { status: 500, headers: cors });
    }

    const today = new Date().toISOString().slice(0, 10); // "2026-03-21"

    // 이 UUID가 오늘 처음 방문인지 확인
    const dayKey = `d:${today}:${uuid}`;
    const isNewToday = !(await env.VISITORS.get(dayKey));

    // 이 UUID가 전체적으로 처음인지 확인
    const uuidKey = `v:${uuid}`;
    const isNewEver = !(await env.VISITORS.get(uuidKey));

    if (isNewEver) {
      await env.VISITORS.put(uuidKey, today);
      // total 카운터 증가
      const total = parseInt((await env.VISITORS.get('total')) || '0') + 1;
      await env.VISITORS.put('total', String(total));
    }

    if (isNewToday) {
      // 오늘 방문 마킹 (30일 후 자동 삭제)
      await env.VISITORS.put(dayKey, '1', { expirationTtl: 60 * 60 * 24 * 30 });
      // 일별 카운터 증가
      const dayCount = parseInt((await env.VISITORS.get(`d:${today}`)) || '0') + 1;
      await env.VISITORS.put(`d:${today}`, String(dayCount), { expirationTtl: 60 * 60 * 24 * 90 });
    }

    return Response.json({ ok: true, isNew: isNewEver, isNewToday }, { headers: cors });
  } catch {
    return Response.json({ ok: false }, { status: 500, headers: cors });
  }
}

export async function onRequestOptions() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
