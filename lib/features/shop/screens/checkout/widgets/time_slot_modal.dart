import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/repositories/horaire/horaire_repository.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/product/panier_controller.dart';
import '../../../controllers/product/horaire_controller.dart';
import '../../../controllers/product/order_controller.dart';
import '../../../models/horaire_model.dart';
import '../../../models/produit_model.dart';

class TimeSlotModal {
  Future<void> openTimeSlotModal(
      BuildContext context, bool dark, ProduitModel product) async {
    // Use instance getter which handles creation if needed
    final orderController = OrderController.instance;
    
    final cartController = CartController.instance;
    
    // Use Get.put with tag or find if exists to avoid duplicates
    HoraireController horaireController;
    try {
      horaireController = Get.find<HoraireController>();
      // If found but for different etablissement, fetch new ones
    } catch (e) {
      horaireController = Get.put(HoraireController(HoraireRepository()), tag: null);
    }

    // Vérifier que l'ID de l'établissement est valide
    if (product.etablissementId.isEmpty) {
      Get.snackbar(
        "Erreur",
        "L'établissement n'est pas défini pour ce produit.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Charger les horaires
    final horairesResult = await horaireController.fetchHoraires(product.etablissementId);

    // Check if fetchHoraires failed (returned null) or list is empty
    if (horairesResult == null || horairesResult.isEmpty) {
      Get.snackbar(
        "Aucun horaire disponible",
        "L'établissement n'a pas encore défini ses horaires.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Check if there are any valid (open) horaires
    // The list might have 7 items but all closed - that's different from "not defined"
    final hasValidHoraires = horaireController.horaires.any((h) => h.isValid);
    
    if (!hasValidHoraires) {
      Get.snackbar(
        "Aucun créneau disponible",
        "L'établissement est actuellement fermé. Veuillez choisir un autre jour ou contacter l'établissement.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Ouvrir la modale
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? AppColors.eerieBlack : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _buildTimeSlotModalContent(
          context, dark, horaireController, orderController, cartController),
    );
  }

  Widget _buildTimeSlotModalContent(
    BuildContext context,
    bool dark,
    HoraireController horaireController,
    OrderController orderController,
    CartController cartController,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Choisir un créneau de retrait 🕓",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          /// Liste des créneaux
          Expanded(
            child:
                _buildTimeSlotsList(horaireController, orderController, dark),
          ),
          const SizedBox(height: 20),

          /// Bouton de confirmation
          _buildConfirmButton(
              orderController, horaireController, cartController, context),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsList(
    HoraireController horaireController,
    OrderController orderController,
    bool dark,
  ) {
    return Obx(() {
      // Safety check: ensure controllers are initialized
      if (!Get.isRegistered<HoraireController>()) {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (horaireController.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final horaires = horaireController.horaires;
      // Check for valid horaires (open days), not just if list is empty
      final hasValidHoraires = horaires.any((h) => h.isValid);
      if (horaires.isEmpty || !hasValidHoraires) {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text("Aucun créneau disponible")),
        );
      }

// Obtenir le jour actuel
      final today = DateTime.now().weekday; // lundi = 1 ... dimanche = 7

// Trier la liste : le jour courant en premier, puis les jours suivants, puis les jours avant
      horaires.sort((a, b) {
        final aIndex = THelperFunctions.weekdayFromJour(a.jour);
        final bIndex = THelperFunctions.weekdayFromJour(b.jour);

        // Décaler les jours pour que "aujourd'hui" soit en premier
        final aShifted = (aIndex - today + 7) % 7;
        final bShifted = (bIndex - today + 7) % 7;
        return aShifted.compareTo(bShifted);
      });

      return ListView.builder(
        shrinkWrap: true,
        itemCount: horaires.length,
        itemBuilder: (ctx, index) {
          final h = horaires[index];
          final dayLabel = h.jour.valeur;

          if (!h.isValid) {
            return ListTile(
              title: Text(dayLabel),
              subtitle: const Text("Fermé"),
              enabled: false,
            );
          }

          return _buildDayExpansionTile(h, dayLabel, orderController, dark);
        },
      );
    });
  }

  Widget _buildDayExpansionTile(
    Horaire h,
    String dayLabel,
    OrderController orderController,
    bool dark,
  ) {
    final slots =
        THelperFunctions.generateTimeSlots(h.ouverture!, h.fermeture!);
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final targetWeekday = THelperFunctions.weekdayFromJour(h.jour);
    final daysToAdd = (targetWeekday - todayWeekday + 7) % 7;
    final isToday = daysToAdd == 0;

    return ExpansionTile(
      title: Row(
        children: [
          Text(
            isToday ? "$dayLabel (Aujourd’hui)" : dayLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color:
                  isToday ? Colors.green : (dark ? Colors.white : Colors.black),
            ),
          ),
          if (isToday)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.star, color: Colors.green, size: 18),
            ),
        ],
      ),
      initiallyExpanded: orderController.selectedDay.value == dayLabel,
      children: slots
          .map((slot) => _buildTimeSlotItem(
                slot: slot,
                dayLabel: dayLabel,
                isToday: isToday,
                now: now,
                orderController: orderController,
                dark: dark,
              ))
          .toList(),
    );
  }

  Widget _buildTimeSlotItem({
    required String slot,
    required String dayLabel,
    required bool isToday,
    required DateTime now,
    required OrderController orderController,
    required bool dark,
  }) {
    final startParts = slot.split(' - ')[0].split(':').map(int.parse).toList();
    final slotStart =
        DateTime(now.year, now.month, now.day, startParts[0], startParts[1]);
    final isPast = isToday && slotStart.isBefore(now);

    return Obx(() {
      // Safety check: ensure controller is initialized
      if (!Get.isRegistered<OrderController>()) {
        return const SizedBox.shrink();
      }
      final isSelected = orderController.selectedSlot.value == slot &&
          orderController.selectedDay.value == dayLabel;

      return GestureDetector(
        onTap: isPast
            ? null
            : () {
                orderController.definirCreneauSelectionne(dayLabel, slot);
              },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isPast
                ? Colors.grey.shade200
                : isSelected
                    ? Colors.green.withOpacity(
                        0.3) // CORRECTION : Opacité augmentée pour meilleure visibilité
                    : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? Colors.green
                  : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null, // AJOUT : Ombre pour mieux mettre en évidence
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                slot,
                style: TextStyle(
                  color: isPast
                      ? Colors.grey
                      : (isSelected
                          ? Colors.green.shade800
                          : (dark ? Colors.white : Colors.black)),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: isSelected
                      ? 15
                      : 14, // AJOUT : Taille de police légèrement augmentée
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: Colors.green,
                    size: 20), // CORRECTION : Taille d'icône
            ],
          ),
        ),
      );
    });
  }

