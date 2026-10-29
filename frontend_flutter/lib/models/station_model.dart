class CycleModel {
  final String id;
  final String cycleNumber;
  final String qrCode;
  final String status;
  final String lockStatus;
  final int batteryPercentage;
  final String? currentStationId;

  CycleModel({
    required this.id,
    required this.cycleNumber,
    required this.qrCode,
    required this.status,
    required this.lockStatus,
    required this.batteryPercentage,
    this.currentStationId,
  });

  factory CycleModel.fromJson(Map<String, dynamic> json) {
    return CycleModel(
      id: json['id'] ?? '',
      cycleNumber: json['cycle_number'] ?? '',
      qrCode: json['qr_code'] ?? '',
      status: json['status'] ?? 'AVAILABLE',
      lockStatus: json['lock_status'] ?? 'LOCKED',
      batteryPercentage: json['battery_percentage'] ?? 100,
      currentStationId: json['current_station']?.toString(),
    );
  }
}

class StationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final int capacity;
  final int availableCycles;
  final List<CycleModel> cycles;

  StationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.capacity,
    required this.availableCycles,
    required this.cycles,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    var rawCycles = json['cycles'] as List? ?? [];
    List<CycleModel> cycleList =
        rawCycles.map((c) => CycleModel.fromJson(c)).toList();

    return StationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      address: json['address'] ?? '',
      capacity: json['capacity'] ?? 10,
      availableCycles: json['available_cycles'] ?? 0,
      cycles: cycleList,
    );
  }
}
