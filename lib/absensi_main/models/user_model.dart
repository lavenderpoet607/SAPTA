class UserModel {
  final int id;
  final String name;
  final String email;
  final String batch;
  final int trainingId;
  final String trainingName;
  final String role;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.batch = 'Batch 1',
    this.trainingId = 1,
    this.trainingName = 'Mobile Flutter Programming',
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map = json;
    if (map['user'] is Map) {
      map = Map<String, dynamic>.from(map['user']);
    } else if (map['data'] is Map) {
      final d = Map<String, dynamic>.from(map['data']);
      if (d['user'] is Map) {
        map = Map<String, dynamic>.from(d['user']);
      } else if (d.containsKey('name') || d.containsKey('email')) {
        map = d;
      }
    }

    final rawEmail = _toText(map['email'], '-');
    final emailPrefix = rawEmail != '-' && rawEmail.contains('@')
        ? rawEmail.split('@').first
        : 'Peserta PPKD';

    final rawName = _optionalText(map['name']);
    final resolvedName =
        (rawName != null &&
            rawName.isNotEmpty &&
            rawName.toLowerCase() != 'peserta ppkd')
        ? rawName
        : (emailPrefix.isNotEmpty ? emailPrefix : 'Peserta PPKD');

    return UserModel(
      id: _toInt(map['id']),
      name: resolvedName,
      email: rawEmail,
      batch: _toText(map['batch'] ?? map['angkatan'], 'Batch 1'),
      trainingId: _toInt(map['training_id'] ?? map['trainingId'], 1),
      trainingName: _toText(
        map['training_name'] ?? map['trainingName'],
        'Mobile Flutter Programming',
      ),
      role: _toText(map['role'], 'peserta'),
      createdAt: _toText(map['created_at'] ?? map['createdAt'], '-'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'batch': batch,
      'training_id': trainingId,
      'training_name': trainingName,
      'role': role,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? batch,
    int? trainingId,
    String? trainingName,
    String? role,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      batch: batch ?? this.batch,
      trainingId: trainingId ?? this.trainingId,
      trainingName: trainingName ?? this.trainingName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get inisial {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'P';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final firstChar = parts.first.isNotEmpty ? parts.first[0] : '';
    final lastChar = parts.last.isNotEmpty ? parts.last[0] : '';
    final code = '$firstChar$lastChar'.toUpperCase();
    return code.isEmpty ? 'P' : code;
  }

  static int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _toText(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _optionalText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
