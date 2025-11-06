import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../common/widgets/success_screen/success_screen.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/order/order_repository.dart';
import '../../../../data/repositories/product/produit_repository.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/popups/full_screen_loader.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../personalization/controllers/address_controller.dart';
import '../../models/cart_item_model.dart';
import '../../models/jour_semaine.dart';
import '../../models/order_model.dart';
import '../../../../data/repositories/horaire/horaire_repository.dart';
import 'panier_controller.dart';
import 'checkout_controller.dart';
import 'horaire_controller.dart';
import '../../services/arrival_time_calculator_service.dart';

class OrderController extends GetxController {
  static OrderController get instance {
    try {
      return Get.find<OrderController>();
    } catch (e) {
      // Si non trouvé, le créer (ne devrait pas arriver si GeneralBinding est utilisé)
      return Get.put(OrderController());
    }
  }

  final orderRepository = Get.put(OrderRepository());
  final produitRepository = ProduitRepository.instance;
  final cartController = CartController.instance;
  final userController = UserController.instance;
  final _db = Supabase.instance.client;
  final addressController = AddressController.instance;
  final checkoutController = CheckoutController.instance;

  // Service pour calculer l'heure d'arrivée
  final _arrivalTimeCalculator = ArrivalTimeCalculatorService();

  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;
  final isUpdating = false.obs;
  RealtimeChannel? _ordersChannel;
  final Rxn<Map<String, dynamic>> selectedAddress = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    _sAbonnerCommandesTempsReel();
    ecouterCommandesUtilisateur(); // 👈 Démarrer l'écoute en temps réel
  }

  @override
  void onClose() {
    if (_ordersChannel != null) _db.removeChannel(_ordersChannel!);
    super.onClose();
  }

  /// Écoute les changements dans la table `orders` pour l'utilisateur connecté
  void ecouterCommandesUtilisateur() {
    final userId = userController.user.value.id;
    if (userId.isEmpty) return;

    isLoading.value = true;

    /// Écouter les changements dans la table `orders`
    _db
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((data) {
          orders.value = data.map((row) => OrderModel.fromJson(row)).toList();
          isLoading.value = false;
        });
  }

  /// Récupère les commandes d'un gérant pour un établissement donné
  Future<List<OrderModel>> recupererCommandesGerant(
      String etablissementId) async {
    try {
      isLoading.value = true;
      debugPrint(' Chargement commandes gérant pour: $etablissementId');

      // Utiliser la méthode du repository
      final gerantOrders =
          await orderRepository.fetchOrdersByEtablissement(etablissementId);

      orders.value = gerantOrders;
      debugPrint('${gerantOrders.length} commandes gérant chargées');
      return gerantOrders;
    } catch (e) {
      debugPrint('Erreur recupererCommandesGerant: $e');
      // Ne pas afficher de snackbar ici - laisser l'écran gérer l'erreur
      rethrow; // Relancer pour que l'appelant gère l'erreur
    } finally {
      isLoading.value = false;
    }
  }

  /// Met à jour le statut d'une commande avec notification
  Future<void> mettreAJourStatutCommande({
    required String orderId,
    required OrderStatus newStatus,
    String? refusalReason,
  }) async {
    try {
      isUpdating.value = true;

      final orderIndex = orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) throw 'Commande non trouvée';

      final order = orders[orderIndex];
      final oldStatus = order.status;

      // Gérer le stock selon le changement de statut
      // Si on refuse ou annule, restaurer le stock
      if ((newStatus == OrderStatus.refused ||
              newStatus == OrderStatus.cancelled) &&
          oldStatus == OrderStatus.pending) {
        try {
          debugPrint(
              '🔄 Début de la restauration du stock pour le changement de statut (${oldStatus.name} -> ${newStatus.name})');
          await _augmenterStockCommande(order.items);
          debugPrint('✅ Stock restauré avec succès');
        } catch (e, stackTrace) {
          debugPrint('❌ Erreur lors de la restauration du stock: $e');
          debugPrint('Stack trace: $stackTrace');
          // Continuer même si la restauration du stock échoue
        }
      }

      // Préparer les données de mise à jour
      final updates = {
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (refusalReason != null) {
        updates['refusal_reason'] = refusalReason;
      }

      await orderRepository.updateOrder(orderId, updates);

      // Envoyer une notification au client
      await _envoyerNotificationStatut(order, newStatus, refusalReason);

      TLoaders.successSnackBar(
        title: "Succès",
        message: "Statut mis à jour",
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "Erreur",
        message: "Impossible de mettre à jour: $e",
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Envoie une notification pour les changements de statut
  Future<void> _envoyerNotificationStatut(
    OrderModel order,
    OrderStatus newStatus,
    String? refusalReason,
  ) async {
    try {
      String title = "";
      String message = "";

      switch (newStatus) {
        case OrderStatus.preparing:
          title = "Commande en préparation";
          message =
              "Votre commande #${order.id.substring(0, 8)} est en cours de préparation.";
          break;
        case OrderStatus.ready:
          title = "Commande prête";
          message =
              "Votre commande #${order.id.substring(0, 8)} est prête pour retrait.";
          break;
        case OrderStatus.delivered:
          title = "Commande livrée";
          message = "Votre commande #${order.id.substring(0, 8)} a été livrée.";
          break;
        case OrderStatus.refused:
          title = "Commande refusée";
          message =
              "Votre commande #${order.id.substring(0, 8)} a été refusée. Raison: $refusalReason";
          break;
        default:
          return;
      }

      await _db.from('notifications').insert({
        'user_id': order.userId,
        'title': title,
        'message': message,
        'read': false,
        'etablissement_id': order.etablissementId,
        'receiver_role': 'client',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Erreur notification: $e');
    }
  }

  /// Abonnement en temps réel aux commandes
  void _sAbonnerCommandesTempsReel() {
    try {
      _ordersChannel = _db.channel('public:orders');

      _ordersChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (payload) {
          try {
            final eventType = payload.eventType;
            // Ne traiter que les événements INSERT et UPDATE (les événements DELETE n'ont pas de newRecord)
            if (eventType != PostgresChangeEvent.insert &&
                eventType != PostgresChangeEvent.update) {
              return;
            }

            final updatedOrder = OrderModel.fromJson(payload.newRecord);
            final index = orders.indexWhere((o) => o.id == updatedOrder.id);

            if (index != -1) {
              orders[index] = updatedOrder;
              orders.refresh();
            } else {
              // Vérifier si cette nouvelle commande appartient au gérant actuel
              final currentEtabId = userController.currentEtablissementId;
              if (currentEtabId != null &&
                  updatedOrder.etablissementId == currentEtabId) {
                orders.insert(0, updatedOrder);
                orders.refresh();
              }
            }
          } catch (e) {
            debugPrint('Erreur temps réel: $e');
          }
        },
      );

      _ordersChannel!.subscribe(
        (status, [_]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('Abonnement temps réel activé pour les commandes');
          }
        },
      );
    } catch (e) {
      debugPrint('Erreur abonnement temps réel: $e');
    }
  }

  /// Filtrer les commandes par statut
  List<OrderModel> get commandesEnAttente =>
      orders.where((o) => o.status == OrderStatus.pending).toList();
  List<OrderModel> get commandesActives => orders
      .where((o) =>
          o.status == OrderStatus.preparing || o.status == OrderStatus.ready)
      .toList();
  List<OrderModel> get commandesTerminees => orders
      .where((o) =>
          o.status == OrderStatus.delivered ||
          o.status == OrderStatus.cancelled ||
          o.status == OrderStatus.refused)
      .toList();

  final RxnString selectedDay = RxnString();
  final RxnString selectedSlot = RxnString();

  /// Définit le créneau horaire sélectionné
  void definirCreneauSelectionne(String day, String slot) {
    selectedDay.value = day;
    selectedSlot.value = slot;
  }

  /// Efface le créneau horaire sélectionné
  void effacerCreneauSelectionne() {
    selectedDay.value = null;
    selectedSlot.value = null;
  }

  /// Calcule et définit un créneau par défaut si aucun n'est sélectionné
  /// Le créneau par défaut est : heure de passage de la commande + 1h (Tunis) + 15 min + temps de préparation
  /// Retourne true si le créneau est valide (établissement ouvert), false sinon
  Future<bool> calculerCreneauParDefaut(
      int tempsPreparationMinutes, String etablissementId) async {
    final now = DateTime.now(); // Heure de passage de la commande

    // Calculer la date/heure de retrait :
    // heure de passage de la commande + 1 heure (Tunis) + 15 minutes + temps de préparation
    var pickupDateTime = now.add(Duration(
      hours: 1, // +1h pour être à l'heure locale de Tunis
      minutes: 15 + tempsPreparationMinutes,
    ));

    // Arrondir à l'intervalle de 30 minutes supérieur
    final minutes = pickupDateTime.minute;
    final roundedMinutes = ((minutes / 30).ceil() * 30) % 60;
    final extraHours = ((minutes / 30).ceil() * 30 ~/ 60);
    final roundedHours = pickupDateTime.hour + extraHours;

    // Si on dépasse 23h, passer au jour suivant
    if (roundedHours >= 24) {
      pickupDateTime = pickupDateTime.add(const Duration(days: 1));
      pickupDateTime = DateTime(
        pickupDateTime.year,
        pickupDateTime.month,
        pickupDateTime.day,
        roundedHours % 24,
        roundedMinutes,
      );
    } else {
      pickupDateTime = DateTime(
        pickupDateTime.year,
        pickupDateTime.month,
        pickupDateTime.day,
        roundedHours,
        roundedMinutes,
      );
    }

    // Convertir le weekday en nom de jour français
    final weekday = pickupDateTime.weekday; // 1 = lundi, 7 = dimanche
    final jourSemaine = _weekdayToJourSemaine(weekday);
    final dayName = jourSemaine.valeur;

    // Vérifier si l'établissement est ouvert à ce créneau
    try {
      final horaireController = HoraireController(HoraireRepository());
      await horaireController.fetchHoraires(etablissementId);

      final horaire = horaireController.getHoraireForDay(jourSemaine);

      // Si l'établissement est fermé ce jour-là
      if (horaire == null || !horaire.isValid) {
        return false;
      }

      // Vérifier si l'heure du créneau est dans les horaires d'ouverture
      final creneauHeure =
          '${pickupDateTime.hour.toString().padLeft(2, '0')}:${pickupDateTime.minute.toString().padLeft(2, '0')}';
      final creneauHeureFin = pickupDateTime.add(const Duration(minutes: 30));
      final creneauHeureFinStr =
          '${creneauHeureFin.hour.toString().padLeft(2, '0')}:${creneauHeureFin.minute.toString().padLeft(2, '0')}';

      // Vérifier si le créneau est dans les horaires d'ouverture
      final estDansHoraires = _estDansHorairesOuverture(
        creneauHeure,
        creneauHeureFinStr,
        horaire.ouverture!,
        horaire.fermeture!,
      );

      if (!estDansHoraires) {
        return false;
      }

      // Créer le créneau horaire (format "HH:MM - HH:MM" avec intervalle de 30 minutes)
      final startHour = pickupDateTime.hour.toString().padLeft(2, '0');
      final startMinute = pickupDateTime.minute.toString().padLeft(2, '0');

      // Calculer l'heure de fin (30 minutes après)
      var endDateTime = pickupDateTime.add(const Duration(minutes: 30));

      // Si l'heure de fin dépasse minuit, la limiter à 23:59
      if (endDateTime.day != pickupDateTime.day) {
        endDateTime = DateTime(
          pickupDateTime.year,
          pickupDateTime.month,
          pickupDateTime.day,
          23,
          59,
        );
      }

      final endHour = endDateTime.hour.toString().padLeft(2, '0');
      final endMinute = endDateTime.minute.toString().padLeft(2, '0');

      final slot = '$startHour:$startMinute - $endHour:$endMinute';

      // Définir le créneau sélectionné
      definirCreneauSelectionne(dayName, slot);
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des horaires: $e');
      return false;
    }
  }

  /// Vérifie si un créneau horaire est dans les horaires d'ouverture
  bool _estDansHorairesOuverture(
    String creneauDebut,
    String creneauFin,
    String ouverture,
    String fermeture,
  ) {
    try {
      final creneauDebutMinutes = _timeToMinutes(creneauDebut);
      final creneauFinMinutes = _timeToMinutes(creneauFin);
      final ouvertureMinutes = _timeToMinutes(ouverture);
      final fermetureMinutes = _timeToMinutes(fermeture);

      // Le créneau doit être complètement dans les horaires d'ouverture
      return creneauDebutMinutes >= ouvertureMinutes &&
          creneauFinMinutes <= fermetureMinutes;
    } catch (e) {
      return false;
    }
  }

  /// Convertit une heure au format "HH:MM" en minutes
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Convertit un weekday (1-7) en JourSemaine
  JourSemaine _weekdayToJourSemaine(int weekday) {
    switch (weekday) {
      case 1:
        return JourSemaine.lundi;
      case 2:
        return JourSemaine.mardi;
      case 3:
        return JourSemaine.mercredi;
      case 4:
        return JourSemaine.jeudi;
      case 5:
        return JourSemaine.vendredi;
      case 6:
        return JourSemaine.samedi;
      case 7:
        return JourSemaine.dimanche;
      default:
        return JourSemaine.lundi;
    }
  }

  /// Définit l'adresse sélectionnée
  void definirAdresseSelectionnee(Map<String, dynamic> address) {
    selectedAddress.value = address;
  }

  /// Obtient l'ID de l'établissement d'une commande
  String obtenirIdEtablissement(OrderModel order) {
    return order.etablissementId;
  }

  /// Récupère les commandes de l'utilisateur connecté
  Future<List<OrderModel>> recupererCommandesUtilisateur() async {
    try {
      isLoading.value = true;

      final userOrders = await orderRepository.fetchUserOrders();
      return userOrders;
    } catch (e) {
      TLoaders.warningSnackBar(title: 'Erreur', message: e.toString());
      return [];
    }
  }

  /// Traite une commande (création ou modification)
  Future<void> traiterCommande({
    required double totalAmount,
    required String etablissementId,
    DateTime? pickupDateTime,
    String? pickupDay,
    String? pickupTimeRange,
    String? addressId,
    bool creneauAutoDefini =
        false, // Indique si le créneau a été défini automatiquement
  }) async {
    try {
      TFullScreenLoader.openLoadingDialog(
          'En cours d\'enrgistrer votre commande...', TImages.pencilAnimation);

      final user = AuthenticationRepository.instance.authUser;
      if (user == null || user.id.isEmpty) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: 'Erreur utilisateur',
          message: 'Impossible de récupérer vos informations utilisateur.',
        );
        return;
      }

      // S'assurer qu'on a une adresse sélectionnée
      final selectedAddress = addressController.selectedAddress.value;
      if (selectedAddress.id.isEmpty) {
        TFullScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
          title: 'Adresse manquante',
          message: 'Veuillez sélectionner une adresse de livraison.',
        );
        return;
      }

      // Vérifier si on modifie une commande existante
      final editingOrderId = cartController.editingOrderId.value;
      if (editingOrderId.isNotEmpty) {
        // Mettre à jour la commande existante
        await mettreAJourCommandeExistante(
          orderId: editingOrderId,
          newItems: cartController.cartItems.toList(),
          totalAmount: totalAmount,
          pickupDay: pickupDay ?? '',
          pickupTimeRange: pickupTimeRange ?? '',
          pickupDateTime: pickupDateTime ?? DateTime.now(),
        );
      } else {
        // Calculer le temps de préparation total de la commande
        final preparationTime = _calculerTempsPreparationCommande(
            cartController.cartItems.toList());

        // Si pas de créneau horaire défini OU si créneau auto-défini, calculer l'heure d'arrivée réelle du client
        String? clientArrivalTime;
        debugPrint('🔍 Vérification des créneaux horaires:');
        debugPrint('   - pickupDateTime: $pickupDateTime');
        debugPrint('   - pickupDay: $pickupDay');
        debugPrint('   - pickupTimeRange: $pickupTimeRange');
        debugPrint('   - creneauAutoDefini: $creneauAutoDefini');

        // Calculer l'heure d'arrivée si :
        // 1. Aucun créneau n'est défini (null)
        // 2. OU si le créneau a été défini automatiquement (pas choisi manuellement par l'utilisateur)
        final shouldCalculateArrivalTime = (pickupDateTime == null ||
                pickupDay == null ||
                pickupTimeRange == null) ||
            creneauAutoDefini;

        if (shouldCalculateArrivalTime) {
          debugPrint(
              '🔄 Demande de confirmation pour calculer l\'heure d\'arrivée...');
          debugPrint(
              '   - Raison: ${(pickupDateTime == null || pickupDay == null || pickupTimeRange == null) ? "Créneau non défini" : "Créneau auto-défini"}');
          debugPrint(
              '📍 Adresse client - Latitude: ${selectedAddress.latitude}, Longitude: ${selectedAddress.longitude}');

          // Demander à l'utilisateur s'il accepte d'afficher son heure d'arrivée estimée
          final accepteAffichage = await _demanderConfirmationHeureArrivee();

          if (accepteAffichage == true) {
            // Demander à l'utilisateur de choisir son moyen de transport
            final vehicle = await _demanderChoixMoyenTransport();

            if (vehicle != null) {
              // Calculer l'heure d'arrivée réelle via GraphHopper avec le véhicule choisi
              // Utilise maintenant la localisation GPS actuelle au lieu de l'adresse sauvegardée
              clientArrivalTime =
                  await _arrivalTimeCalculator.calculerHeureArriveeReelle(
                etablissementId: etablissementId,
                vehicle: vehicle,
              );
              if (clientArrivalTime != null) {
                debugPrint(
                    '✅ Heure d\'arrivée calculée et prête à être enregistrée: $clientArrivalTime');
                // Afficher un message de confirmation à l'utilisateur
                TLoaders.successSnackBar(
                  title: 'Heure d\'arrivée estimée',
                  message:
                      'Votre heure d\'arrivée estimée est $clientArrivalTime',
                );
              } else {
                debugPrint(
                    '⚠️ Impossible de calculer l\'heure d\'arrivée, la commande sera enregistrée sans heure d\'arrivée');
                debugPrint('   Raisons possibles:');
                debugPrint('   - Permissions GPS refusées');
                debugPrint('   - Services de localisation désactivés');
                debugPrint('   - Coordonnées GPS invalides');
                debugPrint('   - Clé API GraphHopper non configurée');
                debugPrint('   - Erreur lors de l\'appel à l\'API GraphHopper');
                debugPrint('   - Établissement introuvable');
                TLoaders.warningSnackBar(
                  title: 'Calcul impossible',
                  message:
                      'Impossible de calculer l\'heure d\'arrivée. La commande sera enregistrée sans heure d\'arrivée.',
                );
              }
            } else {
              debugPrint(
                  'ℹ️ L\'utilisateur a annulé le choix du moyen de transport');
            }
          } else {
            debugPrint(
                'ℹ️ L\'utilisateur a refusé d\'afficher son heure d\'arrivée estimée');
          }
        } else {
          debugPrint(
              'ℹ️ Créneau horaire choisi manuellement, pas de calcul d\'heure d\'arrivée nécessaire');
        }

        // Créer une nouvelle commande
        final order = OrderModel(
          id: '', // Laisser la base de données générer l'UUID
          userId: user.id,
          etablissementId: etablissementId,
          status: OrderStatus.pending,
          totalAmount: totalAmount,
          orderDate: DateTime.now(),
          paymentMethod: checkoutController.selectedPaymentMethod.value.name,
          address: selectedAddress,
          deliveryDate: null, // Devrait être null initialement
          items: cartController.cartItems.toList(),
          pickupDateTime: pickupDateTime,
          pickupDay: pickupDay,
          pickupTimeRange: pickupTimeRange,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          preparationTime: preparationTime,
          clientArrivalTime:
              clientArrivalTime, // Heure d'arrivée réelle calculée via GraphHopper
        );

        // Log de débogage pour l'heure d'arrivée qui sera enregistrée
        debugPrint(
            '═══════════════════════════════════════════════════════════');
        debugPrint('📦 CRÉATION DE COMMANDE');
        debugPrint(
            '═══════════════════════════════════════════════════════════');
        debugPrint('🆔 ID Établissement: $etablissementId');
        debugPrint('💰 Montant total: ${totalAmount.toStringAsFixed(2)} DT');
        if (clientArrivalTime != null) {
          debugPrint(
              '🕐 Heure d\'arrivée (client_arrival_time): $clientArrivalTime');
        } else {
          debugPrint('🕐 Heure d\'arrivée: Non définie');
        }
        debugPrint(
            '═══════════════════════════════════════════════════════════');

        // Diminuer le stock des produits stockables commandés AVANT de sauvegarder la commande
        try {
          debugPrint(
              '🔄 Début de la mise à jour du stock avant sauvegarde de la commande');
          await _diminuerStockCommande(order.items);
          debugPrint('✅ Stock mis à jour avec succès');
        } catch (e, stackTrace) {
          debugPrint('❌ Erreur lors de la mise à jour du stock: $e');
          debugPrint('Stack trace: $stackTrace');
          TFullScreenLoader.stopLoading();
          TLoaders.errorSnackBar(
            title: 'Erreur de stock',
            message: 'Erreur lors de la mise à jour du stock: $e',
          );
          return; // Ne pas continuer si la mise à jour du stock échoue
        }

        await orderRepository.saveOrder(order, user.id);

        // Envoyer une notification au gérant de l'établissement
        try {
          await _notifierGerantNouvelleCommande(etablissementId, order);
        } catch (e) {
          debugPrint(
              'Erreur lors de l\'envoi de la notification au gérant: $e');
          // Ne pas bloquer le processus si la notification échoue
        }
      }

      cartController.viderPanier();
      TFullScreenLoader.stopLoading();

      final isEditing = cartController.editingOrderId.value.isNotEmpty;
      Get.offAll(() => SuccessScreen(
          image: TImages.orderCompletedAnimation,
          title: isEditing ? 'Commande modifiée !' : 'Produit(s) commandé(s) !',
          subTitle: isEditing
              ? 'Votre commande a été modifiée avec succès'
              : 'Votre commande est en cours de traitement',
          onPressed: () => Get.offAll(() => const NavigationMenu())));
    } catch (e) {
      TFullScreenLoader.stopLoading();

      TLoaders.warningSnackBar(title: 'Erreur', message: e.toString());
    }
  }

  /// Met à jour une commande existante
  Future<void> mettreAJourCommandeExistante({
    required String orderId,
    required List<CartItemModel> newItems,
    required double totalAmount,
    required String pickupDay,
    required String pickupTimeRange,
    required DateTime pickupDateTime,
  }) async {
    try {
      final orderIndex = orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) {
        throw 'Commande non trouvée';
      }

      final order = orders[orderIndex];

      // Vérifier que la commande peut être modifiée (seulement en attente)
      if (order.status != OrderStatus.pending) {
        throw 'Seules les commandes en attente peuvent être modifiées.';
      }

      // 1. Restaurer le stock des anciens articles
      try {
        debugPrint('🔄 Restauration du stock pour les anciens articles');
        await _augmenterStockCommande(order.items);
        debugPrint('✅ Stock restauré avec succès');
      } catch (e, stackTrace) {
        debugPrint('❌ Erreur lors de la restauration du stock: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      // 2. Diminuer le stock des nouveaux articles
      try {
        debugPrint('🔄 Mise à jour du stock pour les nouveaux articles');
        await _diminuerStockCommande(newItems);
        debugPrint('✅ Stock mis à jour avec succès');
      } catch (e, stackTrace) {
        debugPrint('❌ Erreur lors de la mise à jour du stock: $e');
        debugPrint('Stack trace: $stackTrace');
        // Restaurer le stock précédent en cas d'erreur
        try {
          await _augmenterStockCommande(order.items);
        } catch (_) {
          // Si cela échoue aussi, on continue quand même
        }
        throw 'Erreur lors de la mise à jour du stock';
      }

      // Calculer le nouveau temps de préparation
      final newPreparationTime = _calculerTempsPreparationCommande(newItems);

      // 3. Préparer les données de mise à jour
      final updates = {
        'items': newItems.map((item) => item.toJson()).toList(),
        'total_amount': totalAmount,
        'pickup_day': pickupDay,
        'pickup_time_range': pickupTimeRange,
        'pickup_date_time': pickupDateTime.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'preparation_time': newPreparationTime,
      };

      // 4. Mettre à jour dans la base de données
      await orderRepository.updateOrder(orderId, updates);

      // 5. Récupérer l'ID du gérant pour la notification
      final etablissementResponse = await _db
          .from('etablissements')
          .select('id_owner, name')
          .eq('id', order.etablissementId)
          .maybeSingle();

      if (etablissementResponse != null) {
        final gerantId = etablissementResponse['id_owner']?.toString() ?? '';
        if (gerantId.isNotEmpty) {
          // Notifier le gérant
          await _db.from('notifications').insert({
            'user_id': gerantId,
            'title': 'Commande modifiée',
            'message':
                'Le client a modifié la commande #${orderId.substring(0, 8)}. Nouveau total: ${totalAmount.toStringAsFixed(2)} DT',
            'read': false,
            'etablissement_id': order.etablissementId,
            'receiver_role': 'gérant',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // 6. Recharger les commandes
      await recupererCommandesUtilisateur();
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la commande: $e');
      rethrow;
    }
  }

  /// Annule une commande
  Future<void> annulerCommande(String orderId) async {
    try {
      isUpdating.value = true;

      final orderIndex = orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) {
        throw 'Commande non trouvée';
      }

      final order = orders[orderIndex];

      // Vérifier si la commande peut être annulée (seulement les commandes en attente)
      if (order.status != OrderStatus.pending) {
        TLoaders.errorSnackBar(
          title: "Impossible d'annuler",
          message: "Seules les commandes en attente peuvent être annulées.",
        );
        return;
      }

      // Restaurer le stock des produits si la commande était en attente
      try {
        debugPrint(
            '🔄 Début de la restauration du stock pour l\'annulation de la commande $orderId');
        await _augmenterStockCommande(order.items);
        debugPrint('✅ Stock restauré avec succès');
      } catch (e, stackTrace) {
        debugPrint('❌ Erreur lors de la restauration du stock: $e');
        debugPrint('Stack trace: $stackTrace');
        // Continuer même si la restauration du stock échoue
        // Ne pas bloquer l'annulation de la commande
      }

      // Mettre à jour localement d'abord pour un feedback immédiat de l'UI
      orders[orderIndex] = order.copyWith(status: OrderStatus.cancelled);
      orders.refresh();

      // Mettre à jour dans la base de données
      await orderRepository.updateOrder(orderId, {
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Envoyer une notification à l'établissement
      await _envoyerNotification(
        userId: order.etablissementId, // Cela va à l'établissement
        title: "Commande annulée",
        message: "Le client a annulé la commande #${orderId.substring(0, 8)}",
        etablissementId: order.etablissementId,
        receiverRole: 'gérant',
      );

      TLoaders.successSnackBar(
        title: "Succès",
        message: "Votre commande a été annulée.",
      );
    } catch (e) {
      // Annuler les changements locaux en cas d'erreur
      recupererCommandesUtilisateur(); // Recharger pour obtenir l'état correct
      TLoaders.errorSnackBar(
        title: "Erreur",
        message: "Impossible d'annuler la commande: $e",
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Diminue le stock des produits stockables lors de la création d'une commande
  Future<void> _diminuerStockCommande(List<CartItemModel> items) async {
    debugPrint('📦 Début de la diminution du stock pour ${items.length} items');

    for (final item in items) {
      try {
        debugPrint(
            '📦 Traitement du produit: ${item.productId}, quantité: ${item.quantity}');

        // Récupérer le produit pour vérifier s'il est stockable
        final productResponse = await _db
            .from('produits')
            .select('est_stockable, quantite_stock, product_type, tailles_prix')
            .eq('id', item.productId)
            .single();

        final isStockable = productResponse['est_stockable'] as bool? ?? false;
        debugPrint('📦 Produit ${item.productId} est stockable: $isStockable');

        if (!isStockable) {
          debugPrint('📦 Produit ${item.productId} non stockable, ignoré');
          continue; // Produit non stockable, passer au suivant
        }

        // Pour tous les produits stockables (simples et variables), le stock est dans quantite_stock
        final currentStock =
            (productResponse['quantite_stock'] as num?)?.toInt() ?? 0;
        debugPrint(
            '📦 Stock actuel: $currentStock, quantité à soustraire: ${item.quantity}');

        await produitRepository.updateProductStock(
            item.productId, -item.quantity);
        debugPrint('✅ Stock mis à jour pour produit ${item.productId}');
      } catch (e, stackTrace) {
        debugPrint(
            '❌ Erreur lors de la diminution du stock pour ${item.productId}: $e');
        debugPrint('Stack trace: $stackTrace');
        // Ne pas lancer l'erreur, continuer avec les autres produits
        // mais loguer l'erreur pour le débogage
      }
    }

    debugPrint('📦 Fin de la diminution du stock');
  }

  /// Restaure le stock des produits stockables lors de l'annulation/refus d'une commande
  Future<void> _augmenterStockCommande(List<CartItemModel> items) async {
    debugPrint(
        '📦 Début de la restauration du stock pour ${items.length} items');

    for (final item in items) {
      try {
        debugPrint(
            '📦 Restauration du stock pour produit: ${item.productId}, quantité: ${item.quantity}');

        // Récupérer le produit pour vérifier s'il est stockable
        final productResponse = await _db
            .from('produits')
            .select('est_stockable, quantite_stock, product_type, tailles_prix')
            .eq('id', item.productId)
            .single();

        final isStockable = productResponse['est_stockable'] as bool? ?? false;
        debugPrint('📦 Produit ${item.productId} est stockable: $isStockable');

        if (!isStockable) {
          debugPrint('📦 Produit ${item.productId} non stockable, ignoré');
          continue; // Produit non stockable, passer au suivant
        }

        // Pour tous les produits stockables (simples et variables), le stock est dans quantite_stock
        final currentStock =
            (productResponse['quantite_stock'] as num?)?.toInt() ?? 0;
        debugPrint(
            '📦 Stock actuel: $currentStock, quantité à ajouter: ${item.quantity}');

        await produitRepository.updateProductStock(
            item.productId, item.quantity);
        debugPrint('✅ Stock restauré pour produit ${item.productId}');
      } catch (e, stackTrace) {
        debugPrint(
            '❌ Erreur lors de la restauration du stock pour ${item.productId}: $e');
        debugPrint('Stack trace: $stackTrace');
        // Continuer avec les autres produits même en cas d'erreur
      }
    }

    debugPrint('📦 Fin de la restauration du stock');
  }

  /// Met à jour les détails d'une commande (créneau horaire)
  Future<void> mettreAJourDetailsCommande({
    required String orderId,
    required String pickupDay,
    required String pickupTimeRange,
  }) async {
    try {
      isUpdating.value = true;

      final orderIndex = orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) {
        throw 'Commande non trouvée';
      }

      final order = orders[orderIndex];

      // Vérifier si la commande peut être modifiée (seulement les commandes en attente)
      if (order.status != OrderStatus.pending) {
        TLoaders.errorSnackBar(
          title: "Impossible de modifier",
          message: "Seules les commandes en attente peuvent être modifiées.",
        );
        return;
      }

      // Mettre à jour dans la base de données
      await orderRepository.updateOrder(orderId, {
        'pickup_day': pickupDay,
        'pickup_time_range': pickupTimeRange,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Envoyer une notification à l'établissement
      await _envoyerNotification(
        userId: order.etablissementId,
        title: "Commande modifiée",
        message:
            "Le client a modifié le créneau de retrait pour la commande #${orderId.substring(0, 8)}",
        etablissementId: order.etablissementId,
        receiverRole: 'gérant',
      );

      // Recharger les commandes pour obtenir les données mises à jour
      await recupererCommandesUtilisateur();

      TLoaders.successSnackBar(
        title: "Succès",
        message: "Commande modifiée avec succès",
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "Erreur",
        message: "Impossible de modifier la commande: $e",
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Méthode helper pour envoyer des notifications
  Future<void> _envoyerNotification({
    required String userId,
    required String title,
    required String message,
    required String etablissementId,
    required String receiverRole,
  }) async {
    try {
      await _db.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'read': false,
        'etablissement_id': etablissementId,
        'receiver_role': receiverRole,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Notification envoyée à $receiverRole: $title');
    } catch (e) {
      debugPrint('Erreur envoi notification: $e');
    }
  }

  /// Calcule le temps de préparation total d'une commande
  /// Les produits de catégories différentes peuvent être préparés en parallèle
  /// Retourne le temps maximum entre les catégories (car les catégories sont préparées en parallèle)
  int _calculerTempsPreparationCommande(List<CartItemModel> items) {
    // Grouper les produits par catégorie
    final Map<String, int> timeByCategory = {};

    for (var item in items) {
      final product = item.product;
      if (product != null && product.categoryId.isNotEmpty) {
        // Pour chaque catégorie, additionner les temps de préparation
        // (produits de la même catégorie sont préparés séquentiellement)
        final categoryTime = product.preparationTime * item.quantity;
        timeByCategory[product.categoryId] =
            (timeByCategory[product.categoryId] ?? 0) + categoryTime;
      }
    }

    // Si aucune catégorie trouvée, retourner 0
    if (timeByCategory.isEmpty) return 0;

    // Retourner le maximum entre les catégories
    // (car les catégories différentes sont préparées en parallèle)
    return timeByCategory.values.reduce((a, b) => a > b ? a : b);
  }

  /// Notifie le gérant lorsqu'une nouvelle commande est reçue
  Future<void> _notifierGerantNouvelleCommande(
      String etablissementId, OrderModel order) async {
    try {
      debugPrint(
          '🔔 Début de la notification au gérant pour l\'établissement: $etablissementId');

      // Récupérer directement l'ID du gérant depuis la base de données
      final etablissementResponse = await _db
          .from('etablissements')
          .select('id_owner, name')
          .eq('id', etablissementId)
          .maybeSingle();

      if (etablissementResponse == null) {
        debugPrint('⚠️ Établissement non trouvé: $etablissementId');
        return;
      }

      final gerantId = etablissementResponse['id_owner']?.toString() ?? '';
      final etablissementName =
          etablissementResponse['name']?.toString() ?? 'l\'établissement';

      if (gerantId.isEmpty) {
        debugPrint(
            '⚠️ Aucun gérant trouvé pour l\'établissement: $etablissementId');
        return;
      }

      // Calculer le nombre total d'articles
      final totalItems =
          order.items.fold<int>(0, (sum, item) => sum + item.quantity);

      // Créer le message de notification avec le nom de l'établissement
      final message =
          'Nouvelle commande reçue pour $etablissementName : $totalItems article${totalItems > 1 ? 's' : ''} pour un montant total de ${order.totalAmount.toStringAsFixed(2)} DT';

      // Envoyer la notification au gérant
      await _db.from('notifications').insert({
        'user_id': gerantId,
        'title': 'Nouvelle commande reçue',
        'message': message,
        'read': false,
        'etablissement_id': etablissementId,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Notification envoyée au gérant $gerantId pour la commande');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la notification au gérant: $e');
      debugPrint('Stack trace: $stackTrace');
      // Ne pas lancer l'erreur pour ne pas bloquer le processus de commande
    }
  }

  /// Demande à l'utilisateur s'il accepte d'afficher son heure d'arrivée estimée
  /// Retourne true si accepté, false si refusé, null si annulé
  Future<bool?> _demanderConfirmationHeureArrivee() async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Heure d\'arrivée estimée',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Souhaitez-vous que nous calculions et affichions votre heure d\'arrivée estimée à l\'établissement ?\n\n'
            'Nous utiliserons votre position GPS et le moyen de transport que vous choisirez pour estimer votre temps de trajet.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text(
                'Non',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Oui'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      return result;
    } catch (e) {
      debugPrint('❌ Erreur lors de la demande de confirmation: $e');
      return null;
    }
  }

  /// Demande à l'utilisateur de choisir son moyen de transport
  /// Retourne le véhicule choisi ou null si annulé
  Future<GraphHopperVehicle?> _demanderChoixMoyenTransport() async {
    try {
      final result = await Get.dialog<GraphHopperVehicle>(
        _VehicleSelectionDialog(),
        barrierDismissible: false,
      );

      return result;
    } catch (e) {
      debugPrint('❌ Erreur lors du choix du moyen de transport: $e');
      return null;
    }
  }
}

/// Widget pour sélectionner le moyen de transport
class _VehicleSelectionDialog extends StatefulWidget {
  @override
  State<_VehicleSelectionDialog> createState() =>
      _VehicleSelectionDialogState();
}

class _VehicleSelectionDialogState extends State<_VehicleSelectionDialog> {
  GraphHopperVehicle selectedVehicle = GraphHopperVehicle.car;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Choisissez votre moyen de transport',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: GraphHopperVehicle.values.map((vehicle) {
            return RadioListTile<GraphHopperVehicle>(
              title: Text(vehicle.label),
              value: vehicle,
              groupValue: selectedVehicle,
              onChanged: (GraphHopperVehicle? value) {
                if (value != null) {
                  setState(() {
                    selectedVehicle = value;
                  });
                }
              },
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: null),
          child: const Text(
            'Annuler',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Utiliser le véhicule sélectionné
            Get.back(result: selectedVehicle);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
