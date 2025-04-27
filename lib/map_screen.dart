import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  late BitmapDescriptor _truckIcon;
  late BitmapDescriptor _warehouseIcon;
  late BitmapDescriptor _materialIcon;
  double _currentZoomLevel = 14.0;
  bool _isDarkMode = false; // <--- Dark mode toggle

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _loadCustomIcons(initialSize: 60);
    _loadInitialMarkers();
  }

  Future<BitmapDescriptor> _resizeImage(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    ByteData? bytes = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    final resizedBytes = bytes!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<void> _loadCustomIcons({required int initialSize}) async {
    _truckIcon = await _resizeImage('assets/icon/truck_icon.png', initialSize);
    _warehouseIcon = await _resizeImage('assets/icon/warehouse_icon.png', initialSize - 10);
    _materialIcon = await _resizeImage('assets/icon/material_icon.png', initialSize - 10);
    setState(() {});
  }

  void _loadInitialMarkers() {
    Set<Marker> loadedMarkers = {};

    loadedMarkers.add(
      Marker(
        markerId: MarkerId('truck_1'),
        position: LatLng(12.9716, 77.5946),
        infoWindow: InfoWindow(title: 'Truck 1'),
        icon: _truckIcon,
      ),
    );

    loadedMarkers.add(
      Marker(
        markerId: MarkerId('warehouse_1'),
        position: LatLng(12.9760, 77.5900),
        infoWindow: InfoWindow(title: 'Warehouse'),
        icon: _warehouseIcon,
      ),
    );

    loadedMarkers.add(
      Marker(
        markerId: MarkerId('material_1'),
        position: LatLng(12.9680, 77.6000),
        infoWindow: InfoWindow(title: 'Material Location'),
        icon: _materialIcon,
      ),
    );

    setState(() {
      _markers = loadedMarkers;
    });
  }

  void _startSimulatedMovement() {
    Timer.periodic(Duration(seconds: 4), (timer) {
      setState(() {
        _markers = _markers.map((marker) {
          if (marker.markerId.value.startsWith('truck')) {
            LatLng newPosition = LatLng(
              marker.position.latitude + 0.0002,
              marker.position.longitude + 0.0002,
            );
            _animateMarker(marker, newPosition);
          }
          return marker;
        }).toSet();
      });
    });
  }

  void _animateMarker(Marker marker, LatLng toLocation) {
    final fromLocation = marker.position;
    final totalDuration = Duration(milliseconds: 2000);

    double latDiff = toLocation.latitude - fromLocation.latitude;
    double lngDiff = toLocation.longitude - fromLocation.longitude;

    int frameCount = 30;
    Duration frameDuration = totalDuration ~/ frameCount;

    for (int i = 0; i <= frameCount; i++) {
      Future.delayed(frameDuration * i, () {
        double lat = fromLocation.latitude + (latDiff * i / frameCount);
        double lng = fromLocation.longitude + (lngDiff * i / frameCount);

        LatLng interpolatedPosition = LatLng(lat, lng);

        setState(() {
          _markers = _markers.map((m) {
            if (m.markerId == marker.markerId) {
              return m.copyWith(positionParam: interpolatedPosition);
            }
            return m;
          }).toSet();
        });
      });
    }
  }

  void _adjustMarkerIcons() async {
    int iconSize;

    if (_currentZoomLevel >= 16) {
      iconSize = 80;
    } else if (_currentZoomLevel >= 14) {
      iconSize = 60;
    } else if (_currentZoomLevel >= 12) {
      iconSize = 40;
    } else {
      iconSize = 30;
    }

    _truckIcon = await _resizeImage('assets/icon/truck_icon.png', iconSize);
    _warehouseIcon = await _resizeImage('assets/icon/warehouse_icon.png', iconSize - 10);
    _materialIcon = await _resizeImage('assets/icon/material_icon.png', iconSize - 10);

    Set<Marker> updatedMarkers = _markers.map((marker) {
      BitmapDescriptor updatedIcon;
      if (marker.markerId.value.startsWith('truck')) {
        updatedIcon = _truckIcon;
      } else if (marker.markerId.value.startsWith('warehouse')) {
        updatedIcon = _warehouseIcon;
      } else {
        updatedIcon = _materialIcon;
      }
      return marker.copyWith(iconParam: updatedIcon);
    }).toSet();

    setState(() {
      _markers = updatedMarkers;
    });
  }

  void _setMapStyle() async {
    if (_isDarkMode) {
      String darkStyle = await rootBundle.loadString('assets/map_style_dark.json');
      _mapController.setMapStyle(darkStyle);
    } else {
      _mapController.setMapStyle(null); // Reset to default
    }
  }

  void _toggleMapStyle() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _setMapStyle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(12.9716, 77.5946),
              zoom: _currentZoomLevel,
              tilt: 45,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              _setMapStyle();
              _startSimulatedMovement();
            },
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            buildingsEnabled: true,
            indoorViewEnabled: true,
            onCameraMove: (position) {
              if ((position.zoom - _currentZoomLevel).abs() > 0.2) {
                _currentZoomLevel = position.zoom;
                _adjustMarkerIcons();
              }
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.black87,
              child: Icon(
                _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                color: Colors.white,
              ),
              onPressed: _toggleMapStyle,
            ),
          ),
        ],
      ),
    );
  }
}
