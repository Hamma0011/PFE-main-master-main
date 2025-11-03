import 'package:get/get.dart';
import '../../../../data/repositories/horaire/horaire_repository.dart';
import '../../models/horaire_model.dart';
import '../../models/jour_semaine.dart';

class HoraireController extends GetxController {
  final HoraireRepository repository;
  final RxList<Horaire> horaires = <Horaire>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasHoraires = false.obs;

  HoraireController(this.repository);

  // Initialiser les horaires vides pour un établissement donné
  void initializeHoraires(String etablissementId) {
    try {
      final horairesVides = JourSemaine.values
          .map((jour) => Horaire(
                etablissementId: etablissementId,
                jour: jour,
                estOuvert: false,
                ouverture: null, // null quand fermé
                fermeture: null, // null quand fermé
              ))
          .toList();

      horaires.assignAll(horairesVides);
      hasHoraires.value = false;
      horaires.refresh();
      print(
          '${horaires.length} horaires initialisés pour l\'établissement $etablissementId');
    } catch (e) {
      print('Erreur initialisation horaires: $e');
    }
  }

  // Initialiser les horaires vides pour la création
  void initializeHorairesForCreation() {
    final horairesVides = JourSemaine.values
        .map((jour) => Horaire(
              etablissementId: 'temp_id',
              jour: jour,
              estOuvert: false,
              ouverture: null, // null quand fermé
              fermeture: null, // null quand fermé
            ))
        .toList();

    horaires.assignAll(horairesVides);
    hasHoraires.value = false;
    horaires.refresh();
    print('${horaires.length} horaires initialisés pour création');
  }

