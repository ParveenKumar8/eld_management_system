import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_section_header.dart';
import 'package:eld_management_system/core/widgets/eld_status_badge.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Live Google Maps card tracking ELD GPS position.
class EldLiveMapCard extends StatefulWidget {
  const EldLiveMapCard({
    this.eldData,
    this.height,
    super.key,
  });

  final EldData? eldData;
  final double? height;

  @override
  State<EldLiveMapCard> createState() => _EldLiveMapCardState();
}

class _EldLiveMapCardState extends State<EldLiveMapCard> {
  GoogleMapController? _controller;
  static const _defaultPosition = LatLng(39.8283, -98.5795); // US center fallback

  LatLng get _position {
    final d = widget.eldData;
    if (d?.latitude != null && d?.longitude != null) {
      return LatLng(d!.latitude!, d.longitude!);
    }
    return _defaultPosition;
  }

  bool get _hasLiveGps =>
      widget.eldData?.latitude != null && widget.eldData?.longitude != null;

  @override
  void didUpdateWidget(EldLiveMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasLiveGps && _controller != null) {
      _animateTo(_position);
    }
  }

  Future<void> _animateTo(LatLng target) async {
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 14, tilt: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight = widget.height ?? Responsive.mapHeight(context);
    final hasKey = AppConstants.googleMapsApiKey.isNotEmpty;

    return EldFadeIn(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EldSectionHeader(
            title: 'Live Tracking',
            subtitle: _hasLiveGps ? 'ELD GPS feed active' : 'Waiting for ELD coordinates',
            action: EldStatusBadge(
              label: _hasLiveGps ? 'Live' : 'No GPS',
              tone: _hasLiveGps ? EldBadgeTone.success : EldBadgeTone.neutral,
              pulsing: _hasLiveGps && (widget.eldData?.isMoving ?? false),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: SizedBox(
              height: mapHeight,
              child: Stack(
                children: [
                  if (hasKey)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: _position, zoom: _hasLiveGps ? 14 : 4),
                      markers: _hasLiveGps
                          ? {
                              Marker(
                                markerId: const MarkerId('eld_vehicle'),
                                position: _position,
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueOrange,
                                ),
                                infoWindow: InfoWindow(
                                  title: 'Vehicle',
                                  snippet: widget.eldData!.isMoving
                                      ? '${widget.eldData!.speedMph.toStringAsFixed(0)} mph'
                                      : 'Stopped',
                                ),
                              ),
                            }
                          : {},
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (c) {
                        _controller = c;
                        if (_hasLiveGps) _animateTo(_position);
                      },
                    )
                  else
                    _MapPlaceholder(hasGps: _hasLiveGps, position: _position, eldData: widget.eldData),
                  if (_hasLiveGps)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      right: 12,
                      child: _TelemetryOverlay(data: widget.eldData!),
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

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.hasGps,
    required this.position,
    required this.eldData,
  });

  final bool hasGps;
  final LatLng position;
  final EldData? eldData;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy.withValues(alpha: 0.06),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_rounded, size: 48, color: AppColors.navy.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'Add GOOGLE_MAPS_API_KEY to enable map',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              if (hasGps && eldData != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryOverlay extends StatelessWidget {
  const _TelemetryOverlay({required this.data});
  final EldData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _Chip(Icons.speed_rounded, '${data.speedMph.toStringAsFixed(0)} mph'),
            const SizedBox(width: 12),
            _Chip(Icons.route_rounded, '${data.odometerMiles.toStringAsFixed(1)} mi'),
            const Spacer(),
            Icon(
              data.isMoving ? Icons.trending_up_rounded : Icons.pause_circle_outline_rounded,
              color: AppColors.amber,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.amber, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}