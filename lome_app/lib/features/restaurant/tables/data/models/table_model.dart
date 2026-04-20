import '../../domain/entities/table_entity.dart';

/// Modelo de datos para mesa, serializable con Supabase.
class TableModel {
  final String id;
  final String tenantId;
  final int number;
  final String? name;
  final int capacity;
  final String? zone;
  final String status;
  final String shape;
  final double? positionX;
  final double? positionY;
  final double width;
  final double height;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Datos de session activa (join)
  final String? activeSessionId;
  final int? guestsCount;
  final String? waiterName;

  const TableModel({
    required this.id,
    required this.tenantId,
    required this.number,
    this.name,
    required this.capacity,
    this.zone,
    required this.status,
    this.shape = 'square',
    this.positionX,
    this.positionY,
    this.width = 1.0,
    this.height = 1.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.activeSessionId,
    this.guestsCount,
    this.waiterName,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    // Extraer datos de session si existen (via join)
    final sessions = json['table_sessions'] as List<dynamic>?;
    final activeSession = sessions?.isNotEmpty == true ? sessions!.first : null;

    return TableModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      number: json['number'] as int,
      name: json['label'] as String?,
      capacity: json['capacity'] as int? ?? 4,
      zone: json['zone'] as String?,
      status: json['status'] as String? ?? 'available',
      shape: json['shape'] as String? ?? 'square',
      positionX: (json['position_x'] as num?)?.toDouble(),
      positionY: (json['position_y'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 1.0,
      height: (json['height'] as num?)?.toDouble() ?? 1.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      activeSessionId: activeSession?['id'] as String?,
      guestsCount: activeSession?['guests_count'] as int?,
      waiterName:
          (activeSession?['profiles'] as Map<String, dynamic>?)?['full_name']
              as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'number': number,
      'label': name,
      'capacity': capacity,
      'zone': zone,
      'status': status,
      'shape': shape,
      'position_x': positionX,
      'position_y': positionY,
      'width': width,
      'height': height,
      'is_active': isActive,
    };
  }

  TableEntity toEntity() {
    return TableEntity(
      id: id,
      tenantId: tenantId,
      number: number,
      name: name,
      capacity: capacity,
      zone: zone,
      status: TableStatus.fromString(status),
      shape: TableShape.fromString(shape),
      positionX: positionX,
      positionY: positionY,
      width: width,
      height: height,
      isActive: isActive,
      activeSessionId: activeSessionId,
      guestsCount: guestsCount,
      waiterName: waiterName,
    );
  }
}
