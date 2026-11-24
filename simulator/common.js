// Подключение к Firebase через Admin SDK.
// Admin SDK работает «от имени сервера» и не проверяет правила безопасности,
// поэтому ключ serviceAccountKey.json — секрет и лежит только у вас на компьютере.
import { readFileSync, existsSync } from 'node:fs';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

const keyPath = process.env.SERVICE_ACCOUNT || './serviceAccountKey.json';
if (!existsSync(keyPath)) {
  console.error(`Не найден ключ ${keyPath}.`);
  console.error('Скачайте его: Консоль Firebase → Настройки проекта → Сервисные аккаунты → Создать ключ.');
  process.exit(1);
}

const serviceAccount = JSON.parse(readFileSync(keyPath, 'utf8'));
initializeApp({ credential: cert(serviceAccount) });

export const db = getFirestore();
export const auth = getAuth();

// Устройства одинаковые во всех теплицах.
export const DEVICES = {
  irrigation: { name: 'Watering', order: 0, powerKw: 0.37, waterLpm: 12 },
  window: { name: 'Window', order: 1, powerKw: 0.05, waterLpm: 0 },
  light: { name: 'Light', order: 2, powerKw: 1.2, waterLpm: 0 },
  heater: { name: 'Heater', order: 3, powerKw: 2.0, waterLpm: 0 },
};

export const DEFAULT_SETTINGS = {
  tempMin: 15,
  tempMax: 32,
  humidityMin: 50,
  humidityMax: 85,
  soilMin: 30,
  lightMin: 2000,
  irrigationMinutes: 2,
  lightOnAt: '06:00',
  lightOffAt: '20:00',
  units: 'C',
};
