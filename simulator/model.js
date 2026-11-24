// Модель «обычного дня» в теплице. Не зависит от Firebase — можно проверить отдельно.

// Время теплиц — Кызылорда, UTC+5.
const TZ_OFFSET_HOURS = 5;

/** Час дня (0–24, с дробной частью) по местному времени. */
export function localHour(date) {
  const h = date.getUTCHours() + date.getUTCMinutes() / 60 + TZ_OFFSET_HOURS;
  return ((h % 24) + 24) % 24;
}

/** Генератор случайных чисел с зерном: при каждом запуске seed.js данные одинаковые. */
export function seededRandom(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const round1 = (v) => Math.round(v * 10) / 10;
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

/**
 * Показания в момент времени для «нормального» дня.
 * profile: { baseTemp, tempAmp, baseHumidity } — у каждой теплицы свои.
 * rnd: функция случайных чисел 0..1 для небольшого шума.
 */
export function normalReading(date, profile, rnd = Math.random) {
  const h = localHour(date);
  const wave = Math.sin((2 * Math.PI * (h - 9)) / 24); // максимум около 15:00
  const noise = (size) => (rnd() - 0.5) * 2 * size;

  const airTemp = profile.baseTemp + profile.tempAmp * wave + noise(0.6);
  const airHumidity = profile.baseHumidity - 12 * wave + noise(2);

  // Солнце с 6:00 до 20:00, днём бывают облака.
  const light = h >= 6 && h <= 20 ? 22000 * Math.sin((Math.PI * (h - 6)) / 14) * (0.75 + 0.25 * rnd()) : 0;

  // Полив по расписанию в 7:00 и 19:00, между поливами почва сохнет ~1.6 % в час.
  const sinceWatering = h >= 19 ? h - 19 : h >= 7 ? h - 7 : h + 5;
  const soilMoisture = 68 - 1.6 * sinceWatering + noise(1);

  return {
    airTemp: round1(clamp(airTemp, -20, 60)),
    airHumidity: round1(clamp(airHumidity, 5, 100)),
    soilMoisture: round1(clamp(soilMoisture, 0, 100)),
    light: Math.round(Math.max(0, light)),
  };
}

export { round1, clamp };
