import '../data/models.dart';

/// Crop profile (Agro-intelligence track): preset thresholds and facts for class.
class CropProfile {
  final String key;
  final String title; // "Tomatoes"
  final String noun; // "tomato"
  final String idealTemp; // "20–28 °C"
  final GreenhouseSettings preset;
  final String tempFact;
  final String funFact;

  const CropProfile({
    required this.key,
    required this.title,
    required this.noun,
    required this.idealTemp,
    required this.preset,
    required this.tempFact,
    required this.funFact,
  });
}

const cropProfiles = <String, CropProfile>{
  'tomato': CropProfile(
    key: 'tomato',
    title: 'Tomatoes',
    noun: 'tomato',
    idealTemp: '20–28 °C',
    preset: GreenhouseSettings(tempMin: 16, tempMax: 30, humidityMin: 50, humidityMax: 75, soilMin: 35),
    tempFact: 'Above 30 °C tomato pollen stops working, so no fruit can grow.',
    funFact: 'Tomatoes come from South America, and Europeans once thought they were poisonous!',
  ),
  'cucumber': CropProfile(
    key: 'cucumber',
    title: 'Cucumbers',
    noun: 'cucumber',
    idealTemp: '22–30 °C',
    preset: GreenhouseSettings(tempMin: 18, tempMax: 32, humidityMin: 70, humidityMax: 92, soilMin: 40),
    tempFact: 'Cucumbers love warmth and water: below 15 °C they simply stop growing.',
    funFact: 'A cucumber is about 95 % water.',
  ),
  'strawberry': CropProfile(
    key: 'strawberry',
    title: 'Strawberries',
    noun: 'strawberry',
    idealTemp: '18–25 °C',
    preset: GreenhouseSettings(tempMin: 12, tempMax: 27, humidityMin: 60, humidityMax: 80, soilMin: 30),
    tempFact: 'In the heat strawberries flower less and the berries stay small.',
    funFact: 'Strawberry seeds are on the outside — about 200 on one berry.',
  ),
  'greens': CropProfile(
    key: 'greens',
    title: 'Herbs',
    noun: 'dill',
    idealTemp: '15–22 °C',
    preset: GreenhouseSettings(tempMin: 10, tempMax: 25, humidityMin: 55, humidityMax: 85, soilMin: 35),
    tempFact: 'Dill and parsley like it cool: in the heat they rush to flower.',
    funFact: 'People grew dill in Ancient Egypt — as medicine.',
  ),
};

CropProfile profileFor(String cropKey) => cropProfiles[cropKey] ?? cropProfiles['greens']!;
