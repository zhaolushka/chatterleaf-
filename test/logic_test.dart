import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamyr/data/models.dart';
import 'package:tamyr/logic/format.dart';
import 'package:tamyr/logic/mood.dart';
import 'package:tamyr/logic/plant_talk.dart';
import 'package:tamyr/logic/status.dart';

// Run: flutter test
void main() {
  final noon = DateTime(2026, 11, 24, 12);
  const settings = GreenhouseSettings(); // tempMin 15, tempMax 32, soilMin 30

  Readings r({double t = 24, double soil = 50, double light = 15000, DateTime? at}) =>
      Readings(airTemp: t, airHumidity: 65, soilMoisture: soil, light: light, updatedAt: at ?? noon.subtract(const Duration(seconds: 20)));

  Greenhouse bed({double t = 24, double soil = 50, String crop = 'tomato', String personality = 'cheerful', DateTime? at}) => Greenhouse(
        id: 'g1',
        ownerId: 'u1',
        name: 'Bed 1',
        plantName: 'Tomi',
        cropKey: crop,
        personality: personality,
        place: 'School',
        mode: 'manual',
        current: r(t: t, soil: soil, at: at),
        settings: settings,
      );

  PlantTalk talk(Greenhouse g, {Map<String, bool> devices = const {}, bool online = true}) =>
      PlantTalk(greenhouse: g, devices: devices, online: online, random: Random(1), now: noon);

  group('thresholds', () {
    test('normal readings — no problems', () => expect(findProblems(r(), settings, now: noon), isEmpty));
    test('45 °C is urgent', () {
      final p = findProblems(r(t: 45), settings, now: noon);
      expect(p.single.param, 'airTemp');
      expect(p.single.level, GhStatus.critical);
    });
    test('darkness at night is fine', () => expect(findProblems(r(light: 0), settings, now: DateTime(2026, 11, 24, 23)), isEmpty));
    test('invalid thresholds are rejected (stress test)', () {
      expect(const GreenhouseSettings(soilMin: -50).validate(), isNotNull);
      expect(const GreenhouseSettings(tempMin: 30, tempMax: 20).validate(), isNotNull);
      expect(const GreenhouseSettings(lightOnAt: '25:00').validate(), isNotNull);
      expect(settings.validate(), isNull);
    });
  });

  group('mood', () {
    test('happy / hot / cold / thirsty / asleep', () {
      expect(moodOf(bed(), now: noon), Mood.happy);
      expect(moodOf(bed(t: 45), now: noon), Mood.hot);
      expect(moodOf(bed(t: 10), now: noon), Mood.cold);
      expect(moodOf(bed(soil: 20), now: noon), Mood.thirsty);
      expect(moodOf(bed(), online: false, now: noon), Mood.sleepy);
      expect(moodOf(bed(at: noon.subtract(const Duration(minutes: 30))), now: noon), Mood.sleepy);
    });
  });

  group('talking plant', () {
    test('understands the main questions', () {
      expect(detectTopic('How are you?'), Topic.howAreYou);
      expect(detectTopic('Thirsty?'), Topic.water);
      expect(detectTopic('Are you warm?'), Topic.temp);
      expect(detectTopic('Why do you need light?'), Topic.light);
      expect(detectTopic('What should I do?'), Topic.todo);
      expect(detectTopic('Who are you?'), Topic.about);
      expect(detectTopic('Thanks!'), Topic.thanks);
      expect(detectTopic('Hello'), Topic.greet);
      expect(detectTopic('Как дела?'), Topic.howAreYou);
      expect(detectTopic('blablabla'), Topic.unknown);
    });

    test('when hot it names the temperature and asks to open the window', () {
      final m = talk(bed(t: 45)).reply('Are you warm?');
      expect(m.text, contains('45.0 °C'));
      expect(m.actions, [PlantAction.openWindow]);
    });

    test('does not ask to open a window that is already open', () {
      expect(talk(bed(t: 45), devices: {'window': true}).suggestedActions(), isNot(contains(PlantAction.openWindow)));
    });

    test('dry soil — asks for water', () {
      final m = talk(bed(soil: 18)).reply('Thirsty?');
      expect(m.text, contains('18 %'));
      expect(m.actions, [PlantAction.water]);
    });

    test('explains photosynthesis', () => expect(talk(bed()).reply('Why do you need light?').text, contains('photosynthesis')));

    test('talks about its own crop', () {
      final m = talk(bed(crop: 'cucumber', personality: 'grumpy')).reply('Who are you?');
      expect(m.text, contains('cucumber'));
      expect(m.text, contains('22–30 °C'));
    });

    test('offline it honestly says the data is old', () {
      final m = talk(bed(), online: false).reply('How are you?');
      expect(m.text, startsWith('Zzz'));
      expect(m.actions, isEmpty);
    });

    test('actions know which device to switch', () {
      expect(PlantAction.water.deviceId, 'irrigation');
      expect(PlantAction.closeWindow.turnOn, isFalse);
    });
  });

  test('Fahrenheit', () {
    expect(formatTemp(100, 'F'), '212 °F');
    expect(formatTemp(21.5, 'C'), '21.5 °C');
  });
}
