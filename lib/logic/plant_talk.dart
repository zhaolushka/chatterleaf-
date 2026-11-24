import 'dart:math';

import '../data/models.dart';
import 'crop_profiles.dart';
import 'format.dart';
import 'mood.dart';
import 'status.dart';

// "Talking plant" — Tamyr's own feature.
//
// How it works:
//  1. Find the TOPIC of the question by keywords: water, temperature, light, "how are you"…
//  2. Take the CURRENT readings of the bed and the thresholds from settings.
//  3. Build the answer from ready-made phrases + real numbers.
//  4. Every plant has a PERSONALITY that changes greetings, complaints and "thank you".
//  5. If the plant feels bad, it offers an action button (water, open window…).
// No internet and no paid AI keys: everything runs on the phone.

enum Personality { cheerful, grumpy, gentle, joker }

Personality personalityFrom(String value) =>
    Personality.values.firstWhere((p) => p.name == value, orElse: () => Personality.cheerful);

/// An action the plant can ask for.
enum PlantAction { water, openWindow, closeWindow, heaterOn, heaterOff, lightOn }

extension PlantActionInfo on PlantAction {
  String get label => switch (this) {
        PlantAction.water => 'Water me',
        PlantAction.openWindow => 'Open window',
        PlantAction.closeWindow => 'Close window',
        PlantAction.heaterOn => 'Turn on heater',
        PlantAction.heaterOff => 'Turn off heater',
        PlantAction.lightOn => 'Turn on light',
      };

  /// Which device in the database to switch.
  String get deviceId => switch (this) {
        PlantAction.water => 'irrigation',
        PlantAction.openWindow || PlantAction.closeWindow => 'window',
        PlantAction.heaterOn || PlantAction.heaterOff => 'heater',
        PlantAction.lightOn => 'light',
      };

  bool get turnOn => this != PlantAction.closeWindow && this != PlantAction.heaterOff;
}

/// A plant message: text + action buttons under it.
class PlantMessage {
  final String text;
  final List<PlantAction> actions;
  const PlantMessage(this.text, [this.actions = const []]);
}

enum Topic { thanks, todo, about, auto, humidity, water, temp, light, howAreYou, greet, unknown }

// Checked top to bottom: the first topic with a matching keyword wins.
// Russian keywords are kept too, so both languages work.
const _keywords = <Topic, List<String>>{
  Topic.thanks: ['thank', 'thx', 'спасиб', 'рахмет'],
  Topic.todo: ['what should i do', 'what do you need', 'help', 'what can i do', 'сделать', 'помощ'],
  Topic.about: ['who are you', 'about you', 'your name', 'tell me about', 'кто ты', 'о себе'],
  Topic.auto: ['auto', 'holiday', 'vacation', 'weekend', 'каникул', 'авто'],
  Topic.humidity: ['air', 'humid', 'воздух'],
  Topic.water: ['thirst', 'water', 'drink', 'dry', 'soil', 'пить', 'полив', 'почв'],
  Topic.temp: ['warm', 'hot', 'cold', 'temp', 'degree', 'heat', 'freez', 'тепл', 'жар', 'холод'],
  Topic.light: ['light', 'sun', 'lamp', 'dark', 'photosynth', 'свет', 'солн'],
  Topic.howAreYou: ['how are you', 'how r u', 'how do you feel', 'how is it going', 'как дела', 'как ты'],
  Topic.greet: ['hi', 'hello', 'hey', 'sälem', 'salem', 'привет', 'сәлем'],
};

Topic detectTopic(String input) {
  final text = input.toLowerCase();
  for (final entry in _keywords.entries) {
    if (entry.value.any(text.contains)) return entry.key;
  }
  return Topic.unknown;
}

bool _asksWhy(String input) {
  final t = input.toLowerCase();
  return t.contains('why') || t.contains('how come') || t.contains('зачем') || t.contains('почему');
}

