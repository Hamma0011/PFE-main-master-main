import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/device/device_utility.dart';
import '../../models/order_model.dart';
import 'dart:async';

import 'package:async/async.dart'; // Add this import

class DeliveryMapView extends StatefulWidget {
  final OrderModel order;
  const DeliveryMapView({super.key, required this.order});

  @override
  State<DeliveryMapView> createState() => _DeliveryMapViewState();
}

class _DeliveryMapViewState extends State<DeliveryMapView> {
  final MapController _mapController = MapController();
  List<LatLng> routePoints = [];
  String travelTime = "";
  String distanceText = "";
  bool _isDisposed = false;
  LatLngBounds? _routeBounds;
  bool _isMapReady = false;
  CancelableOperation? _currentRequestOperation;
  http.Client? _currentHttpClient;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRoute());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _currentRequestOperation?.cancel();
    _currentHttpClient?.close();
    super.dispose();
  }

  Future<void> _showSnack(String title, String msg) async {
    if (_isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        Get.snackbar(title, msg, snackPosition: SnackPosition.TOP);
      }
    });
  }

  String _formatTravelTime(double milliseconds) {
    final totalMinutes = (milliseconds / 60000).round();
    if (totalMinutes < 60) {
      return '${totalMinutes} min';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  void _fitMapToBounds() {
    if (_routeBounds != null && _isMapReady) {
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: _routeBounds!,
            padding: EdgeInsets.all(_getPaddingForDevice(context)),
          ),
        );
      } catch (e) {
        debugPrint('Error fitting bounds: $e');
        _fitBoundsManually();
      }
    } else {
      _fitToStartEndPoints();
    }
  }

  double _getPaddingForDevice(BuildContext context) {
    final deviceType = TDeviceUtils.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 80.0;
      case DeviceType.tablet:
        return 120.0;
      case DeviceType.desktop:
        return 160.0;
    }
  }

  void _fitBoundsManually() {
    if (_routeBounds == null) return;

    final center = _routeBounds!.center;
    final distance = Distance();
    final diagonalDistance = distance(
      _routeBounds!.southWest,
      _routeBounds!.northEast,
    );

    final zoom = _calculateOptimalZoom(diagonalDistance);
    _mapController.move(center, zoom);
  }

  void _fitToStartEndPoints() {
    final clientLat = widget.order.address?.latitude ?? 0.0;
    final clientLng = widget.order.address?.longitude ?? 0.0;
    final restoLat = widget.order.etablissement?.latitude ?? 0.0;
    final restoLng = widget.order.etablissement?.longitude ?? 0.0;

    if (clientLat != 0.0 &&
        clientLng != 0.0 &&
        restoLat != 0.0 &&
        restoLng != 0.0) {
      final points = [
        LatLng(clientLat, clientLng),
        LatLng(restoLat, restoLng),
      ];
      final bounds = LatLngBounds.fromPoints(points);
      final center = bounds.center;
      final distance = Distance();
      final diagonalDistance = distance(bounds.southWest, bounds.northEast);
      final zoom = _calculateOptimalZoom(diagonalDistance);

      _mapController.move(center, zoom);
    }
  }

  double _calculateOptimalZoom(double meters) {
    final km = meters / 1000.0;
    if (km < 0.1) return 16.0;
    if (km < 0.5) return 15.0;
    if (km < 1.0) return 14.0;
    if (km < 2.0) return 13.0;
    if (km < 5.0) return 12.0;
    if (km < 10.0) return 11.0;
    if (km < 20.0) return 10.0;
    if (km < 50.0) return 9.0;
    if (km < 100.0) return 8.0;
    return 7.0;
  }

  LatLng _calculateCenter() {
    final clientLat = widget.order.address?.latitude ?? 0.0;
    final clientLng = widget.order.address?.longitude ?? 0.0;
    final restoLat = widget.order.etablissement?.latitude ?? 0.0;
    final restoLng = widget.order.etablissement?.longitude ?? 0.0;

    if (clientLat != 0.0 &&
        clientLng != 0.0 &&
        restoLat != 0.0 &&
        restoLng != 0.0) {
      return LatLng(
        (clientLat + restoLat) / 2,
        (clientLng + restoLng) / 2,
      );
    } else if (clientLat != 0.0 && clientLng != 0.0) {
      return LatLng(clientLat, clientLng);
    } else if (restoLat != 0.0 && restoLng != 0.0) {
      return LatLng(restoLat, restoLng);
    }

    return const LatLng(0, 0);
  }

  Future<void> _fetchRoute() async {
    // Cancel any ongoing request
    await _currentRequestOperation?.cancel();
    _currentHttpClient?.close();

    // Use debouncing to prevent rapid successive calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performRouteFetch();
    });
  }

  Future<void> _performRouteFetch() async {
    final operation = CancelableOperation.fromFuture(
      _executeRouteRequest(),
      onCancel: () {
        _currentHttpClient?.close();
        debugPrint('Route request cancelled');
      },
    );

    _currentRequestOperation = operation;
    try {
      await operation.value;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('Request was cancelled normally');
        return;
      }
      if (!_isDisposed) {
        await _showSnack("Erreur", "Impossible de récupérer l'itinéraire: $e");
        debugPrint("Route fetch error: $e");
      }
    }
  }

  Future<void> _executeRouteRequest() async {
    if (_isDisposed) return;

    final client = http.Client();
    _currentHttpClient = client;

    try {
      final clientLat = widget.order.address?.latitude ?? 0.0;
      final clientLng = widget.order.address?.longitude ?? 0.0;
      final restoLat = widget.order.etablissement?.latitude ?? 0.0;
      final restoLng = widget.order.etablissement?.longitude ?? 0.0;

      if (clientLat == 0.0 ||
          clientLng == 0.0 ||
          restoLat == 0.0 ||
          restoLng == 0.0) {
        await _showSnack("Erreur", "Coordonnées invalides pour la commande.");
        return;
      }

      final apiKey = dotenv.env['GRAPHHOPPER_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        await _showSnack("Erreur", "Clé API GraphHopper non configurée.");
        return;
      }

      final url = Uri.parse(
        'https://graphhopper.com/api/1/route?point=$restoLat,$restoLng&point=$clientLat,$clientLng&vehicle=car&points_encoded=false&key=$apiKey',
      );

      final response = await client.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          client.close();
          throw TimeoutException('Request timeout');
        },
      );

      if (_isDisposed) return;

      if (response.statusCode != 200) {
        throw Exception('Erreur API: ${response.statusCode} ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['paths'] == null || (data['paths'] as List).isEmpty) {
        throw Exception('Aucun chemin retourné par l\'API');
      }

      final path = (data['paths'] as List).first as Map<String, dynamic>;

      final distance = (path['distance'] as num?)?.toDouble() ?? 0.0;
      final time = (path['time'] as num?)?.toDouble() ?? 0.0;

      final pointsObj = path['points'] as Map<String, dynamic>?;
      final coords = pointsObj != null
          ? (pointsObj['coordinates'] as List<dynamic>?) ?? []
          : [];

      if (coords.isEmpty) {
        await _showSnack("Erreur", "Itinéraire introuvable (aucun point).");
        return;
      }

      final points = <LatLng>[];
      for (final coord in coords) {
        if (coord is List && coord.length >= 2) {
          final lon = double.tryParse(coord[0].toString()) ?? 0.0;
          final lat = double.tryParse(coord[1].toString()) ?? 0.0;
          if (lat != 0.0 && lon != 0.0) {
            points.add(LatLng(lat, lon));
          }
        }
      }

      if (points.isEmpty) {
        await _showSnack(
            "Erreur", "Impossible de parser les coordonnées de l'itinéraire.");
        return;
      }

      if (_isDisposed) return;

      setState(() {
        distanceText = "${(distance / 1000).toStringAsFixed(1)} km";
        travelTime = _formatTravelTime(time);
        routePoints = points;
        _routeBounds = LatLngBounds.fromPoints(points);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        _fitMapToBounds();
      });
    } finally {
      client.close();
      if (_currentHttpClient == client) {
        _currentHttpClient = null;
      }
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 0.5);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 0.5);
  }

  void _resetZoom() {
    _fitMapToBounds();
  }

  // ... rest of your UI methods (_buildInfoCard, _buildZoomControls, etc.)
  // Keep all your existing UI methods exactly as they were

  Widget _buildInfoCard(BuildContext context) {
    final deviceType = TDeviceUtils.getDeviceType(context);
    final isMobile = deviceType == DeviceType.mobile;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoItem(
            context,
            Icons.access_time,
            travelTime.isNotEmpty ? travelTime : '-',
            Colors.blue,
          ),
          SizedBox(width: isMobile ? 16 : 24),
          Container(
            width: 1,
            height: isMobile ? 20 : 24,
            color: Colors.grey.shade300,
          ),
          SizedBox(width: isMobile ? 16 : 24),
          _buildInfoItem(
            context,
            Icons.place,
            distanceText.isNotEmpty ? distanceText : '-',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context, IconData icon, String text, Color color) {
    final deviceType = TDeviceUtils.getDeviceType(context);
    final isMobile = deviceType == DeviceType.mobile;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: isMobile ? 18 : 22,
        ),
        SizedBox(width: isMobile ? 6 : 8),
        Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildZoomControls(BuildContext context) {
    final deviceType = TDeviceUtils.getDeviceType(context);
    final isMobile = deviceType == DeviceType.mobile;
    final buttonSize = isMobile ? 44.0 : 52.0;
    final iconSize = isMobile ? 20.0 : 24.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildZoomButton(
            context,
            Icons.add,
            _zoomIn,
            buttonSize,
            iconSize,
          ),
          Container(
            width: buttonSize * 0.6,
            height: 1,
            color: Colors.grey.shade300,
          ),
          _buildZoomButton(
            context,
            Icons.remove,
            _zoomOut,
            buttonSize,
            iconSize,
          ),
          Container(
            width: buttonSize * 0.6,
            height: 1,
            color: Colors.grey.shade300,
          ),
          _buildZoomButton(
            context,
            Icons.fit_screen,
            _resetZoom,
            buttonSize,
            iconSize,
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(BuildContext context, IconData icon,
      VoidCallback onPressed, double size, double iconSize) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = TDeviceUtils.getDeviceType(context);
    final isMobile = deviceType == DeviceType.mobile;
    final initialCenter = _calculateCenter();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 10.0,
              keepAlive: true,
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
                if (_routeBounds != null) {
                  _fitMapToBounds();
                } else {
                  _fitToStartEndPoints();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.app',
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: isMobile ? 4 : 5,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (widget.order.etablissement?.latitude != 0.0 &&
                      widget.order.etablissement?.longitude != 0.0)
                    Marker(
                      point: LatLng(
                        widget.order.etablissement!.latitude!,
                        widget.order.etablissement!.longitude!,
                      ),
                      width: isMobile ? 50 : 60,
                      height: isMobile ? 50 : 60,
                      child: Icon(Icons.restaurant,
                          color: Colors.red, size: isMobile ? 30 : 36),
                    ),
                  if (widget.order.address?.latitude != 0.0 &&
                      widget.order.address?.longitude != 0.0)
                    Marker(
                      point: LatLng(
                        widget.order.address!.latitude!,
                        widget.order.address!.longitude!,
                      ),
                      width: isMobile ? 50 : 60,
                      height: isMobile ? 50 : 60,
                      child: Icon(Icons.home,
                          color: Colors.blue, size: isMobile ? 30 : 36),
                    ),
                ],
              ),
            ],
          ),

          // Info Card
          if (travelTime.isNotEmpty || distanceText.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + (isMobile ? 16 : 24),
              left: isMobile ? 16 : 24,
              right: isMobile ? 16 : 24,
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildInfoCard(context),
              ),
            ),

          // Zoom Controls
          Positioned(
            bottom:
                MediaQuery.of(context).padding.bottom + (isMobile ? 100 : 120),
            right: isMobile ? 16 : 24,
            child: _buildZoomControls(context),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + (isMobile ? 16 : 24),
            left: isMobile ? 16 : 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: isMobile ? 20 : 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Loading indicator
          if (!_isMapReady || (routePoints.isEmpty && travelTime.isEmpty))
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chargement de l\'itinéraire...',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
