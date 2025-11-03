import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;


class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerScreen({super.key, this.initialLatitude, this.initialLongitude});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isGettingAddress = false;
  bool _isLoading = true;

  static const LatLng _defaultPosition = LatLng(48.8566, 2.3522); // Paris

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      LatLng initialPos = widget.initialLatitude != null && widget.initialLongitude != null
          ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
          : await _getCurrentLocation();

      setState(() {
        _selectedLocation = initialPos;
        _isLoading = false;
      });

      await _getAddressFromLatLng(initialPos);
      _mapController.move(initialPos, 15);
    } catch (e) {
      print('Erreur initialisation localisation: $e');
      setState(() {
        _selectedLocation = _defaultPosition;
        _isLoading = false;
      });
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permission refusée';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Permission définitivement refusée';
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Erreur récupération localisation: $e');
      throw 'Impossible d\'obtenir la localisation';
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      setState(() => _isGettingAddress = true);

      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${latLng.latitude}&lon=${latLng.longitude}');
      final response = await http.get(url, headers: {
        'User-Agent': 'com.caferesto.app', // Required by Nominatim
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedAddress = data['display_name'] ?? 'Adresse non disponible';
        });
      } else {
        setState(() => _selectedAddress = 'Adresse non disponible');
      }
    } catch (e) {
      print('Erreur récupération adresse: $e');
      setState(() => _selectedAddress = 'Adresse non disponible');
    } finally {
      setState(() => _isGettingAddress = false);
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      TLoaders.infoSnackBar(message: 'Obtention de votre position...');
      LatLng currentPos = await _getCurrentLocation();

      setState(() => _selectedLocation = currentPos);
      _mapController.move(currentPos, 15);
      await _getAddressFromLatLng(currentPos);

      TLoaders.successSnackBar(message: 'Position actuelle récupérée');
    } catch (e) {
      print('Erreur localisation: $e');
      TLoaders.errorSnackBar(message: 'Impossible d\'obtenir la position');
    }
  }

  void _onMapTap(LatLng latLng) {
    setState(() => _selectedLocation = latLng);
    _getAddressFromLatLng(latLng);
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _selectedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner la localisation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
            tooltip: 'Ma position actuelle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? _defaultPosition,
                    initialZoom: 15,
                    onTap: (tapPos, point) => _onMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.caferesto.app',
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerLayer(
                      markers: [
                        if (_selectedLocation != null)
                          Marker(
                            point: _selectedLocation!,
                            child : const Icon(
                              Icons.location_pin,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_isGettingAddress)
                  const Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Recherche de l\'adresse...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!_isGettingAddress && _selectedAddress.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAddress,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _confirmSelection,
        child: const Icon(Icons.check),
      ),
    );
  }
}
