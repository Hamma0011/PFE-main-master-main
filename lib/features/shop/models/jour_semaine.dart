enum JourSemaine {
  lundi('lundi'),
  mardi('mardi'),
  mercredi('mercredi'),
  jeudi('jeudi'),
  vendredi('vendredi'),
  samedi('samedi'),
  dimanche('dimanche');

  const JourSemaine(this.valeur);
  final String valeur;

  factory JourSemaine.fromString(String valeur) {
    switch (valeur) {
      case 'lundi':
        return JourSemaine.lundi;
      case 'mardi':
        return JourSemaine.mardi;
      case 'mercredi':
        return JourSemaine.mercredi;
      case 'jeudi':
        return JourSemaine.jeudi;
      case 'vendredi':
        return JourSemaine.vendredi;
      case 'samedi':
        return JourSemaine.samedi;
      case 'dimanche':
        return JourSemaine.dimanche;
      default:
        throw ArgumentError('Jour inconnu: $valeur');
    }
  }

  @override
  String toString() => valeur;
}
