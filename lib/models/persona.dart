/// Plant personalities used by [PersonaEngine] for chat / alerts.
enum Persona {
  tomatoDramaQueen('tomato', 'Tomato "Drama Queen"', 'Tomato'),
  basilChillOne('basil', 'Basil "Chill One"', 'Basil'),
  succulentZenMaster('succulent', 'Succulent "Zen Master"', 'Succulent'),
  orchidDiva('orchid', 'Orchid "Diva"', 'Orchid');

  const Persona(this.id, this.displayName, this.shortName);

  final String id;
  final String displayName;
  final String shortName;

  static Persona fromId(String? id) {
    switch (id) {
      case 'basil':
        return Persona.basilChillOne;
      case 'succulent':
        return Persona.succulentZenMaster;
      case 'orchid':
        return Persona.orchidDiva;
      case 'tomato':
      default:
        return Persona.tomatoDramaQueen;
    }
  }
}

/// Kept for defense Q&A / older call sites (`PersonaX.fromId`).
typedef PersonaX = Persona;