class _Voice {
  final List<String> hello, happy, complain, thanks, unknown;
  const _Voice({required this.hello, required this.happy, required this.complain, required this.thanks, required this.unknown});
}

const _voices = <Personality, _Voice>{
  Personality.cheerful: _Voice(
    hello: ['Hi-hi!', 'Sälem, friend!', 'Oh hi! So glad you came!'],
    happy: ['I feel great!', 'Life is good!', 'Best mood ever!'],
    complain: ['Oh no!', 'Help!', 'SOS!'],
    thanks: ['Yay, thank you!', 'You’re the best!', 'Such care!'],
    unknown: ['Hmm, didn’t get that — but I’m still happy!', 'Oh, what do you mean?'],
  ),
  Personality.grumpy: _Voice(
    hello: ['Well, hi.', 'Oh, it’s you.', 'Finally. Hello.'],
    happy: ['Fine. I can live with this.', 'Not bad. Not complaining… much.', 'It’ll do.'],
    complain: ['Here we go again!', 'I knew it!', 'Outrageous!'],
    thanks: ['Okay, thanks. I’d have dried up without you.', 'Hmph. Thanks, I guess.', 'About time!'],
    unknown: ['What? Speak clearly.', 'I don’t get your fancy words.'],
  ),
  Personality.gentle: _Voice(
    hello: ['Hello! I’m so happy to see you', 'Hi! It’s lovely that you came!'],
    happy: ['I feel wonderful, thank you for asking!', 'Everything is lovely!'],
    complain: ['Sorry to bother you…', 'I don’t feel very well…'],
    thanks: ['Thank you so, so much!', 'You’re so caring!'],
    unknown: ['Sorry, I didn’t quite understand…', 'Could you ask in another way?'],
  ),
  Personality.joker: _Voice(
    hello: ['Yo! Dilly on the line!', 'Hey hey! What’s up?', 'Hi! Just here, being green.'],
    happy: ['Feeling dill-ightful!', 'All good in the herb-hood!', 'Green with happiness!'],
    complain: ['This is not funny!', 'Jokes are over!', 'No time for puns!'],
    thanks: ['Thanks! You’re my hero!', 'Five stars, would grow again!', 'Now that’s service!'],
    unknown: ['Is that a joke? I didn’t get it — and I’m an expert!', 'Hehe, what does that mean?'],
  ),
};

class PlantTalk {
  PlantTalk({required this.greenhouse, this.devices = const {}, this.online = true, Random? random, DateTime? now})
      : _rnd = random ?? Random(),
        _now = now ?? DateTime.now();

  final Greenhouse greenhouse;
  final Map<String, bool> devices; // irrigation → on?
  final bool online;
  final Random _rnd;
  final DateTime _now;

  static const quickQuestions = ['How are you?', 'Thirsty?', 'Are you warm?', 'Why do you need light?', 'What should I do?', 'Who are you?'];

  Personality get personality => personalityFrom(greenhouse.personality);
  CropProfile get crop => profileFor(greenhouse.cropKey);
  Mood get mood => moodOf(greenhouse, online: online, now: _now);
  String get name => greenhouse.plantName;

  _Voice get _voice => _voices[personality]!;
  String _pick(List<String> options) => options[_rnd.nextInt(options.length)];
  bool _on(String deviceId) => devices[deviceId] == true;

  Readings get _r => greenhouse.current;
  GreenhouseSettings get _s => greenhouse.settings;
  String get _temp => formatTemp(_r.airTemp, _s.units);
  String get _soil => formatPercent(_r.soilMoisture);
  bool get _isDaytime => _now.hour >= 9 && _now.hour < 17;

  /// Short line for cards and the speech bubble.
  String statusLine() => switch (mood) {
        Mood.sleepy => 'Zzz… No new data — last update ${timeAgo(_r.updatedAt, now: _now)}.',
        Mood.hot => '${_pick(_voice.complain)} I’m hot — $_temp! Please open the window.',
        Mood.cold => '${_pick(_voice.complain)} I’m cold — $_temp!',
        Mood.thirsty => '${_pick(_voice.complain)} I’m thirsty — soil at $_soil.',
        Mood.happy => '${_pick(_voice.happy)} $_temp, soil $_soil.',
      };

