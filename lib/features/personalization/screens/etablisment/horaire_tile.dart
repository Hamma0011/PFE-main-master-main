import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import '../../../shop/models/horaire_model.dart';
import '../../../shop/models/jour_semaine.dart';
import 'heure_button.dart';

class HoraireTileAmeliore extends StatefulWidget {
  final Horaire horaire;
  final Function(Horaire) onChanged;

  const HoraireTileAmeliore({
    super.key,
    required this.horaire,
    required this.onChanged,
  });

  @override
  State<HoraireTileAmeliore> createState() => _HoraireTileAmelioreState();
}

class _HoraireTileAmelioreState extends State<HoraireTileAmeliore> {
  late Horaire _currentHoraire;

  @override
  void initState() {
    super.initState();
    _currentHoraire = widget.horaire;
  }

  void _toggleOuverture(bool estOuvert) {
    setState(() {
      if (estOuvert) {
        _currentHoraire = _currentHoraire.copyWith(
          estOuvert: true,
          ouverture: _currentHoraire.ouverture ?? '09:00',
          fermeture: _currentHoraire.fermeture ?? '18:00',
        );
      } else {
        _currentHoraire = _currentHoraire.copyWith(
          estOuvert: false,
          ouverture: null,
          fermeture: null,
        );
      }
    });
    widget.onChanged(_currentHoraire);
  }

  Future<void> _selectHeure(BuildContext context, bool isOuverture) async {
    final heureActuelle = isOuverture
        ? _currentHoraire.ouverture ?? '09:00'
        : _currentHoraire.fermeture ?? '18:00';
    final initialTime = _parseTime(heureActuelle);

    final TimeOfDay? heureChoisie = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (heureChoisie != null) {
      final heureFormattee =
          '${heureChoisie.hour.toString().padLeft(2, '0')}:${heureChoisie.minute.toString().padLeft(2, '0')}';

      if (!_validerHeures(isOuverture, heureFormattee)) return;

      setState(() {
        _currentHoraire = _currentHoraire.copyWith(
          ouverture: isOuverture ? heureFormattee : _currentHoraire.ouverture,
          fermeture: !isOuverture ? heureFormattee : _currentHoraire.fermeture,
        );
      });
      widget.onChanged(_currentHoraire);
    }
  }

  bool _validerHeures(bool isOuverture, String nouvelleHeure) {
    if (isOuverture && _currentHoraire.fermeture != null) {
      final nouvelleOuverture = _timeToMinutes(nouvelleHeure);
      final fermeture = _timeToMinutes(_currentHoraire.fermeture!);
      if (nouvelleOuverture >= fermeture) {
        TLoaders.errorSnackBar(
            message:
                'L\'heure d\'ouverture doit être avant celle de fermeture');
        return false;
      }
    } else if (!isOuverture && _currentHoraire.ouverture != null) {
      final ouverture = _timeToMinutes(_currentHoraire.ouverture!);
      final nouvelleFermeture = _timeToMinutes(nouvelleHeure);
      if (nouvelleFermeture <= ouverture) {
        TLoaders.errorSnackBar(
            message:
                'L\'heure de fermeture doit être après celle d\'ouverture');
        return false;
      }
    }
    return true;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _getJourAbrege(JourSemaine jour) {
    switch (jour) {
      case JourSemaine.lundi:
        return 'LUN';
      case JourSemaine.mardi:
        return 'MAR';
      case JourSemaine.mercredi:
        return 'MER';
      case JourSemaine.jeudi:
        return 'JEU';
      case JourSemaine.vendredi:
        return 'VEN';
      case JourSemaine.samedi:
        return 'SAM';
      case JourSemaine.dimanche:
        return 'DIM';
    }
  }

  @override
  Widget build(BuildContext context) {
    const couleurJour = Colors.blueAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Badge du jour
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _currentHoraire.estOuvert
                        ? couleurJour
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _getJourAbrege(_currentHoraire.jour),
                      style: TextStyle(
                        color: _currentHoraire.estOuvert
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Nom du jour + heures
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentHoraire.jour.valeur,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _currentHoraire.estOuvert
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentHoraire.estOuvert
                            ? '${_currentHoraire.ouverture ?? "09:00"} - ${_currentHoraire.fermeture ?? "18:00"}'
                            : 'Fermé',
                        style: TextStyle(
                          color: _currentHoraire.estOuvert
                              ? Colors.green[700]
                              : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Switch
                Switch(
                  value: _currentHoraire.estOuvert,
                  onChanged: _toggleOuverture,
                  activeColor: couleurJour,
                ),
              ],
            ),

            // Affichage des boutons si ouvert
            if (_currentHoraire.estOuvert) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: HeureButton(
                      label: 'Ouverture',
                      heure: _currentHoraire.ouverture ?? '09:00',
                      onTap: () => _selectHeure(context, true),
                      couleur: couleurJour,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HeureButton(
                      label: 'Fermeture',
                      heure: _currentHoraire.fermeture ?? '18:00',
                      onTap: () => _selectHeure(context, false),
                      couleur: couleurJour,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
