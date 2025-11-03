import 'jour_semaine.dart';

class Horaire {
  final String? id;
  final String etablissementId;
  final JourSemaine jour;
  late final String? ouverture;
  late final String? fermeture;
  late final bool estOuvert;

  Horaire({
    this.id,
    required this.etablissementId,
    required this.jour,
    this.ouverture,
    this.fermeture,
    this.estOuvert = false, // Par défaut fermé
  });

  factory Horaire.fromJson(Map<String, dynamic> json) => Horaire(
        id: json['id'],
        etablissementId: json['etablissement_id'],
        jour: JourSemaine.fromString(json['jour']),
        ouverture: json['ouverture'],
        fermeture: json['fermeture'],
        estOuvert: json['est_ouvert'] ?? false, // Par défaut fermé
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'etablissement_id': etablissementId,
        'jour': jour.valeur,
        'ouverture': ouverture,
        'fermeture': fermeture,
        'est_ouvert': estOuvert,
      };

  // Méthode utilitaire pour vérifier si l'horaire est valide
  bool get isValid => estOuvert && ouverture != null && fermeture != null;

  // Méthode pour obtenir l'affichage de l'horaire
  String get displayText {
    if (!estOuvert) return 'Fermé';
    if (ouverture == null || fermeture == null) return 'Horaires non définis';
    return '$ouverture - $fermeture';
  }

  // Créer une copie avec de nouvelles valeurs
  Horaire copyWith({
    String? id,
    String? etablissementId,
    JourSemaine? jour,
    String? ouverture,
    String? fermeture,
    bool? estOuvert,
  }) {
    return Horaire(
      id: id ?? this.id,
      etablissementId: etablissementId ?? this.etablissementId,
      jour: jour ?? this.jour,
      ouverture: ouverture ?? this.ouverture,
      fermeture: fermeture ?? this.fermeture,
      estOuvert: estOuvert ?? this.estOuvert,
    );
  }
}
