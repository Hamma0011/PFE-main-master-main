import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/shop/models/horaire_model.dart';
import '../../../features/shop/models/jour_semaine.dart';

class HoraireRepository {
  final supabase = Supabase.instance.client;

  // Créer les 7 horaires pour un nouvel établissement
  Future<void> createHorairesForEtablissement(
      String etablissementId, List<Horaire> horaires) async {
    try {
      // Créer TOUJOURS les 7 jours, même si fermés
      final horairesData = JourSemaine.values.map((jour) {
        // Trouver l'horaire correspondant ou utiliser des valeurs par défaut
        final horaireExist = horaires.firstWhere(
          (h) => h.jour == jour,
          orElse: () => Horaire(
            etablissementId: etablissementId,
            jour: jour,
            estOuvert: false,
            ouverture: null, // null quand fermé
            fermeture: null, // null quand fermé
          ),
        );

        return {
          'etablissement_id': etablissementId,
          'jour': jour.valeur,
          'ouverture': horaireExist.ouverture,
          'fermeture': horaireExist.fermeture,
          'est_ouvert': horaireExist.estOuvert,
        };
      }).toList();

      await supabase.from('horaires').insert(horairesData);

    } catch (e) {
      throw Exception('Erreur lors de la création des horaires: $e');
    }
  }

  // Récupérer les horaires d'un établissement - CORRIGÉE
  Future<List<Horaire>> getHorairesByEtablissement(
      String etablissementId) async {
    try {
      final response = await supabase
          .from('horaires')
          .select()
          .eq('etablissement_id', etablissementId)
          .order('jour');

      // Si aucun horaire n'existe, créer les 7 jours par défaut
      if (response.isEmpty) {
        await _createHorairesParDefaut(etablissementId);

        // Relire après création
        final newResponse = await supabase
            .from('horaires')
            .select()
            .eq('etablissement_id', etablissementId)
            .order('jour');

        final horairesCrees = (newResponse as List)
            .map((json) => Horaire.fromJson(json))
            .toList();
        return horairesCrees;
      }

      final horaires =
          (response as List).map((json) => Horaire.fromJson(json)).toList();

      // Vérifier qu'on a bien les 7 jours
      if (horaires.length != 7) {
        await _completerHorairesManquants(etablissementId, horaires);

        // Relire après complétion
        final newResponse = await supabase
            .from('horaires')
            .select()
            .eq('etablissement_id', etablissementId)
            .order('jour');

        return (newResponse as List)
            .map((json) => Horaire.fromJson(json))
            .toList();
      }

      return horaires;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des horaires: $e');
    }
  }

  // Méthode privée pour créer les 7 jours par défaut
  Future<void> _createHorairesParDefaut(String etablissementId) async {
    try {
      final horairesData = JourSemaine.values
          .map((jour) => {
                'etablissement_id': etablissementId,
                'jour': jour.valeur,
                'ouverture': null, // null par défaut (fermé)
                'fermeture': null, // null par défaut (fermé)
                'est_ouvert': false, // fermé par défaut
              })
          .toList();

      await supabase.from('horaires').insert(horairesData);

    } catch (e) {
      throw Exception('Erreur lors de la création des horaires par défaut: $e');
    }
  }

  // Méthode privée pour compléter les jours manquants
  Future<void> _completerHorairesManquants(
      String etablissementId, List<Horaire> horairesExistants) async {
    try {
      final joursExistants = horairesExistants.map((h) => h.jour).toSet();
      final joursManquants = JourSemaine.values
          .where((jour) => !joursExistants.contains(jour))
          .toList();

      if (joursManquants.isNotEmpty) {
        final horairesManquantsData = joursManquants
            .map((jour) => {
                  'etablissement_id': etablissementId,
                  'jour': jour.valeur,
                  'ouverture': null,
                  'fermeture': null,
                  'est_ouvert': false,
                })
            .toList();

        await supabase.from('horaires').insert(horairesManquantsData);
      }
    } catch (e) {
      print('Erreur complétion horaires: $e');
    }
  }

