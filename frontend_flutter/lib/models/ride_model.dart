class RideModel {
  final String id;
  final String username;
  final String cycleId;
  final String cycleNumber;
  final String? startStationId;
  final String? startStationName;
  final String? endStationId;
  final String? endStationName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final double totalFare;
  final String status;
  final int? liveDurationMinutes;
  final double? liveProjectedFare;

  RideModel({
    required this.id,
    required this.username,
    required this.cycleId,
    required this.cycleNumber,
    this.startStationId,
    this.startStationName,
    this.endStationId,
    this.endStationName,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.totalFare,
    required this.status,
    this.liveDurationMinutes,
    this.liveProjectedFare,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      cycleId: json['cycle']?.toString() ?? '',
      cycleNumber: json['cycle_number'] ?? '',
      startStationId: json['start_station']?.toString(),
      startStationName: json['start_station_name'],
      endStationId: json['end_station']?.toString(),
      endStationName: json['end_station_name'],
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      durationMinutes: json['duration_minutes'] ?? 0,
      totalFare: double.tryParse(json['total_fare']?.toString() ?? '0.0') ?? 0.0,
      status: json['status'] ?? 'ACTIVE',
      liveDurationMinutes: json['live_duration_minutes'],
      liveProjectedFare: json['live_projected_fare'] != null
          ? double.tryParse(json['live_projected_fare'].toString())
          : null,
    );
  }
}
