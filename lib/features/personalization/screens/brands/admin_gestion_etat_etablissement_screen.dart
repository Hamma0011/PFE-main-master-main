import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../data/repositories/etablissement/etablissement_repository.dart';
import '../../controllers/user_controller.dart';
import '../../../shop/controllers/etablissement_controller.dart';
import '../../../shop/models/etablissement_model.dart';
import '../../../shop/models/statut_etablissement_model.dart';

class AdminGestionEtablissementsScreen extends StatefulWidget {
  const AdminGestionEtablissementsScreen({Key? key}) : super(key: key);

  @override
  State<AdminGestionEtablissementsScreen> createState() =>
      _AdminGestionEtablissementsScreenState();
}

class _AdminGestionEtablissementsScreenState
    extends State<AdminGestionEtablissementsScreen> {
  final EtablissementController _etablissementController =
      Get.put(EtablissementController(EtablissementRepository()));
  final UserController _userController = Get.find<UserController>();

  bool _isLoading = false;
  List<Etablissement> _etablissements = [];

  @override
  void initState() {
    super.initState();
    _loadEtablissements();
  }

  Future<void> _loadEtablissements() async {
    setState(() => _isLoading = true);
    try {
      final data = await _etablissementController.getTousEtablissements();
      setState(() => _etablissements = data);
    } catch (e) {
      // print('Erreur chargement établissements: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changerStatut(Etablissement etab) async {
    StatutEtablissement? nouveauStatut = await showDialog<StatutEtablissement>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Modifier le statut"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: StatutEtablissement.values.map((statut) {
              return RadioListTile<StatutEtablissement>(
                title: Text(_getStatutText(statut)),
                value: statut,
                groupValue: etab.statut,
                activeColor: _getStatutColor(statut),
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (nouveauStatut != null && nouveauStatut != etab.statut) {
      setState(() => _isLoading = true);
      final success = await _etablissementController.changeStatutEtablissement(
          etab.id!, nouveauStatut);
      if (success) {
        _loadEtablissements(); // Rafraîchir la liste
      }
      setState(() => _isLoading = false);
    }
  }

  String _getStatutText(StatutEtablissement statut) {
    switch (statut) {
      case StatutEtablissement.approuve:
        return "Approuvé ✓";
      case StatutEtablissement.rejete:
        return "Rejeté ✗";
      case StatutEtablissement.en_attente:
        return "En attente 🕓";
    }
  }

  Color _getStatutColor(StatutEtablissement statut) {
    switch (statut) {
      case StatutEtablissement.approuve:
        return Colors.green;
      case StatutEtablissement.rejete:
        return Colors.red;
      case StatutEtablissement.en_attente:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userController.userRole != 'Admin') {
      return const Scaffold(
        body: Center(
          child: Text(
            "Accès refusé — réservé aux administrateurs",
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: TAppBar(
        title: const Text("Gestion des établissements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEtablissements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _etablissements.isEmpty
              ? const Center(child: Text("Aucun établissement trouvé"))
              : ListView.builder(
                  itemCount: _etablissements.length,
                  itemBuilder: (context, index) {
                    final etab = _etablissements[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatutColor(etab.statut),
                          child: const Icon(Icons.store, color: Colors.white),
                        ),
                        title: Text(etab.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(etab.address),
                            const SizedBox(height: 4),
                            Text(
                              _getStatutText(etab.statut),
                              style: TextStyle(
                                color: _getStatutColor(etab.statut),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _changerStatut(etab),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
