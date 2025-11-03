import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:caferesto/features/shop/models/etablissement_model.dart';
import 'package:flutter/material.dart';

class EtablissementSubtitle extends StatelessWidget {
  const EtablissementSubtitle({super.key, required this.etablissement});
  final Etablissement etablissement;
  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    final userRole = controller.userRole;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etablissement.address,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        if (userRole == 'Admin') ...[
          const SizedBox(height: 4),
          Text(
            'Gérant : ${etablissement.ownerDisplayName}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
