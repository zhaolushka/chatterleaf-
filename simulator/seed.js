// Заполняет базу тестовыми данными (неделя 3):
//  - 2 тестовых аккаунта (учитель школы №12 и вторая школа для проверки M1);
//  - 4 грядки-персонажа школы №12 и 1 грядка второй школы;
//  - текущие показания, 4 устройства, настройки;
//  - историю за 7 дней (каждые 30 минут) со значениями ВНЕ нормы;
//  - журнал включений и несколько оповещений.
// Можно запускать много раз: старые тестовые данные удаляются и создаются заново.
//
// Запуск: npm run seed
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db, auth, DEVICES, DEFAULT_SETTINGS } from './common.js';
import { localHour, normalReading, seededRandom, round1 } from './model.js';

const HOUR = 3600_000;
const now = new Date();

/** Момент «N дней назад в hour часов» по местному времени. */
function atLocal(daysAgo, hour) {
  const localMidnight = now.getTime() - localHour(now) * HOUR;
  return new Date(localMidnight - daysAgo * 24 * HOUR + hour * HOUR);
}

const inWindow = (date, from, to) => date >= from && date <= to;

// ---------- Грядки школьной теплицы и их «происшествия» ----------
const heatFrom = atLocal(1, 13.5), heatTo = atLocal(1, 15.5);
const coldFrom = atLocal(2, 2), coldTo = atLocal(2, 5.5);
const dryFrom = atLocal(4, 9), dryTo = atLocal(3, 7.5);

const SCHOOL_PLACE = 'School No. 12, Kyzylorda';

const SCHOOL_BEDS = [
  {
    id: 'school12-bed1',
    name: 'Bed 1',
    plantName: 'Tomi',
    cropKey: 'tomato',
    personality: 'cheerful',
    mode: 'manual',
    profile: { baseTemp: 22, tempAmp: 5, baseHumidity: 62 },
    settings: { tempMin: 16, tempMax: 30, humidityMin: 50, humidityMax: 75, soilMin: 35 },
    // Вчера днём перегрев до 45 °C — дежурные забыли открыть форточку.
    scenario: (d, r) =>
      inWindow(d, heatFrom, heatTo) ? { ...r, airTemp: round1(43 + Math.random() * 2.5), airHumidity: 35 } : r,
  },
  {
    id: 'school12-bed2',
    name: 'Bed 2',
    plantName: 'Cuke',
    cropKey: 'cucumber',
    personality: 'grumpy',
    mode: 'manual',
    profile: { baseTemp: 25, tempAmp: 4, baseHumidity: 80 },
    settings: { tempMin: 18, tempMax: 32, humidityMin: 70, humidityMax: 92, soilMin: 40 },
    // 3–4 дня назад пропустили полив (выходные): почва высохла до 15 %. Сейчас тоже суховато.
    scenario: (d, r) => {
      if (!inWindow(d, dryFrom, dryTo)) return r;
      const hours = (d - dryFrom) / HOUR;
      return { ...r, soilMoisture: round1(Math.max(14.5, 50 - 1.6 * hours)) };
    },
    current: { soilMoisture: 24 },
  },
  {
    id: 'school12-bed3',
    name: 'Bed 3',
    plantName: 'Berry',
    cropKey: 'strawberry',
    personality: 'gentle',
    mode: 'manual',
    profile: { baseTemp: 20, tempAmp: 4, baseHumidity: 70 },
    settings: { tempMin: 12, tempMax: 27, humidityMin: 60, humidityMax: 80, soilMin: 30 },
    // 2 дня назад ночью отключили отопление: 7–9 °C.
    scenario: (d, r) => (inWindow(d, coldFrom, coldTo) ? { ...r, airTemp: round1(7 + Math.random() * 2) } : r),
  },
  {
    id: 'school12-bed4',
    name: 'Bed 4',
    plantName: 'Dilly',
    cropKey: 'greens',
    personality: 'joker',
    mode: 'auto',
    profile: { baseTemp: 18, tempAmp: 4, baseHumidity: 68 },
    settings: { tempMin: 10, tempMax: 25, humidityMin: 55, humidityMax: 85, soilMin: 35 },
  },
];

// Вторая школа — чтобы проверить M1: её аккаунт не видит грядки школы №12.
const OTHER_BEDS = [
  {
    id: 'school5-bed1',
    name: 'Bed 1',
    plantName: 'Sprout',
    cropKey: 'greens',
    personality: 'cheerful',
    mode: 'manual',
    place: 'School No. 5, Aralsk',
    profile: { baseTemp: 18, tempAmp: 4, baseHumidity: 68 },
    settings: { tempMin: 10, tempMax: 25, soilMin: 35 },
  },
];

const DUTY_STUDENTS = ['Dana (7B)', 'Arman (8A)', 'Miras (7A)', 'Aisha (8B)'];

// ---------- Пользователи ----------
async function getOrCreateUser(email, password, displayName) {
  try {
    const user = await auth.getUserByEmail(email);
    await auth.updateUser(user.uid, { password, displayName });
    return user.uid;
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    const user = await auth.createUser({ email, password, displayName });
    return user.uid;
  }
}

