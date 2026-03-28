/// Domain models for Attendance Statistics — Issue TBD (MS2)

// ─── Attendance Stats ─────────────────────────────────────────────────────────

class AttendanceStats {
  final double overallPercentage;
  final int totalEvents;
  final int totalAttendances;
  final int totalAbsences;
  final List<MemberAttendance> memberStats;
  final List<RegisterAttendance> registerStats;

  const AttendanceStats({
    required this.overallPercentage,
    required this.totalEvents,
    required this.totalAttendances,
    required this.totalAbsences,
    required this.memberStats,
    required this.registerStats,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) => AttendanceStats(
        overallPercentage: (json['overall_percentage'] as num).toDouble(),
        totalEvents: json['total_events'] as int,
        totalAttendances: json['total_attendances'] as int,
        totalAbsences: json['total_absences'] as int,
        memberStats: (json['member_stats'] as List<dynamic>)
            .map((e) => MemberAttendance.fromJson(e as Map<String, dynamic>))
            .toList(),
        registerStats: (json['register_stats'] as List<dynamic>)
            .map((e) => RegisterAttendance.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'overall_percentage': overallPercentage,
        'total_events': totalEvents,
        'total_attendances': totalAttendances,
        'total_absences': totalAbsences,
        'member_stats': memberStats.map((e) => e.toJson()).toList(),
        'register_stats': registerStats.map((e) => e.toJson()).toList(),
      };
}

// ─── Member Attendance ────────────────────────────────────────────────────────

class MemberAttendance {
  final String musicianId;
  final String name;
  final String? avatarUrl;
  final int attendances;
  final int absences;
  final double percentage;
  final String? register;

  const MemberAttendance({
    required this.musicianId,
    required this.name,
    this.avatarUrl,
    required this.attendances,
    required this.absences,
    required this.percentage,
    this.register,
  });

  factory MemberAttendance.fromJson(Map<String, dynamic> json) => MemberAttendance(
        musicianId: json['musician_id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        attendances: json['attendances'] as int,
        absences: json['absences'] as int,
        percentage: (json['percentage'] as num).toDouble(),
        register: json['register'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'musician_id': musicianId,
        'name': name,
        'avatar_url': avatarUrl,
        'attendances': attendances,
        'absences': absences,
        'percentage': percentage,
        'register': register,
      };

  MemberAttendance copyWith({
    String? musicianId,
    String? name,
    String? avatarUrl,
    int? attendances,
    int? absences,
    double? percentage,
    String? register,
  }) =>
      MemberAttendance(
        musicianId: musicianId ?? this.musicianId,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        attendances: attendances ?? this.attendances,
        absences: absences ?? this.absences,
        percentage: percentage ?? this.percentage,
        register: register ?? this.register,
      );
}

// ─── Register Attendance ──────────────────────────────────────────────────────

class RegisterAttendance {
  final String registerId;
  final String name;
  final int memberCount;
  final double percentage;
  final String? color;

  const RegisterAttendance({
    required this.registerId,
    required this.name,
    required this.memberCount,
    required this.percentage,
    this.color,
  });

  factory RegisterAttendance.fromJson(Map<String, dynamic> json) => RegisterAttendance(
        registerId: json['register_id'] as String,
        name: json['name'] as String,
        memberCount: json['member_count'] as int,
        percentage: (json['percentage'] as num).toDouble(),
        color: json['color'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'register_id': registerId,
        'name': name,
        'member_count': memberCount,
        'percentage': percentage,
        'color': color,
      };

  RegisterAttendance copyWith({
    String? registerId,
    String? name,
    int? memberCount,
    double? percentage,
    String? color,
  }) =>
      RegisterAttendance(
        registerId: registerId ?? this.registerId,
        name: name ?? this.name,
        memberCount: memberCount ?? this.memberCount,
        percentage: percentage ?? this.percentage,
        color: color ?? this.color,
      );
}

// ─── Attendance Trend ─────────────────────────────────────────────────────────

class AttendanceTrend {
  final List<TrendDataPoint> dataPoints;
  final double averagePercentage;
  final String period;

  const AttendanceTrend({
    required this.dataPoints,
    required this.averagePercentage,
    required this.period,
  });

  factory AttendanceTrend.fromJson(Map<String, dynamic> json) => AttendanceTrend(
        dataPoints: (json['data_points'] as List<dynamic>)
            .map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        averagePercentage: (json['average_percentage'] as num).toDouble(),
        period: json['period'] as String,
      );

  Map<String, dynamic> toJson() => {
        'data_points': dataPoints.map((e) => e.toJson()).toList(),
        'average_percentage': averagePercentage,
        'period': period,
      };
}

class TrendDataPoint {
  final DateTime date;
  final double percentage;
  final int eventCount;

  const TrendDataPoint({
    required this.date,
    required this.percentage,
    required this.eventCount,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) => TrendDataPoint(
        date: DateTime.parse(json['date'] as String),
        percentage: (json['percentage'] as num).toDouble(),
        eventCount: json['event_count'] as int,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'percentage': percentage,
        'event_count': eventCount,
      };
}

// ─── Export Data ──────────────────────────────────────────────────────────────

class ExportData {
  final String jobId;
  final String format;
  final String status;
  final String? downloadUrl;
  final DateTime? expiresAt;

  const ExportData({
    required this.jobId,
    required this.format,
    required this.status,
    this.downloadUrl,
    this.expiresAt,
  });

  factory ExportData.fromJson(Map<String, dynamic> json) => ExportData(
        jobId: json['job_id'] as String,
        format: json['format'] as String,
        status: json['status'] as String,
        downloadUrl: json['download_url'] as String?,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'job_id': jobId,
        'format': format,
        'status': status,
        'download_url': downloadUrl,
        'expires_at': expiresAt?.toIso8601String(),
      };
}
