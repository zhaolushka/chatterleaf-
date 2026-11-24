// «Живая» теплица: каждые 30 секунд пишет новые показания в Firestore
// и выполняет команды устройствам (M3: полив → почва влажнее).
//
// Значения, которые вы меняете руками в консоли Firebase, НЕ затираются:
// симулятор берёт текущее значение из базы и меняет его понемногу.
//
// Запуск: npm start      Остановка: Ctrl+C (так проверяется M8 «нет связи с теплицей»)
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from './common.js';
import { normalReading, round1, clamp } from './model.js';

const TICK_SECONDS = Number(process.env.TICK_SECONDS || 30);
const HISTORY_MINUTES = Number(process.env.HISTORY_MINUTES || 30);

// Насколько быстро показания возвращаются к «обычному дню» (доля за один шаг).
const DRIFT = 0.02;
// Влияние устройств за один шаг (30 с).
const EFFECT = {
  irrigation: { soilMoisture: +3 },
  window: { airTemp: -0.8, airHumidity: -1.5 },
  heater: { airTemp: +0.7, airHumidity: -0.5 },
};
const SOIL_DRYING_PER_TICK = 0.03;

const greenhouses = new Map(); // id → данные документа
const devices = new Map(); // id теплицы → { irrigation: true, ... }
const lastHistory = new Map(); // id теплицы → время последней записи истории

// Подписки: изменения в базе приходят сразу, без лишних запросов.
db.collection('greenhouses').onSnapshot((snap) => {
  for (const change of snap.docChanges()) {
    if (change.type === 'removed') greenhouses.delete(change.doc.id);
    else greenhouses.set(change.doc.id, change.doc.data());
  }
});

db.collectionGroup('devices').onSnapshot((snap) => {
  for (const change of snap.docChanges()) {
    const ghId = change.doc.ref.parent.parent.id;
    const state = devices.get(ghId) || {};
    const isOn = change.type !== 'removed' && change.doc.get('isOn') === true;
    if (state[change.doc.id] !== isOn && change.type !== 'added') {
      console.log(`  ⚡ ${ghId}: ${change.doc.id} → ${isOn ? 'ВКЛ' : 'выкл'}`);
    }
    state[change.doc.id] = isOn;
    devices.set(ghId, state);
  }
});

async function loadLastHistory(ghId) {
  if (lastHistory.has(ghId)) return lastHistory.get(ghId);
  const snap = await db.collection('greenhouses').doc(ghId).collection('history').orderBy('ts', 'desc').limit(1).get();
  const t = snap.empty ? 0 : snap.docs[0].get('ts').toMillis();
  lastHistory.set(ghId, t);
  return t;
}

// «Обычный день» для каждой грядки считаем из её порогов:
// середина диапазона температуры и влажности, размах — четверть диапазона.
function profileFrom(settings = {}) {
  const tMin = settings.tempMin ?? 15, tMax = settings.tempMax ?? 32;
  const hMin = settings.humidityMin ?? 50, hMax = settings.humidityMax ?? 85;
  return { baseTemp: (tMin + tMax) / 2, tempAmp: (tMax - tMin) / 4, baseHumidity: (hMin + hMax) / 2 };
}

async function tick() {
  const now = new Date();
  const jobs = [];

  for (const [id, gh] of greenhouses) {
    const cur = gh.current || {};
    const target = normalReading(now, profileFrom(gh.settings));
    const dev = devices.get(id) || {};

    // 1. Плавно тянем к «обычному дню».
    let airTemp = (cur.airTemp ?? target.airTemp) + (target.airTemp - (cur.airTemp ?? target.airTemp)) * DRIFT;
    let airHumidity = (cur.airHumidity ?? target.airHumidity) + (target.airHumidity - (cur.airHumidity ?? target.airHumidity)) * DRIFT;
    let soilMoisture = (cur.soilMoisture ?? target.soilMoisture) - SOIL_DRYING_PER_TICK;
    let light = target.light;

    // 2. Влияние включённых устройств.
    for (const [deviceId, effect] of Object.entries(EFFECT)) {
      if (!dev[deviceId]) continue;
      airTemp += effect.airTemp || 0;
      airHumidity += effect.airHumidity || 0;
      soilMoisture += effect.soilMoisture || 0;
    }
    if (dev.light) light = Math.max(light, 15000);

    const next = {
      airTemp: round1(clamp(airTemp, -20, 60)),
      airHumidity: round1(clamp(airHumidity, 5, 100)),
      soilMoisture: round1(clamp(soilMoisture, 0, 95)),
      light: Math.round(light),
    };

    // Сразу запоминаем у себя, не дожидаясь, пока подписка пришлёт наше же изменение.
    greenhouses.set(id, { ...gh, current: { ...cur, ...next } });

    const ref = db.collection('greenhouses').doc(id);
    jobs.push(
      ref.update({
        'current.airTemp': next.airTemp,
        'current.airHumidity': next.airHumidity,
        'current.soilMoisture': next.soilMoisture,
        'current.light': next.light,
        'current.updatedAt': FieldValue.serverTimestamp(),
      }),
    );

    // 3. Раз в HISTORY_MINUTES — запись в историю.
    jobs.push(
      loadLastHistory(id).then(async (last) => {
        if (now.getTime() - last < HISTORY_MINUTES * 60_000) return;
        await ref.collection('history').add({ ts: Timestamp.fromDate(now), ...next });
        lastHistory.set(id, now.getTime());
      }),
    );

    const on = Object.entries(dev).filter(([, v]) => v).map(([k]) => k);
    console.log(
      `${now.toLocaleTimeString('ru-RU')} ${id}: ${next.airTemp} °C, возд. ${next.airHumidity} %, ` +
        `почва ${next.soilMoisture} %, ${next.light} лк${on.length ? ' [' + on.join(', ') + ']' : ''}`,
    );
  }

  const results = await Promise.allSettled(jobs);
  results.filter((r) => r.status === 'rejected').forEach((r) => console.error('Ошибка записи:', r.reason?.message));
}

console.log(`Симулятор Тамыра запущен: показания каждые ${TICK_SECONDS} с, история каждые ${HISTORY_MINUTES} мин.`);
console.log('Остановить: Ctrl+C\n');

// Первый шаг — через 3 секунды, чтобы подписки успели загрузить данные.
setTimeout(tick, 3000);
const timer = setInterval(tick, TICK_SECONDS * 1000);

process.on('SIGINT', () => {
  clearInterval(timer);
  console.log('\nСимулятор остановлен. Через 2 минуты приложение покажет «нет новых данных от теплицы».');
  process.exit(0);
});