// ---------- Запись одной теплицы ----------
async function seedGreenhouse(def, ownerId, index) {
  const ref = db.collection('greenhouses').doc(def.id);
  await db.recursiveDelete(ref); // удаляем старую версию со всей историей

  const rnd = seededRandom(1000 + index);
  const scenario = def.scenario || ((d, r) => r);

  // История: каждые 30 минут за последние 7 дней.
  const step = 30 * 60_000;
  const start = Math.floor((now.getTime() - 7 * 24 * HOUR) / step) * step;
  const writer = db.bulkWriter();
  let count = 0;
  for (let t = start; t <= now.getTime(); t += step) {
    const d = new Date(t);
    const r = scenario(d, normalReading(d, def.profile, rnd));
    writer.create(ref.collection('history').doc(), { ts: Timestamp.fromDate(d), ...r });
    count++;
  }

  // Текущие показания = модель на «сейчас» + особые значения теплицы.
  const current = { ...normalReading(now, def.profile, rnd), ...(def.current || {}) };

  await ref.set({
    ownerId,
    name: def.name,
    plantName: def.plantName,
    cropKey: def.cropKey,
    personality: def.personality,
    place: def.place || SCHOOL_PLACE,
    mode: def.mode,
    current: { ...current, updatedAt: FieldValue.serverTimestamp() },
    settings: { ...DEFAULT_SETTINGS, ...(def.settings || {}) },
  });

  for (const [id, d] of Object.entries(DEVICES)) {
    writer.set(ref.collection('devices').doc(id), {
      ...d,
      isOn: false,
      changedBy: 'user',
      changedAt: Timestamp.fromDate(atLocal(1, 19.1)),
    });
  }

  // Журнал дежурных: утром и после уроков дежурный поливает грядку.
  for (const day of [2, 1, 0]) {
    for (const [k, hour] of [7.5, 14].entries()) {
      const on = atLocal(day, hour);
      if (on > now) continue;
      const byName = DUTY_STUDENTS[(day * 2 + k + index) % DUTY_STUDENTS.length];
      writer.create(ref.collection('events').doc(), { ts: Timestamp.fromDate(on), deviceId: 'irrigation', isOn: true, by: 'user', byName });
      writer.create(ref.collection('events').doc(), {
        ts: Timestamp.fromDate(new Date(on.getTime() + 2 * 60_000)),
        deviceId: 'irrigation',
        isOn: false,
        by: 'user',
        byName,
      });
    }
  }
  if (def.id === 'school12-bed1') {
    writer.create(ref.collection('events').doc(), { ts: Timestamp.fromDate(atLocal(1, 15.4)), deviceId: 'window', isOn: true, by: 'user', byName: 'Arman (8A)' });
    writer.create(ref.collection('events').doc(), { ts: Timestamp.fromDate(atLocal(1, 18)), deviceId: 'window', isOn: false, by: 'user', byName: 'Aisha (8B)' });
  }

  await writer.close();
  console.log(`  ✓ ${def.plantName} (${def.name}): ${count} записей истории`);
}

async function seedAlerts(ownerId) {
  const old = await db.collection('alerts').where('ownerId', '==', ownerId).get();
  const batch = db.batch();
  old.docs.forEach((d) => batch.delete(d.ref));
  // Оповещения — голосом растений.
  const alerts = [
    { greenhouseId: 'school12-bed1', plantName: 'Tomi', cropKey: 'tomato', param: 'airTemp', value: 45.2, message: 'I was overheating — 45.2 °C! Open the window next time!', ts: atLocal(1, 14.6), read: true },
    { greenhouseId: 'school12-bed3', plantName: 'Berry', cropKey: 'strawberry', param: 'airTemp', value: 7.8, message: 'I’m cold, 7.8 °C… Please turn on the heater.', ts: atLocal(2, 3.5), read: true },
    { greenhouseId: 'school12-bed2', plantName: 'Cuke', cropKey: 'cucumber', param: 'soilMoisture', value: 15, message: 'Ugh, drought again — soil at 15 %!', ts: atLocal(3, 6), read: false },
  ];
  for (const a of alerts) {
    batch.set(db.collection('alerts').doc(), { ...a, ownerId, ts: Timestamp.fromDate(a.ts) });
  }
  await batch.commit();
  console.log(`  ✓ ${alerts.length} оповещения`);
}

// ---------- Запуск ----------
async function main() {
  const password = process.env.SEED_PASSWORD || '';
  if (password.length < 6) {
    console.error('Задайте SEED_PASSWORD в файле .env (минимум 6 символов).');
    process.exit(1);
  }
  const teacherEmail = process.env.TEACHER_EMAIL || 'aigul@tamyr.app';
  const otherEmail = process.env.OTHER_EMAIL || 'school5@tamyr.app';

  console.log('Создаём тестовые аккаунты…');
  const teacherUid = await getOrCreateUser(teacherEmail, password, 'Aigul Nurlanovna');
  const otherUid = await getOrCreateUser(otherEmail, password, 'School No. 5');
  await db.collection('users').doc(teacherUid).set({ name: 'Aigul Nurlanovna', role: 'teacher' });
  await db.collection('users').doc(otherUid).set({ name: 'School No. 5', role: 'teacher' });

  console.log(`Грядки ${teacherEmail}:`);
  for (const [i, g] of SCHOOL_BEDS.entries()) await seedGreenhouse(g, teacherUid, i);
  await seedAlerts(teacherUid);

  console.log(`Грядки ${otherEmail}:`);
  for (const [i, g] of OTHER_BEDS.entries()) await seedGreenhouse(g, otherUid, 10 + i);

  console.log('\nГотово! Войдите в приложение с этими почтами и паролем из .env.');
}

main().catch((e) => {
  console.error('Ошибка:', e.message);
  process.exit(1);
});
