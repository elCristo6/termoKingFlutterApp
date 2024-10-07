// lib/models/device_data.dart

class DeviceData {
  final int deviceID;
  final int runTime;
  final double temperature;
  final double setPoint;
  final GPSData gps;

  DeviceData({
    required this.deviceID,
    required this.runTime,
    required this.temperature,
    required this.setPoint,
    required this.gps,
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) {
    return DeviceData(
      deviceID: json['deviceID'],
      runTime: json['RunTime'],
      temperature: (json['Temperature'] as num).toDouble(),
      setPoint: (json['SetPoint'] as num).toDouble(),
      gps: GPSData.fromJson(json['GPS']),
    );
  }
}

class GPSData {
  final bool enabled;
  final double latitude;
  final double longitude;
  final double speed;
  final double altitude;
  final int satellitesVisible;
  final int satellitesUsed;
  final double accuracy;
  final String mapLink;

  GPSData({
    required this.enabled,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.altitude,
    required this.satellitesVisible,
    required this.satellitesUsed,
    required this.accuracy,
    required this.mapLink,
  });

  factory GPSData.fromJson(Map<String, dynamic> json) {
    return GPSData(
      enabled: json['Enabled'] == 1,
      latitude: (json['Latitude'] as num).toDouble(),
      longitude: (json['Longitude'] as num).toDouble(),
      speed: (json['Speed'] as num).toDouble(),
      altitude: (json['Altitude'] as num).toDouble(),
      satellitesVisible: json['SatellitesVisible'],
      satellitesUsed: json['SatellitesUsed'],
      accuracy: (json['Accuracy'] as num).toDouble(),
      mapLink: json['MapLink'],
    );
  }
}
