import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../data/repositories/horaire/horaire_repository.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../shop/controllers/product/horaire_controller.dart';
import 'horaire_tile.dart';

class GestionHorairesEtablissement extends StatefulWidget {
  final String etablissementId;
  final String nomEtablissement;
  final bool isCreation;

  const GestionHorairesEtablissement({
    super.key,
    required this.etablissementId,
    required this.nomEtablissement,
    this.isCreation = false,
  });

  @override
  State<GestionHorairesEtablissement> createState() =>
      _GestionHorairesEtablissementState();
}

class _GestionHorairesEtablissementState
    extends State<GestionHorairesEtablissement> {
  late final HoraireController _horaireController;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _horaireController = Get.put(HoraireController(HoraireRepository()));
    _initializeHoraires();
  }

  Future<void> _initializeHoraires() async {
    try {
      if (widget.isCreation) {
        _horaireController.initializeHoraires(widget.etablissementId);
      } else {
        await _horaireController.fetchHoraires(widget.etablissementId);
      }
    } catch (e) {
        TLoaders.errorSnackBar(message: 'Impossible de charger les horaires');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sauvegarderHoraires() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final success = widget.isCreation
          ? await _horaireController.createHoraires(
              widget.etablissementId, _horaireController.horaires)
          : await _horaireController.updateAllHoraires(
              widget.etablissementId, _horaireController.horaires);

      Get.back(result: success);
    } catch (e) {
      // print('Erreur lors de la sauvegarde: $e');
      Get.back(result: false);
    } finally {
      setState(() => _saving = false);
    }
  }

  // Appliquer un horaire standard
  Future<void> _appliquerHoraireStandard() async {
    final ouvertureController = TextEditingController(text: '07:00');
    final fermetureController = TextEditingController(text: '22:00');

    await Get.defaultDialog(
      title: 'Définir horaire standard',
      content: Column(
        children: [
          TextField(
            controller: ouvertureController,
            decoration: const InputDecoration(
              labelText: 'Heure d\'ouverture (HH:mm)',
              prefixIcon: Icon(Icons.access_time),
            ),
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: fermetureController,
            decoration: const InputDecoration(
              labelText: 'Heure de fermeture (HH:mm)',
              prefixIcon: Icon(Icons.access_time),
            ),
            keyboardType: TextInputType.datetime,
          ),
        ],
      ),
      textCancel: 'Annuler',
      textConfirm: 'Appliquer',
      onConfirm: () async {
        final ouverture = ouvertureController.text.trim();
        final fermeture = fermetureController.text.trim();

        if (!_isValidTimeFormat(ouverture) || !_isValidTimeFormat(fermeture)) {
          TLoaders.errorSnackBar(
            message: 'Veuillez entrer des heures valides au format HH:mm',
          );
          return;
        }

        setState(() => _saving = true);

        try {
          final nouveauxHoraires = _horaireController.horaires.map((h) {
            return h.copyWith(
              estOuvert: true,
              ouverture: ouverture,
              fermeture: fermeture,
            );
          }).toList();

          _horaireController.horaires.assignAll(nouveauxHoraires);
          _horaireController.horaires.refresh();

          await _horaireController.updateAllHoraires(
            widget.etablissementId,
            nouveauxHoraires,
          );
        } finally {
          setState(() => _saving = false);
          Get.back();
        }
      },
    );
  }

  bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return regex.hasMatch(time);
  }

  // Fermer tous les jours
  Future<void> _toutFermer() async {
    if (_saving) return;

    setState(() => _saving = true);
    try {
      // Fermer tous les horaires localement
      final nouveauxHoraires = _horaireController.horaires.map((h) {
        return h.copyWith(
          estOuvert: false,
          ouverture: null,
          fermeture: null,
        );
      }).toList();

      //  Met à jour la liste réactive
      _horaireController.horaires.assignAll(nouveauxHoraires);
      _horaireController.horaires.refresh();

      //  Sauvegarde dans la base
      final success = await _horaireController.updateAllHoraires(
        widget.etablissementId,
        nouveauxHoraires,
      );

      if (success) {
        //  Attendre un petit délai avant le retour
        await Future.delayed(const Duration(milliseconds: 300));
        Get.back(result: true);
      }
    } catch (e) {
      // print('Erreur lors de la fermeture: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  Widget _buildHorairesList() {
    return Obx(() {
      final horaires = _horaireController.horaires;
      if (horaires.isEmpty) {
        return const Center(
          child: Text(
            'Aucun horaire configuré',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      final horairesTries = horaires.toList()
        ..sort((a, b) => a.jour.index.compareTo(b.jour.index));

      return ListView.builder(
        itemCount: horairesTries.length,
        itemBuilder: (context, index) => HoraireTileAmeliore(
          horaire: horairesTries[index],
          onChanged: _horaireController.updateHoraire,
        ),
      );
    });
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving ? null : () => Get.back(),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _saving ? null : _sauvegarderHoraires,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Sauvegarder'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: Text(
          "Horaires - ${widget.nomEtablissement}",
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'standard', child: Text('Horaire standard')),
              const PopupMenuItem(value: 'fermer', child: Text('Tout fermer')),
            ],
            onSelected: (value) async {
              if (value == 'standard') {
                await _appliquerHoraireStandard();
                await _sauvegarderHoraires();
              } else if (value == 'fermer') {
                await _toutFermer();
                await _sauvegarderHoraires();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue[50],
                  child: Text(
                    widget.isCreation
                        ? 'Définissez les horaires de votre établissement'
                        : 'Modifiez les horaires existants',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
                Expanded(child: _buildHorairesList()),
                _buildActionButtons(),
              ],
            ),
    );
  }
}
