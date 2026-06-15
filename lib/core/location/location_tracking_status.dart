/// Runtime state of the device GPS tracking pipeline.
enum LocationTrackingStatus {
  idle,
  trackingForeground,
  trackingBackground,
  permissionDenied,
  serviceDisabled,
}