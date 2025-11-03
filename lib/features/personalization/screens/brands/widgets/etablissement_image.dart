import 'package:caferesto/features/shop/models/etablissement_model.dart';
import 'package:flutter/material.dart';

class EtablissementImage extends StatelessWidget {
  const EtablissementImage({super.key, required this.etablissement});
  final Etablissement etablissement;
  @override
  Widget build(BuildContext context) {
    if (etablissement.imageUrl != null && etablissement.imageUrl!.isNotEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(etablissement.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Image par défaut
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue.shade50,
        ),
        child: Icon(Icons.business, color: Colors.blue.shade600, size: 24),
      );
    }
  }
}
