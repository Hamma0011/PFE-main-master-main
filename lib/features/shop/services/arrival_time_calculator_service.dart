import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Types de véhicules supportés par GraphHopper
enum GraphHopperVehicle {
  car('car', 'Voiture'),
  foot('foot', 'À pied'),
  bike('bike', 'Vélo'),

  scooter('scooter', 'Scooter');

  final String value;
  final String label;

  const GraphHopperVehicle(this.value, this.label);
}

/// Service pour calculer l'heure d'arrivée réelle du client
class ArrivalTimeCalculatorService {
  final _db = Supabase.instance.client;

  /// Calcule l'heure d'arrivée réelle du client en utilisant GraphHopper API
  /// Retourne l'heure au format HH:mm:ss (type TIME) ou null si le calcul échoue
  ///
  /// [vehicle] : Type de véhicule pour le calcul du trajet (par défaut: car)
  /// Utilise la localisation GPS actuelle du client au lieu de l'adresse sauvegardée
  Future<String?> calculerHeureArriveeReelle({
    required String etablissementId,
    GraphHopperVehicle vehicle = GraphHopperVehicle.car,
  }) async {
    try {
      debugPrint('🚀 [DEBUG] Début du calcul de l\'heure d\'arrivée réelle');
      debugPrint('   - Établissement ID: $etablissementId');
      debugPrint('   - Utilisation de la localisation GPS actuelle');

      // Obtenir la position GPS actuelle du client
      debugPrint('   - Récupération de la position GPS actuelle...');
      final clientPosition = await _obtenirPositionGPSActuelle();
      if (clientPosition == null) {
        debugPrint('❌ [DEBUG] Impossible d\'obtenir la position GPS actuelle');
        return null;
      }
      final clientLat = clientPosition.latitude;
      final clientLng = clientPosition.longitude;
      debugPrint('   ✅ Position GPS actuelle obtenue: $clientLat, $clientLng');

      // Récupérer les coordonnées de l'établissement
      debugPrint('   - Récupération des coordonnées de l\'établissement...');
      final etablissementCoords =
          await obtenirCoordonneesEtablissement(etablissementId);
      if (etablissementCoords == null) {
        debugPrint(
            '❌ [DEBUG] Impossible de récupérer les coordonnées de l\'établissement');
        return null;
      }
      debugPrint(
          '   ✅ Coordonnées établissement récupérées: ${etablissementCoords['latitude']}, ${etablissementCoords['longitude']}');

      final restoLat = etablissementCoords['latitude']!;
      final restoLng = etablissementCoords['longitude']!;

      debugPrint(
          '   - Coordonnées client (GPS actuel): $clientLat, $clientLng');
      debugPrint('   - Coordonnées établissement: $restoLat, $restoLng');

      if (clientLat == 0.0 ||
          clientLng == 0.0 ||
          restoLat == 0.0 ||
          restoLng == 0.0) {
        debugPrint(
            '❌ [DEBUG] Coordonnées invalides pour le calcul de l\'itinéraire');
        debugPrint(
            '   - clientLat: $clientLat (${clientLat == 0.0 ? "INVALIDE" : "OK"})');
        debugPrint(
            '   - clientLng: $clientLng (${clientLng == 0.0 ? "INVALIDE" : "OK"})');
        debugPrint(
            '   - restoLat: $restoLat (${restoLat == 0.0 ? "INVALIDE" : "OK"})');
        debugPrint(
            '   - restoLng: $restoLng (${restoLng == 0.0 ? "INVALIDE" : "OK"})');
        return null;
      }

      // Récupérer la clé API GraphHopper
      debugPrint('   - Récupération de la clé API GraphHopper...');
      String apiKey = '';
      try {
        apiKey = dotenv.env['GRAPHHOPPER_API_KEY'] ?? '';
        debugPrint(
            '   - Clé API récupérée depuis dotenv: ${apiKey.isNotEmpty ? "OK (${apiKey.substring(0, 5)}...)" : "VIDE"}');
      } catch (e) {
        debugPrint('   ⚠️ Erreur lors de la récupération de la clé API: $e');
        try {
          await dotenv.load();
          apiKey = dotenv.env['GRAPHHOPPER_API_KEY'] ?? '';
          debugPrint(
              '   - Clé API chargée après dotenv.load(): ${apiKey.isNotEmpty ? "OK" : "VIDE"}');
        } catch (loadError) {
          debugPrint('   ❌ Erreur lors du chargement de dotenv: $loadError');
        }
      }

      if (apiKey.isEmpty) {
        debugPrint('❌ [DEBUG] Clé API GraphHopper non configurée ou vide');
        return null;
      }
      debugPrint('   ✅ Clé API GraphHopper disponible');

      // Appeler l'API GraphHopper pour calculer le temps de trajet
      debugPrint('   - Appel de l\'API GraphHopper...');
      debugPrint('   - Type de véhicule: ${vehicle.label} (${vehicle.value})');
      final url = Uri.parse(
        'https://graphhopper.com/api/1/route?point=$restoLat,$restoLng&point=$clientLat,$clientLng&vehicle=${vehicle.value}&points_encoded=false&key=$apiKey',
      );
      debugPrint(
          '   - URL GraphHopper: ${url.toString().replaceAll(apiKey, '***')}');

      final response = await http.get(url).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('❌ [DEBUG] Timeout lors de l\'appel à GraphHopper');
          throw TimeoutException('Request timeout');
        },
      );

