import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../services/location_service.dart';

enum LocationSelectionSource {
  search,
  map,
  currentLocation,
}

class LocationPickerResult {
  final String address;
  final double latitude;
  final double longitude;
  final String placeId;

  const LocationPickerResult({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.placeId,
  });
}

class MapLocationPickerArgs {
  final bool isPickup;
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  const MapLocationPickerArgs({
    required this.isPickup,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
  });
}

class MapLocationPickerPage extends StatefulWidget {
  final bool isPickup;
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  const MapLocationPickerPage({
    super.key,
    required this.isPickup,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapLocationPickerPage> createState() => _MapLocationPickerPageState();
}

class _MapLocationPickerPageState extends State<MapLocationPickerPage> {
  // Default fallback center: Nadiad, Gujarat, India
  static const LatLng _defaultLocation = LatLng(22.6916, 72.8634);

  GoogleMapController? _mapController;
  late LatLng _currentCenter;
  String _selectedAddress = '';
  String _selectedPlaceId = '';
  double? _selectedLat;
  double? _selectedLng;

  LocationSelectionSource _selectionSource = LocationSelectionSource.map;
  bool _isProgrammaticCameraMove = false;
  bool _hasUserGesture = false;
  int _selectionRequestId = 0;

  bool _isCameraMoving = false;
  bool _isGeocoding = false;
  bool _isFetchingGPS = false;

  Timer? _geocodeDebounce;
  Timer? _searchDebounce;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<PlacePrediction> _suggestions = [];
  bool _isSearching = false;

  static const Color _primaryGreen = Color(0xFF0C5935);
  static const Color _primaryYellow = Color(0xFFF6C000);
  static const Color _dangerRed = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null && !widget.isPickup) {
      _currentCenter = LatLng(widget.initialLat!, widget.initialLng!);
      _selectedLat = widget.initialLat;
      _selectedLng = widget.initialLng;
      _selectionSource = LocationSelectionSource.map;
    } else {
      _currentCenter = _defaultLocation;
      _selectedLat = _defaultLocation.latitude;
      _selectedLng = _defaultLocation.longitude;
      _selectionSource = LocationSelectionSource.map;
    }

    if (widget.initialAddress != null && widget.initialAddress!.trim().isNotEmpty && !widget.isPickup) {
      _selectedAddress = widget.initialAddress!;
    } else {
      _selectedAddress = 'Pinpointing location...';
      if (widget.initialLat != null && widget.initialLng != null && !widget.isPickup) {
        _reverseGeocodeCenter();
      }
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _hasUserGesture = true;
    _isProgrammaticCameraMove = false;
  }

  void _onPointerUp(PointerUpEvent event) {
    _hasUserGesture = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _hasUserGesture = false;
  }

  void _onCameraMoveStarted() {
    setState(() {
      _isCameraMoving = true;
    });

    if (!_isProgrammaticCameraMove) {
      _geocodeDebounce?.cancel();
      if (_selectionSource != LocationSelectionSource.map) {
        setState(() {
          _selectionSource = LocationSelectionSource.map;
        });
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentCenter = position.target;
    if (_selectionSource == LocationSelectionSource.map) {
      _selectedLat = position.target.latitude;
      _selectedLng = position.target.longitude;
    }
  }

  void _onCameraIdle() {
    setState(() {
      _isCameraMoving = false;
    });

    if (_isProgrammaticCameraMove) {
      _isProgrammaticCameraMove = false;
      return;
    }

    if (_selectionSource == LocationSelectionSource.map) {
      _geocodeDebounce?.cancel();
      _geocodeDebounce = Timer(const Duration(milliseconds: 400), () {
        _reverseGeocodeCenter();
      });
    }
  }

  Future<void> _reverseGeocodeCenter() async {
    if (!mounted) return;
    if (_selectionSource != LocationSelectionSource.map) return;
    final requestId = ++_selectionRequestId;

    setState(() {
      _isGeocoding = true;
    });

    try {
      final prediction = await LocationService.reverseGeocode(
        _currentCenter.latitude,
        _currentCenter.longitude,
      );

      if (mounted &&
          _selectionSource == LocationSelectionSource.map &&
          requestId == _selectionRequestId) {
        setState(() {
          _selectedAddress = prediction.description.isNotEmpty
              ? prediction.description
              : '${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}';
          _selectedLat = _currentCenter.latitude;
          _selectedLng = _currentCenter.longitude;
          _selectedPlaceId = prediction.placeId;
          _isGeocoding = false;
        });
      }
    } catch (_) {
      if (mounted &&
          _selectionSource == LocationSelectionSource.map &&
          requestId == _selectionRequestId) {
        setState(() {
          if (_selectedAddress.isEmpty ||
              _selectedAddress == 'Pinpointing location...') {
            _selectedAddress =
                'Location (${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)})';
          }
          _selectedLat = _currentCenter.latitude;
          _selectedLng = _currentCenter.longitude;
          _isGeocoding = false;
        });
      }
    }
  }

  Future<void> _onSearchChanged(String query) async {
    _searchDebounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);

      try {
        final results = await LocationService.fetchPredictions(trimmed);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  Future<void> _selectSuggestion(PlacePrediction prediction) async {
    final requestId = ++_selectionRequestId;
    _geocodeDebounce?.cancel();
    _searchFocusNode.unfocus();

    final chosenAddress = prediction.description.isNotEmpty
        ? prediction.description
        : prediction.primaryText;

    setState(() {
      _selectionSource = LocationSelectionSource.search;
      _suggestions = [];
      _searchController.text = prediction.primaryText;
      _selectedAddress = chosenAddress;
      _selectedPlaceId = prediction.placeId;
      if (prediction.latitude != null && prediction.longitude != null) {
        _selectedLat = prediction.latitude;
        _selectedLng = prediction.longitude;
      }
    });

    double? lat = prediction.latitude;
    double? lng = prediction.longitude;

    if (lat == null || lng == null) {
      setState(() => _isGeocoding = true);
      try {
        final details = await LocationService.fetchPlaceDetails(prediction.placeId);
        if (details.latitude != null && details.longitude != null) {
          lat = details.latitude;
          lng = details.longitude;
        }
        if (details.description.isNotEmpty && _selectedAddress.isEmpty) {
          _selectedAddress = details.description;
        }
        if (details.placeId.isNotEmpty) {
          _selectedPlaceId = details.placeId;
        }
      } catch (_) {}
    }

    if (!mounted || requestId != _selectionRequestId) return;

    if (lat != null && lng != null) {
      setState(() {
        _selectedLat = lat;
        _selectedLng = lng;
        _currentCenter = LatLng(lat!, lng!);
        _isGeocoding = false;
      });

      _isProgrammaticCameraMove = true;
      try {
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentCenter, 16.5),
        );
      } catch (_) {
      } finally {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_hasUserGesture) {
            _isProgrammaticCameraMove = false;
          }
        });
      }
    } else {
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  Future<void> _handleCurrentLocation({bool showErrors = true, bool isInitial = false}) async {
    final requestId = ++_selectionRequestId;
    _geocodeDebounce?.cancel();
    setState(() => _isFetchingGPS = true);

    try {
      final loc = await LocationService.getCurrentLocation();
      if (loc.latitude != null &&
          loc.longitude != null &&
          mounted &&
          (isInitial || requestId == _selectionRequestId)) {
          
        if (isInitial) {
          _selectionRequestId = requestId;
        }

        final latLng = LatLng(loc.latitude!, loc.longitude!);
        setState(() {
          _selectionSource = LocationSelectionSource.currentLocation;
          _currentCenter = latLng;
          _selectedLat = loc.latitude!;
          _selectedLng = loc.longitude!;
          _selectedAddress = loc.description.isNotEmpty
              ? loc.description
              : '${loc.latitude!.toStringAsFixed(4)}, ${loc.longitude!.toStringAsFixed(4)}';
          _selectedPlaceId = loc.placeId;
        });

        _isProgrammaticCameraMove = true;
        try {
          await _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(latLng, 16.5),
          );
        } catch (_) {
        } finally {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted && !_hasUserGesture) {
              _isProgrammaticCameraMove = false;
            }
          });
        }
      }
    } catch (e) {
      if (mounted && showErrors) {
        final message =
            e is PermissionException ? e.message : 'Could not obtain current location.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: _dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted && requestId == _selectionRequestId) {
        setState(() => _isFetchingGPS = false);
      }
    }
  }

  void _confirmLocation() {
    final lat = _selectedLat ?? _currentCenter.latitude;
    final lng = _selectedLng ?? _currentCenter.longitude;
    final address = _selectedAddress.trim().isNotEmpty
        ? _selectedAddress.trim()
        : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

    Navigator.of(context).pop(
      LocationPickerResult(
        address: address,
        latitude: lat,
        longitude: lng,
        placeId: _selectedPlaceId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D2818);
    final textSecondary = isDark ? const Color(0xFFA1A1A1) : const Color(0xFF5B7063);
    final borderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E8E2);

    final pinColor = widget.isPickup ? _primaryYellow : _dangerRed;
    final confirmLabel = widget.isPickup ? 'Confirm pickup' : 'Confirm destination';
    final sectionLabel = widget.isPickup ? 'Pickup location' : 'Destination';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F8F5),
      body: Stack(
        children: [
          // Full-screen Google Map
          Positioned.fill(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentCenter,
                  zoom: 16.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (widget.initialLat == null || widget.isPickup) {
                    _handleCurrentLocation(showErrors: false, isInitial: true);
                  }
                },
                onCameraMoveStarted: _onCameraMoveStarted,
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                onTap: (_) {
                  _searchFocusNode.unfocus();
                  if (_suggestions.isNotEmpty) {
                    setState(() => _suggestions = []);
                  }
                },
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),

          // Center Pin (Stationary Marker under which map moves)
          Center(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 38), // Center tip of pin
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Pin Jump on Drag
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      transform: Matrix4.translationValues(0, _isCameraMoving ? -10 : 0, 0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: pinColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: pinColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Icon(
                          widget.isPickup
                              ? Icons.radio_button_checked_rounded
                              : Icons.location_on_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Subtle shadow circle below pin
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _isCameraMoving ? 8 : 12,
                      height: _isCameraMoving ? 3 : 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: _isCameraMoving ? 0.2 : 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Floating Search Bar Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Floating Search Bar Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: textSecondary.withValues(alpha: 0.8),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: _primaryGreen,
                          size: 22,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                color: textSecondary,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _suggestions = []);
                                },
                              )
                            : (_isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _primaryGreen,
                                      ),
                                    ),
                                  )
                                : null),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  // Search Suggestions Overlay
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _suggestions.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: _primaryGreen,
                              size: 20,
                            ),
                            title: Text(
                              item.primaryText.isNotEmpty ? item.primaryText : item.description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: item.secondaryText.isNotEmpty
                                ? Text(
                                    item.secondaryText,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => _selectSuggestion(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Floating Current Location GPS Button
          Positioned(
            right: 16,
            bottom: 184, // Sits comfortably above bottom confirmation panel
            child: InkWell(
              onTap: _isFetchingGPS ? null : _handleCurrentLocation,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isFetchingGPS
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _primaryGreen,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: _primaryGreen,
                          size: 24,
                        ),
                ),
              ),
            ),
          ),

          // Bottom Confirmation Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: borderColor, width: 1.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtle top drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Section Label
                  Text(
                    sectionLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Address Display
                  Row(
                    children: [
                      Icon(
                        widget.isPickup ? Icons.radio_button_checked : Icons.location_on,
                        color: pinColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isGeocoding
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pinpointing address...',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _selectedAddress,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Full-width Confirmation Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isGeocoding ? null : _confirmLocation,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
