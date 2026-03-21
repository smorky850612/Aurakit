/**
 * Cloudflare Pages Function — POST /api/admin
 * 관리자 통계 API. 비밀번호 검증 후 방문자 통계 반환.
 * KV binding: VISITORS
 * Env var: ADMIN_PW (Cloudflare Pages → Settings → Environment variables)
 */
export async function onRequestPost(context) {
  const { request, env } = context;

  const cors = {
    'Access-Control-Allow-Origin': request.headers.get('origin') || '',
    'Access-Control-Allow-Methods': 'POST',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };

  try {
    const body = await request.json();
    const { password } = body;

    if (!env.ADMIN_PW || !password || password !== env.ADMIN_PW) {
      return Response.json({ ok: false, error: '비밀번호가 틀렸습니다.' }, { status: 401, headers: cors });
    }

    if (!env.VISITORS) {
      return Response.json({ ok: false, error: 'KV not bound' }, { status: 500, headers: cors });
    }

    // 최근 7일 데이터 수집
    const days = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(Date.now() - i * 86400000).toISOString().slice(0, 10);
      const count = parseInt((await env.VISITORS.get(`d:${date}`)) || '0');
      days.push({ date, count });
    }

    const total = parseInt((await env.VISITORS.get('total')) || '0');
    const today = days[days.length - 1].count;
    const yesterday = days[days.length - 2].count;
    const weeklySum = days.reduce((sum, d) => sum + d.count, 0);

    return Response.json({
      ok: true,
      total,
      today,
      yesterday,
      weeklySum,
      days,
    }, { headers: cors });
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
