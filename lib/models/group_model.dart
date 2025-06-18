class GroupModel {
  final String id;
  final String name;
  final String adminId;
  final List<String> memberIds;
  final DateTime createdAt;
  final double initialAmount;
  final Map<String, double> memberBalances;

  GroupModel({
    required this.id,
    required this.name,
    required this.adminId,
    required this.memberIds,
    required this.createdAt,
    required this.initialAmount,
    required this.memberBalances,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'adminId': adminId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'initialAmount': initialAmount,
      'memberBalances': memberBalances,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      adminId: map['adminId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      initialAmount: (map['initialAmount'] ?? 0.0).toDouble(),
      memberBalances: Map<String, double>.from(map['memberBalances'] ?? {}),
    );
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? adminId,
    List<String>? memberIds,
    DateTime? createdAt,
    double? initialAmount,
    Map<String, double>? memberBalances,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      initialAmount: initialAmount ?? this.initialAmount,
      memberBalances: memberBalances ?? this.memberBalances,
    );
  }
} 