  // Créer les horaires pour un établissement
  Future<bool> createHoraires(
      String etablissementId, List<Horaire> horairesList) async {
    try {
      isLoading.value = true;

      final horairesAvecVraiId = horairesList
          .map((horaire) => horaire.copyWith(
                etablissementId: etablissementId,
              ))
          .toList();

      await repository.createHorairesForEtablissement(
          etablissementId, horairesAvecVraiId);
      horaires.assignAll(horairesAvecVraiId);
      hasHoraires.value = horairesAvecVraiId.any((h) => h.isValid);
      horaires.refresh();

      print(
          '${horairesAvecVraiId.length} horaires créés pour l\'établissement $etablissementId');
      return true;
    } catch (e) {
      _logError('création des horaires', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Récupérer les horaires depuis la base - CORRIGÉE
  Future<List<Horaire>?> fetchHoraires(String etablissementId) async {
    try {
      isLoading.value = true;
      final horairesList =
          await repository.getHorairesByEtablissement(etablissementId);

      // MAINTENANT: On aura toujours des horaires (soit existants, soit créés par défaut)
      horaires.assignAll(horairesList);
      hasHoraires.value = horairesList.any((h) => h.isValid);
      horaires.refresh();

      print(
          '${horairesList.length} horaires chargés pour l\'établissement $etablissementId');

      // Vérification
      if (horairesList.length != 7) {
        print('Attention: ${horairesList.length}/7 jours trouvés');
      } else {
        print('Tous les 7 jours sont présents !');

        // Debug: Afficher l'état de chaque jour
        for (final horaire in horairesList) {
          print(
              '${horaire.jour.valeur}: ${horaire.estOuvert ? "Ouvert" : "Fermé"} ${horaire.estOuvert ? "(${horaire.ouverture} - ${horaire.fermeture})" : ""}');
        }
      }

      return horairesList;
    } catch (e) {
      _logError('récupération des horaires', e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour un horaire spécifique
  Future<bool> updateHoraire(Horaire horaire) async {
    try {
      // Mettre à jour localement d'abord
      final index = horaires.indexWhere((h) => h.id == horaire.id);
      if (index != -1) {
        horaires[index] = horaire;
      } else {
        final indexByDay = horaires.indexWhere((h) => h.jour == horaire.jour);
        if (indexByDay != -1) {
          horaires[indexByDay] = horaire;
        } else {
          // Ajouter si pas trouvé
          horaires.add(horaire);
        }
      }

      hasHoraires.value = horaires.any((h) => h.isValid);
      horaires.refresh();

      // Sauvegarder en base si l'horaire a un ID
      if (horaire.id != null) {
        await repository.updateHoraire(horaire);
        print('Horaire ${horaire.jour.valeur} mis à jour (ID: ${horaire.id})');
      } else {
        print(
            'Horaire ${horaire.jour.valeur} mis à jour localement (pas d\'ID)');
      }

      return true;
    } catch (e) {
      _logError('mise à jour de l\'horaire', e);
      return false;
    }
  }

  // Mettre à jour tous les horaires
  Future<bool> updateAllHoraires(
      String etablissementId, List<Horaire> newHoraires) async {
    try {
      isLoading.value = true;
      await repository.updateAllHoraires(etablissementId, newHoraires);
      horaires.assignAll(newHoraires);
      hasHoraires.value = newHoraires.any((h) => h.isValid);
      horaires.refresh();
      return true;
    } catch (e) {
      _logError('mise à jour de tous les horaires', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Supprimer tous les horaires
  Future<bool> clearHoraires(String etablissementId) async {
    try {
      isLoading.value = true;
      await repository.deleteHorairesByEtablissement(etablissementId);
      horaires.clear();
      hasHoraires.value = false;
      horaires.refresh();
      return true;
    } catch (e) {
      _logError('suppression des horaires', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Obtenir l'horaire d'un jour donné
  Horaire? getHoraireForDay(JourSemaine jour) {
    try {
      return horaires.firstWhere((horaire) => horaire.jour == jour);
    } catch (_) {
      return null;
    }
  }

  // Vérifier si l'établissement est ouvert un jour donné
  bool isOpenOnDay(JourSemaine jour) {
    final horaire = getHoraireForDay(jour);
    return horaire != null && horaire.isValid;
  }

  // Nombre total de jours ouverts
  int get nombreJoursOuverts =>
      horaires.where((horaire) => horaire.isValid).length;

  // Vérifier si l'établissement est ouvert maintenant
  bool get isOpenNow {
    if (!hasHoraires.value || horaires.isEmpty) return false;

    final now = DateTime.now();
    final today = _getJourSemaineFromDateTime(now);
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final horaireAujourdhui = getHoraireForDay(today);
    if (horaireAujourdhui == null || !horaireAujourdhui.isValid) return false;

    return _isTimeBetween(currentTime, horaireAujourdhui.ouverture!,
        horaireAujourdhui.fermeture!);
  }

  // Obtenir les horaires d'aujourd'hui
  Horaire? get horaireAujourdhui {
    final today = _getJourSemaineFromDateTime(DateTime.now());
    return getHoraireForDay(today);
  }

  // Statut d'ouverture en texte
  String get openStatus {
    if (!hasHoraires.value) return "Horaires non définis";
    return isOpenNow ? "Ouvert" : "Fermé";
  }

  // Obtenir un résumé textuel des horaires
  String get resumeHoraires {
    if (!hasHoraires.value) return "Aucun horaire défini";

    final joursOuverts = horaires.where((h) => h.isValid).toList();
    if (joursOuverts.isEmpty) return "Établissement fermé";

    return "${joursOuverts.length} jour(s) ouvert(s) par semaine";
  }

  // Fonctions utilitaires privées
  JourSemaine _getJourSemaineFromDateTime(DateTime date) {
    switch (date.weekday) {
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

  bool _isTimeBetween(String currentTime, String startTime, String endTime) {
    try {
      final current = _timeToMinutes(currentTime);
      final start = _timeToMinutes(startTime);
      final end = _timeToMinutes(endTime);
      return current >= start && current <= end;
    } catch (e) {
      return false;
    }
  }

  int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  void _logError(String action, Object error) {
    print('Erreur lors de la $action: $error');
  }
}
