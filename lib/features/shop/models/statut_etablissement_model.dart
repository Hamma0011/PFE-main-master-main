// models/statut_etablissement_model.dart
enum StatutEtablissement { en_attente, approuve, rejete }

extension StatutEtablissementExt on StatutEtablissement {
  String get value {
    switch (this) {
      case StatutEtablissement.en_attente:
        return 'en_attente';
      case StatutEtablissement.approuve:
        return 'approuve';
      case StatutEtablissement.rejete:
        return 'rejete';
      default:
        return 'en_attente';
    }
  }

  static StatutEtablissement fromString(String? s) {
    if (s == null) return StatutEtablissement.en_attente;

    switch (s) {
      case 'en_attente':
        return StatutEtablissement.en_attente;
      case 'approuve':
        return StatutEtablissement.approuve;
      case 'rejete':
        return StatutEtablissement.rejete;
      default:
        return StatutEtablissement.en_attente;
    }
  }

  String get displayName {
    switch (this) {
      case StatutEtablissement.en_attente:
        return 'En attente';
      case StatutEtablissement.approuve:
        return 'Approuvé';
      case StatutEtablissement.rejete:
        return 'Rejeté';
      default:
        return 'En attente';
    }
  }
}