  /// Alert text in the plant's voice (M5).
  String alertLine(Problem p) => switch (p.param) {
        'airTemp' when _r.airTemp > _s.tempMax => 'I’m so hot, $_temp! Open the window!',
        'airTemp' => 'I’m cold, $_temp… Please turn on the heater.',
        'soilMoisture' => personality == Personality.grumpy ? 'Ugh, drought again — soil at $_soil!' : 'I’m thirsty! Soil is only $_soil.',
        'airHumidity' => 'The air feels wrong — humidity ${formatPercent(_r.airHumidity)}.',
        _ => 'I need more light — only ${formatLux(_r.light)}.',
      };

  PlantMessage greeting() => PlantMessage('${_pick(_voice.hello)} ${statusLine()}', suggestedActions());

  PlantMessage reply(String input) {
    final topic = detectTopic(input);
    final why = _asksWhy(input);
    final sleepy = mood == Mood.sleepy && topic != Topic.about && topic != Topic.thanks
        ? 'Zzz… I haven’t had new data for a while, so here is what I remember. '
        : '';
    return switch (topic) {
      Topic.thanks => PlantMessage(_pick(_voice.thanks)),
      Topic.greet => greeting(),
      Topic.howAreYou => PlantMessage(sleepy + _howAreYou(), suggestedActions()),
      Topic.water => PlantMessage(sleepy + _aboutWater(why), _only({PlantAction.water})),
      Topic.temp => PlantMessage(sleepy + _aboutTemp(why),
          _only({PlantAction.openWindow, PlantAction.heaterOn, PlantAction.closeWindow, PlantAction.heaterOff})),
      Topic.light => PlantMessage(sleepy + _aboutLight(why), _only({PlantAction.lightOn})),
      Topic.humidity => PlantMessage(sleepy + _aboutHumidity(why)),
      Topic.todo => PlantMessage(sleepy + _todo(), suggestedActions()),
      Topic.about => PlantMessage(_about()),
      Topic.auto => PlantMessage(_aboutAuto()),
      Topic.unknown => PlantMessage('${_pick(_voice.unknown)} Ask me “How are you?”, “Thirsty?” or “Why do you need light?”'),
    };
  }

  PlantMessage afterAction(PlantAction action) {
    final reaction = switch (action) {
      PlantAction.water => 'Mmm, water!',
      PlantAction.openWindow => 'Ahh, a fresh breeze!',
      PlantAction.closeWindow => 'No more draft.',
      PlantAction.heaterOn => 'Warming up — much cosier.',
      PlantAction.heaterOff => 'Heater off, it’ll get cooler now.',
      PlantAction.lightOn => 'The sun is on! Time for photosynthesis.',
    };
    return PlantMessage('$reaction ${_pick(_voice.thanks)}');
  }

  /// What the plant asks for right now.
  List<PlantAction> suggestedActions() {
    final actions = <PlantAction>[];
    switch (mood) {
      case Mood.hot:
        if (!_on('window')) actions.add(PlantAction.openWindow);
        if (_on('heater')) actions.add(PlantAction.heaterOff);
      case Mood.cold:
        if (!_on('heater')) actions.add(PlantAction.heaterOn);
        if (_on('window')) actions.add(PlantAction.closeWindow);
      case Mood.thirsty:
        if (!_on('irrigation')) actions.add(PlantAction.water);
      case Mood.happy:
      case Mood.sleepy:
        break;
    }
    if (mood != Mood.sleepy && _isDaytime && _r.light < _s.lightMin && !_on('light')) actions.add(PlantAction.lightOn);
    return actions;
  }

  List<PlantAction> _only(Set<PlantAction> allowed) => suggestedActions().where(allowed.contains).toList();

