import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/location_service.dart' show LocationService, PlacePrediction, HttpException;

export '../../services/location_service.dart' show PlacePrediction;

enum LocationErrorType { none, network, empty, quota }

class LocationDetails {
  final String address;
  final double? latitude;
  final double? longitude;
  final String placeId;

  const LocationDetails({
    required this.address,
    this.latitude,
    this.longitude,
    required this.placeId,
  });
}

class LocationAutocompleteField extends StatefulWidget {
  final String fieldKey;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final Future<void> Function(PlacePrediction prediction, LocationDetails details) onPlaceSelected;

  const LocationAutocompleteField({
    super.key,
    required this.fieldKey,
    required this.hint,
    required this.icon,
    required this.iconColor,
    this.initialValue,
    this.onChanged,
    required this.onPlaceSelected,
  });

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  Timer? _debounce;
  bool _isLoading = false;
  List<PlacePrediction> _predictions = [];
  LocationErrorType _errorType = LocationErrorType.none;
  String _activeQuery = '';

  // Guard: set to true while processing a selection to block new searches.
  bool _isSelecting = false;
  // Track what we last sent to the provider to prevent duplicates.
  String _lastSentQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
      _lastSentQuery = widget.initialValue!;
    }
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(LocationAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != null &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue!;
      _lastSentQuery = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fadeController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    widget.onChanged?.call(query);
    if (_isSelecting) return;

    final trimmed = query.trim();

    // Skip if exactly the same as what we already sent.
    if (trimmed == _lastSentQuery && !_isLoading) return;
    _lastSentQuery = trimmed;

    _debounce?.cancel();

    if (trimmed.isEmpty) {
      setState(() {
        _predictions = [];
        _errorType = LocationErrorType.none;
        _isLoading = false;
        _activeQuery = '';
      });
      _fadeController.reverse();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (_isSelecting) return;
      
      setState(() {
        _activeQuery = trimmed;
        _isLoading = true;
        _errorType = LocationErrorType.none;
      });

      _fadeController.forward();

      try {
        final results = await LocationService.fetchPredictions(_activeQuery);

        if (!mounted || _activeQuery != trimmed) return;

        setState(() {
          _isLoading = false;
          if (results.isEmpty) {
            _predictions = [];
            _errorType = LocationErrorType.empty;
          } else {
            _predictions = results.take(5).toList();
            _errorType = LocationErrorType.none;
          }
        });
      } on HttpException catch (e) {
        if (!mounted || _activeQuery != trimmed) return;
        final isQuota = e.message.contains('OVER_QUERY_LIMIT') ||
            e.message.contains('REQUEST_DENIED');
        setState(() {
          _predictions = [];
          _isLoading = false;
          _errorType = isQuota ? LocationErrorType.quota : LocationErrorType.network;
        });
      } catch (_) {
        if (!mounted || _activeQuery != trimmed) return;
        setState(() {
          _predictions = [];
          _isLoading = false;
          _errorType = LocationErrorType.network;
        });
      }
    });
  }

  Future<void> _onSelect(PlacePrediction prediction) async {
    _isSelecting = true;
    _lastSentQuery = prediction.description;
    _debounce?.cancel();

    setState(() {
      _predictions = [];
      _isLoading = false;
      _errorType = LocationErrorType.none;
    });

    _focusNode.unfocus();
    _fadeController.reverse();

    // Fill the text field instantly.
    _controller.text = prediction.description;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: prediction.description.length),
    );

    // Fetch coordinates in background; show text immediately.
    try {
      final details = await LocationService.fetchPlaceDetails(prediction.placeId);
      if (!mounted) return;

      await widget.onPlaceSelected(
        prediction,
        LocationDetails(
          address: prediction.description,
          latitude: details.latitude,
          longitude: details.longitude,
          placeId: prediction.placeId,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      // Fallback: save without coordinates.
      await widget.onPlaceSelected(
        prediction,
        LocationDetails(
          address: prediction.description,
          latitude: null,
          longitude: null,
          placeId: prediction.placeId,
        ),
      );
    } finally {
      if (mounted) {
        _isSelecting = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Animate suggestion list in/out.
    final hasSuggestions = _predictions.isNotEmpty;
    final hasError = _errorType != LocationErrorType.none && !_isLoading;
    final showOverlay = (hasSuggestions || hasError) && !_isSelecting;

    if (showOverlay) {
      _fadeController.forward();
    } else if (!_isLoading) {
      _fadeController.reverse();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(),
        const SizedBox(height: 4),
        if (showOverlay)
          FadeTransition(
            opacity: _fadeAnimation,
            child: hasSuggestions
                ? _SuggestionList(
                    predictions: _predictions,
                    onSelect: _onSelect,
                  )
                : _ErrorTile(errorType: _errorType),
          ),
      ],
    );
  }

  Widget _buildTextField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF28282A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFEAE5DD);
    final textColor = theme.colorScheme.onSurface;

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onChanged,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.grey[400],
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(widget.icon, color: widget.iconColor, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIcon: _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.iconColor,
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: cardBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF6C000), width: 2),
          ),
        ),
      );
  }
}

class _SuggestionList extends StatelessWidget {
  final List<PlacePrediction> predictions;
  final Future<void> Function(PlacePrediction) onSelect;

  const _SuggestionList({
    required this.predictions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final dividerColor = isDark ? const Color(0xFF333333) : const Color(0xFFF0EDE8);

    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33000000) : const Color(0x1A000000),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: predictions.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
            indent: 52,
          ),
          itemBuilder: (context, index) {
            final pred = predictions[index];
            return _SuggestionTile(
              prediction: pred,
              onTap: () => onSelect(pred),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final PlacePrediction prediction;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.prediction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final iconBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF6F5F3);
    final textColor = theme.colorScheme.onSurface;

    return Material(
      color: cardBg,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFFF6C000).withAlpha(30),
        highlightColor: const Color(0xFFF6C000).withAlpha(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: isDark ? Colors.white60 : const Color(0xFF6F6F72),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prediction.primaryText.isNotEmpty
                          ? prediction.primaryText
                          : prediction.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (prediction.secondaryText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        prediction.secondaryText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E9E9E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final LocationErrorType errorType;

  const _ErrorTile({required this.errorType});

  @override
  Widget build(BuildContext context) {
    final (icon, message) = switch (errorType) {
      LocationErrorType.empty => (Icons.search_off_rounded, 'No locations found'),
      LocationErrorType.quota => (
          Icons.cloud_off_rounded,
          'Location service temporarily unavailable'
        ),
      LocationErrorType.network => (
          Icons.wifi_off_rounded,
          'Unable to fetch locations'
        ),
      LocationErrorType.none => (Icons.search_off_rounded, ''),
    };

    if (errorType == LocationErrorType.none) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE5DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6F6F72),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