  Widget _buildConfirmButton(
    OrderController orderController,
    HoraireController horaireController,
    CartController cartController,
    BuildContext context,
  ) {
    return Obx(() {
      // Safety check: ensure controller is initialized
      if (!Get.isRegistered<OrderController>()) {
        return const SizedBox.shrink();
      }
      final hasSelection = orderController.selectedSlot.value != null &&
          orderController.selectedDay.value != null;

      return ElevatedButton.icon(
        onPressed: hasSelection
            ? () => _confirmOrder(
                orderController, horaireController, cartController, context)
            : null,
        icon: const Icon(Icons.check),
        label: const Text("Confirmer le créneau"),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasSelection ? Colors.green : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  Future<void> _confirmOrder(
    OrderController orderController,
    HoraireController horaireController,
    CartController cartController,
    BuildContext context,
  ) async {
    try {
      // Vérifier qu'un créneau est sélectionné
      if (orderController.selectedDay.value == null ||
          orderController.selectedSlot.value == null) {
        Get.snackbar(
          "Créneau manquant",
          "Veuillez sélectionner un jour et un créneau",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Just close the modal and keep the selected slot
      // Order will be created only when user presses "Commander" button in checkout screen
      Navigator.of(context).pop();

      // Show confirmation snackbar
      Get.snackbar(
        "Créneau sélectionné ✅",
        "${orderController.selectedDay.value!} - ${orderController.selectedSlot.value!}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "Erreur",
        "Impossible de sélectionner le créneau: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
