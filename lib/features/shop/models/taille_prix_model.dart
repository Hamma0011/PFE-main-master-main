class TaillePrix {
  final String taille;
  final double prix;

  TaillePrix({
    required this.taille,
    required this.prix,
  });

  factory TaillePrix.fromJson(Map<String, dynamic> json) {
    return TaillePrix(
      taille: json['taille'] as String,
      prix: (json['prix'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taille': taille,
      'prix': prix,
    };
  }

  @override
  String toString() {
    return 'TaillePrix{taille: $taille, prix: $prix}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TaillePrix &&
              runtimeType == other.runtimeType &&
              taille == other.taille;

  @override
  int get hashCode => taille.hashCode;
}