      debugPrint('   - Réponse GraphHopper: Status ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('❌ [DEBUG] Erreur API GraphHopper: ${response.statusCode}');
        debugPrint('   - Body: ${response.body}');
        return null;
      }

      // Parser la réponse
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('❌ Erreur lors du parsing JSON: $e');
        return null;
      }

      if (data['paths'] == null || (data['paths'] as List).isEmpty) {
        debugPrint('⚠️ Aucun chemin retourné par l\'API GraphHopper');
        return null;
      }

      final path = (data['paths'] as List).first as Map<String, dynamic>;
      final time =
          (path['time'] as num?)?.toDouble() ?? 0.0; // Temps en millisecondes

      if (time <= 0) {
        debugPrint('⚠️ Temps de trajet invalide: $time');
        return null;
      }

      // Calculer l'heure d'arrivée (heure actuelle + temps de trajet)
      final tempsTrajetMinutes =
          (time / 60000).round(); // Convertir millisecondes en minutes
      final heureActuelle = DateTime.now();
      final heureArriveeSansDecalage =
          heureActuelle.add(Duration(minutes: tempsTrajetMinutes));

      // Ajouter +1 heure pour s'adapter à l'heure locale de Tunis (UTC+1)
      final heureArrivee =
          heureArriveeSansDecalage.add(const Duration(hours: 1));

      // Formater l'heure au format HH:mm:ss (type TIME)
      final formattedTime =
          '${heureArrivee.hour.toString().padLeft(2, '0')}:${heureArrivee.minute.toString().padLeft(2, '0')}:${heureArrivee.second.toString().padLeft(2, '0')}';
      final formattedTimeSansDecalage =
          '${heureArriveeSansDecalage.hour.toString().padLeft(2, '0')}:${heureArriveeSansDecalage.minute.toString().padLeft(2, '0')}:${heureArriveeSansDecalage.second.toString().padLeft(2, '0')}';

      // Logs de débogage détaillés
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🕐 CALCUL HEURE D\'ARRIVÉE RÉELLE (GraphHopper)');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🚗 Type de véhicule: ${vehicle.label} (${vehicle.value})');
      debugPrint('📍 Coordonnées client (GPS actuel): $clientLat, $clientLng');
      debugPrint('📍 Coordonnées établissement: $restoLat, $restoLng');
      debugPrint(
          '⏱️  Temps de trajet: $tempsTrajetMinutes minutes (${(time / 1000).toStringAsFixed(0)} secondes)');
      debugPrint(
          '🕐 Heure actuelle: ${heureActuelle.hour.toString().padLeft(2, '0')}:${heureActuelle.minute.toString().padLeft(2, '0')}:${heureActuelle.second.toString().padLeft(2, '0')}');
      debugPrint(
          '🕐 Heure d\'arrivée (sans décalage): $formattedTimeSansDecalage');
      debugPrint('🕐 Heure d\'arrivée (+1h Tunis): $formattedTime');
      debugPrint('📝 Format TIME pour DB: $formattedTime');
      debugPrint('═══════════════════════════════════════════════════════════');

      return formattedTime;
    } catch (e) {
      debugPrint('❌ Erreur lors du calcul de l\'heure d\'arrivée réelle: $e');
      return null;
    }
  }

  /// Récupère les coordonnées GPS de l'établissement
  /// Retourne un Map avec 'latitude' et 'longitude' si disponible, null sinon
  Future<Map<String, double>?> obtenirCoordonneesEtablissement(
      String etablissementId) async {
    try {
      final response = await _db
          .from('etablissements')
          .select('latitude, longitude')
          .eq('id', etablissementId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ Établissement non trouvé: $etablissementId');
        return null;
      }

      final latitude = (response['latitude'] as num?)?.toDouble();
      final longitude = (response['longitude'] as num?)?.toDouble();

      if (latitude == null ||
          longitude == null ||
          latitude == 0.0 ||
          longitude == 0.0) {
        debugPrint('⚠️ Coordonnées GPS de l\'établissement non disponibles');
        return null;
      }

      debugPrint('📍 Coordonnées établissement : $latitude, $longitude');
      return {
        'latitude': latitude,
        'longitude': longitude,
      };
    } catch (e) {
      debugPrint(
          '❌ Erreur lors de la récupération des coordonnées de l\'établissement: $e');
      return null;
    }
  }

  /// Obtient la position GPS actuelle du client
  /// Retourne la Position ou null si impossible d'obtenir
  Future<Position?> _obtenirPositionGPSActuelle() async {
    try {
      // Vérifier les permissions de localisation
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Les services de localisation sont désactivés');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Les permissions de localisation sont refusées');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            '❌ Les permissions de localisation sont définitivement refusées');
        return null;
      }

      // Obtenir la position actuelle
      debugPrint('   - Demande de la position GPS actuelle...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint(
          '   ✅ Position GPS obtenue: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'obtention de la position GPS: $e');
      return null;
    }
  }
}