  String _howAreYou() {
    final parts = <String>[statusLine()];
    if (mood == Mood.happy) parts.add('Air humidity ${formatPercent(_r.airHumidity)}, light ${formatLux(_r.light)}.');
    if (_on('irrigation')) parts.add('I’m being watered right now!');
    return parts.join(' ');
  }

  String _aboutWater(bool why) {
    var text = _on('irrigation')
        ? 'I’m being watered right now — mmm! Soil is already at $_soil.'
        : _r.soilMoisture < _s.soilMin
            ? 'My soil is dry — only $_soil, and I need at least ${_s.soilMin.round()} %. I’m so thirsty!'
            : _r.soilMoisture > 85
                ? 'Soil is $_soil — a bit soggy. No watering for now, or my roots can’t breathe.'
                : 'Soil moisture is $_soil — not thirsty, thanks!';
    if (why) text += ' Water carries nutrients from the soil up my stem, and when it evaporates from my leaves it cools me down.';
    return text;
  }

  String _aboutTemp(bool why) {
    final min = formatTemp(_s.tempMin, _s.units), max = formatTemp(_s.tempMax, _s.units);
    var text = _r.airTemp > _s.tempMax
        ? 'It’s $_temp here, and I’m comfy only up to $max. I’m overheating!'
        : _r.airTemp < _s.tempMin
            ? 'Brrr, only $_temp! I need at least $min.'
            : 'It’s $_temp — just right! I’m happy between $min and $max.';
    if (why) text += ' ${crop.tempFact}';
    return text;
  }

  String _aboutLight(bool why) {
    final lux = formatLux(_r.light);
    var text = !_isDaytime && _r.light < _s.lightMin
        ? 'It’s not daytime, so I’m resting. I need light during the day.'
        : _r.light < _s.lightMin
            ? 'It’s a bit dark: $lux.${_on('light') ? ' The lamp is on, thank you!' : ' Could you turn on the light?'}'
            : 'Plenty of light: $lux.';
    if (why) {
      text += ' I need light for photosynthesis: I turn water and CO₂ into sugar and give oxygen back — the oxygen you breathe!';
    }
    return text;
  }

  String _aboutHumidity(bool why) {
    final h = formatPercent(_r.airHumidity);
    var text = _r.airHumidity > _s.humidityMax
        ? 'The air is too humid — $h. Let’s open the window a bit.'
        : _r.airHumidity < _s.humidityMin
            ? 'The air is dry — $h. It makes me even thirstier.'
            : 'Air humidity is $h — fine.';
    if (why) text += ' In dry air I lose lots of water through my leaves; in very humid air fungus can grow.';
    return text;
  }

  String _todo() {
    final actions = suggestedActions();
    if (mood == Mood.sleepy) return 'Check the connection to the greenhouse — I’m not getting new data.';
    if (actions.isEmpty) return 'Nothing needed, all good! You can just watch me grow.';
    return 'Please: ${actions.map((a) => a.label.toLowerCase()).join(' and ')}. The buttons are right below.';
  }

  String _about() {
    final intro = switch (personality) {
      Personality.cheerful => 'I’m $name — the happiest ${crop.noun} in this greenhouse!',
      Personality.grumpy => 'I’m $name. Just a ${crop.noun}. I grumble, but I’m kind inside.',
      Personality.gentle => 'I’m $name — a gentle little ${crop.noun}. I love care and warm sunshine.',
      Personality.joker => 'I’m $name — the funniest ${crop.noun} around. I keep every joke fresh!',
    };
    return '$intro I feel best at ${crop.idealTemp}. Fun fact: ${crop.funFact}';
  }

  String _aboutAuto() => greenhouse.isAuto
      ? 'I’m in auto mode: I’ll water myself when soil drops below ${_s.soilMin.round()} % and open the window above ${formatTemp(_s.tempMax, _s.units)}. Have a nice holiday!'
      : 'I’m in manual mode. Switch on “Auto” on my page and I’ll look after myself.';
}