  // Mettre à jour un horaire spécifique
  Future<bool> updateHoraire(Horaire horaire) async {
    try {
      if (horaire.id == null) {
        throw Exception('Impossible de mettre à jour un horaire sans ID');
      }

      // Utiliser une approche différente pour éviter les problèmes de typage
      Map<String, dynamic> updateData;

      if (!horaire.estOuvert) {
        // Si fermé, structure avec valeurs null
        updateData = {
          'est_ouvert': false,
          'ouverture': null,
          'fermeture': null,
          'updated_at': DateTime.now().toIso8601String(),
        };
      } else {
        // Si ouvert, structure avec les heures
        updateData = {
          'est_ouvert': true,
          'ouverture': horaire.ouverture,
          'fermeture': horaire.fermeture,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }

      await supabase
          .from('horaires')
          .update(updateData)
          .eq('id', horaire.id!)
          .eq('etablissement_id', horaire.etablissementId);
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'horaire: $e');
    }
  }

  // Mettre à jour tous les horaires d'un établissement
  Future<bool> updateAllHoraires(
      String etablissementId, List<Horaire> newHoraires) async {
    try {
      for (final horaire in newHoraires) {

        if (horaire.id == null) {

          // Map avec typage explicite
          final insertData = <String, dynamic>{
            'etablissement_id': etablissementId,
            'jour': horaire.jour.valeur,
            'est_ouvert': horaire.estOuvert,
          };

          // Gestion sécurisée des valeurs null
          if (horaire.ouverture != null) {
            insertData['ouverture'] = horaire.ouverture!;
          } else {
            insertData['ouverture'] = null;
          }

          if (horaire.fermeture != null) {
            insertData['fermeture'] = horaire.fermeture!;
          } else {
            insertData['fermeture'] = null;
          }

          await supabase.from('horaires').insert(insertData);

        } else {

          // Map avec typage explicite et gestion séparée des cas
          Map<String, dynamic> updateData;

          if (!horaire.estOuvert) {
            // CAS FERMÉ: mettre explicitement les heures à null
            updateData = <String, dynamic>{
              'est_ouvert': false,
              'ouverture': null,
              'fermeture': null,
              'updated_at': DateTime.now().toIso8601String(),
            };
          } else {
            // CAS OUVERT: gérer les heures (peuvent être null temporairement)
            updateData = <String, dynamic>{
              'est_ouvert': true,
              'updated_at': DateTime.now().toIso8601String(),
            };

            // Gestion sécurisée des heures
            if (horaire.ouverture != null) {
              updateData['ouverture'] = horaire.ouverture!;
            } else {
              updateData['ouverture'] = null;
            }

            if (horaire.fermeture != null) {
              updateData['fermeture'] = horaire.fermeture!;
            } else {
              updateData['fermeture'] = null;
            }
          }

          await supabase
              .from('horaires')
              .update(updateData)
              .eq('id', horaire.id!)
              .eq('etablissement_id', etablissementId);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Supprimer un horaire spécifique
  Future<bool> deleteHoraire(String horaireId) async {
    try {
      await supabase.from('horaires').delete().eq('id', horaireId);

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'horaire: $e');
    }
  }

  // Supprimer tous les horaires d'un établissement
  Future<bool> deleteHorairesByEtablissement(String etablissementId) async {
    try {
      await supabase
          .from('horaires')
          .delete()
          .eq('etablissement_id', etablissementId);

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression des horaires: $e');
    }
  }

  // Vérifier si un établissement a des horaires définis
  Future<bool> hasHoraires(String etablissementId) async {
    try {
      final response = await supabase
          .from('horaires')
          .select('id')
          .eq('etablissement_id', etablissementId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification des horaires: $e');
    }
  }

  // Méthode utilitaire pour créer les 7 jours si ils n'existent pas
  Future<void> ensureHorairesExist(String etablissementId) async {
    try {
      final existingHoraires =
          await getHorairesByEtablissement(etablissementId);

      if (existingHoraires.length < 7) {

        // Créer les horaires manquants
        final horairesManquants = JourSemaine.values
            .where((jour) {
              return !existingHoraires.any((h) => h.jour == jour);
            })
            .map((jour) => Horaire(
                  etablissementId: etablissementId,
                  jour: jour,
                  estOuvert: false,
                  ouverture: null,
                  fermeture: null,
                ))
            .toList();

        if (horairesManquants.isNotEmpty) {
          await createHorairesForEtablissement(
              etablissementId, horairesManquants);
        }
      }
    } catch (e) {
      print('Erreur vérification horaires: $e');
    }
  }
}
