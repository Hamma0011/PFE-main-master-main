import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/horaire/horaire_repository.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/product/horaire_controller.dart';

class PickUpSlotPicker extends StatelessWidget {
  final horaireController = Get.put(HoraireController(HoraireRepository()));
  final Function(String? pickupDateTime, String dayLabel, String timeRange)
      onSlotSelected;

  //Durée d’un créneau en minutes (modifiable)
  final int slotDurationMinutes;

  PickUpSlotPicker({
    required this.onSlotSelected,
    this.slotDurationMinutes = 30, // 30 minutes par défaut
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final horaires = horaireController.horaires;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            ' Choisir un créneau de retrait',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Liste des jours disponibles
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: horaires.length,
              itemBuilder: (ctx, index) {
                final h = horaires[index];
                final dayLabel = h.jour.valeur;

                if (!h.isValid) {
                  return ListTile(
                    title: Text(dayLabel),
                    subtitle: const Text('Fermé'),
                    enabled: false,
                  );
                }

                // Génération automatique des créneaux
                final slots = _generateSlots(h.ouverture!, h.fermeture!);

                return ExpansionTile(
                  title: Text(dayLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${h.ouverture} - ${h.fermeture} (${slots.length} créneaux)"),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.map((slot) {
                        final timeRange = "${slot['start']} - ${slot['end']}";
                        return OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orangeAccent),
                          ),
                          child: Text(timeRange),
                          onPressed: () {
                            final now = DateTime.now();
                            final targetWeekday =
                                THelperFunctions.weekdayFromJour(h.jour);
                            final daysToAdd =
                                (targetWeekday - now.weekday + 7) % 7;
                            final chosenDate =
                                now.add(Duration(days: daysToAdd));

                            final startParts =
                                (slot['start'] as String).split(':');
                            final pickupDateTime = DateTime(
                              chosenDate.year,
                              chosenDate.month,
                              chosenDate.day,
                              int.parse(startParts[0]),
                              int.parse(startParts[1]),
                            ).toIso8601String();

                            onSlotSelected(
                              pickupDateTime,
                              dayLabel,
                              timeRange,
                            );
                            Navigator.of(context).pop();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Génère des créneaux entre deux heures données
  List<Map<String, String>> _generateSlots(String ouverture, String fermeture) {
    final openParts = ouverture.split(':').map(int.parse).toList();
    final closeParts = fermeture.split(':').map(int.parse).toList();

    final start = Duration(hours: openParts[0], minutes: openParts[1]);
    final end = Duration(hours: closeParts[0], minutes: closeParts[1]);

    final List<Map<String, String>> slots = [];
    var current = start;

    while (current < end) {
      final next = current + Duration(minutes: slotDurationMinutes);
      if (next > end) break;

      final startLabel =
          "${current.inHours.toString().padLeft(2, '0')}:${(current.inMinutes % 60).toString().padLeft(2, '0')}";
      final endLabel =
          "${next.inHours.toString().padLeft(2, '0')}:${(next.inMinutes % 60).toString().padLeft(2, '0')}";

      slots.add({'start': startLabel, 'end': endLabel});
      current = next;
    }

    return slots;
  }
}
