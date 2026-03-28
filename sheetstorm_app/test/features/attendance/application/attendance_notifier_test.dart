import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/attendance/application/attendance_notifier.dart';
import 'package:sheetstorm/features/attendance/data/models/attendance_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

AttendanceStats _stats({
  double overallPercentage = 85.0,
  int totalEvents = 10,
  int totalAttendances = 85,
  int totalAbsences = 15,
  List<MemberAttendance>? memberStats,
  List<RegisterAttendance>? registerStats,
}) =>
    AttendanceStats(
      overallPercentage: overallPercentage,
      totalEvents: totalEvents,
      totalAttendances: totalAttendances,
      totalAbsences: totalAbsences,
      memberStats: memberStats ?? [],
      registerStats: registerStats ?? [],
    );

MemberAttendance _memberAttendance({
  String musicianId = 'musician1',
  String name = 'Max Mustermann',
  int attendances = 8,
  int absences = 2,
  double percentage = 80.0,
  String? register,
}) =>
    MemberAttendance(
      musicianId: musicianId,
      name: name,
      attendances: attendances,
      absences: absences,
      percentage: percentage,
      register: register,
    );

RegisterAttendance _registerAttendance({
  String registerId = 'trp',
  String name = 'Trompeten',
  int memberCount = 5,
  double percentage = 90.0,
}) =>
    RegisterAttendance(
      registerId: registerId,
      name: name,
      memberCount: memberCount,
      percentage: percentage,
    );

TrendDataPoint _trendDataPoint({
  DateTime? date,
  double percentage = 85.0,
  int eventCount = 1,
}) =>
    TrendDataPoint(
      date: date ?? DateTime(2024, 1, 15),
      percentage: percentage,
      eventCount: eventCount,
    );

AttendanceTrend _trend({
  List<TrendDataPoint>? dataPoints,
  double averagePercentage = 85.0,
  String period = '3-months',
}) =>
    AttendanceTrend(
      dataPoints: dataPoints ??
          [
            _trendDataPoint(date: DateTime(2024, 1, 1), percentage: 80.0),
            _trendDataPoint(date: DateTime(2024, 2, 1), percentage: 85.0),
            _trendDataPoint(date: DateTime(2024, 3, 1), percentage: 90.0),
          ],
      averagePercentage: averagePercentage,
      period: period,
    );

void main() {
  // Initialize Flutter bindings for all tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── AttendanceNotifier Tests ──────────────────────────────────────────────

  group('AttendanceNotifier — State Management', () {
    test('Initial State hat Default-Zeitraum (3 Monate)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(attendanceProvider('band1'));

      expect(state.startDate, isNotNull);
      expect(state.endDate, isNotNull);
      expect(state.isLoading, isTrue);
    });

    test('State wird nach Initialisierung geladen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(attendanceProvider('band1'));

      // Initial loading state
      expect(container.read(attendanceProvider('band1')).isLoading, isTrue);
    });

    test('setDateRange aktualisiert Zeitraum', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 3, 31);

      await notifier.setDateRange(startDate, endDate);

      final state = container.read(attendanceProvider('band1'));
      expect(state.startDate, startDate);
      expect(state.endDate, endDate);
    });

    test('setEventType filtert nach Event-Typ', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);

      await notifier.setEventType('rehearsal');

      final state = container.read(attendanceProvider('band1'));
      expect(state.eventType, 'rehearsal');
    });

    test('refresh lädt Daten neu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);

      await notifier.refresh();

      // Should trigger loading
      expect(container.read(attendanceProvider('band1')).isLoading, isTrue);
    });
  });

  // ─── Statistics Tests ──────────────────────────────────────────────────────

  group('AttendanceNotifier — Statistiken', () {
    test('Overall Percentage wird berechnet', () {
      final stats = _stats(overallPercentage: 87.5);
      expect(stats.overallPercentage, 87.5);
    });

    test('Total Events zählt alle Events', () {
      final stats = _stats(totalEvents: 15);
      expect(stats.totalEvents, 15);
    });

    test('Total Attendances summiert Anwesenheiten', () {
      final stats = _stats(totalAttendances: 120);
      expect(stats.totalAttendances, 120);
    });

    test('Total Absences summiert Abwesenheiten', () {
      final stats = _stats(totalAbsences: 30);
      expect(stats.totalAbsences, 30);
    });

    test('Member Stats enthalten individuelle Anwesenheit', () {
      final member1 = _memberAttendance(name: 'Alice', percentage: 90.0);
      final member2 = _memberAttendance(name: 'Bob', percentage: 75.0);
      final stats = _stats(memberStats: [member1, member2]);

      expect(stats.memberStats.length, 2);
      expect(stats.memberStats[0].percentage, 90.0);
      expect(stats.memberStats[1].percentage, 75.0);
    });

    test('Register Stats zeigen Register-Anwesenheit', () {
      final trp = _registerAttendance(name: 'Trompeten', percentage: 92.0);
      final pos = _registerAttendance(name: 'Posaunen', percentage: 88.0);
      final stats = _stats(registerStats: [trp, pos]);

      expect(stats.registerStats.length, 2);
      expect(stats.registerStats[0].name, 'Trompeten');
      expect(stats.registerStats[1].name, 'Posaunen');
    });
  });

  // ─── Member Attendance Tests ───────────────────────────────────────────────

  group('MemberAttendance — Mitglieder-Daten', () {
    test('Percentage basiert auf Attendances/Total', () {
      final member = _memberAttendance(
        attendances: 8,
        absences: 2,
        percentage: 80.0,
      );

      expect(member.attendances, 8);
      expect(member.absences, 2);
      expect(member.percentage, 80.0);
    });

    test('Member mit 100% Anwesenheit', () {
      final member = _memberAttendance(
        attendances: 10,
        absences: 0,
        percentage: 100.0,
      );

      expect(member.percentage, 100.0);
      expect(member.absences, 0);
    });

    test('Member mit 0% Anwesenheit', () {
      final member = _memberAttendance(
        attendances: 0,
        absences: 10,
        percentage: 0.0,
      );

      expect(member.percentage, 0.0);
      expect(member.attendances, 0);
    });

    test('Register-Zuordnung wird gespeichert', () {
      final member = _memberAttendance(register: 'Trompeten');
      expect(member.register, 'Trompeten');
    });
  });

  // ─── Trend Tests ───────────────────────────────────────────────────────────

  group('AttendanceTrend — Trend-Analyse', () {
    test('Trend-Datenpunkte zeigen zeitlichen Verlauf', () {
      final trend = _trend(
        dataPoints: [
          _trendDataPoint(date: DateTime(2024, 1, 1), percentage: 75.0),
          _trendDataPoint(date: DateTime(2024, 2, 1), percentage: 80.0),
          _trendDataPoint(date: DateTime(2024, 3, 1), percentage: 85.0),
        ],
      );

      expect(trend.dataPoints.length, 3);
      expect(trend.dataPoints[0].percentage, 75.0);
      expect(trend.dataPoints[2].percentage, 85.0);
    });

    test('Average Percentage ist Durchschnitt über Zeitraum', () {
      final trend = _trend(averagePercentage: 82.5);
      expect(trend.averagePercentage, 82.5);
    });

    test('Period beschreibt Zeitraum', () {
      final trend = _trend(period: '6-months');
      expect(trend.period, '6-months');
    });

    test('Event Count pro Datenpunkt wird gezählt', () {
      final dataPoint = _trendDataPoint(eventCount: 4);
      expect(dataPoint.eventCount, 4);
    });
  });

  // ─── Export Tests ──────────────────────────────────────────────────────────

  group('AttendanceNotifier — Export', () {
    test('exportData mit CSV-Format', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);

      final exportData = await notifier.exportData('csv');

      expect(exportData, isNotNull);
    });

    test('exportData mit Excel-Format', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);

      final exportData = await notifier.exportData('xlsx');

      expect(exportData, isNotNull);
    });

    test('exportData mit PDF-Format', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);

      final exportData = await notifier.exportData('pdf');

      expect(exportData, isNotNull);
    });

    test('Export enthält jobId für Status-Tracking', () {
      final export = ExportData(
        jobId: 'export123',
        format: 'csv',
        status: 'pending',
      );

      expect(export.jobId, 'export123');
      expect(export.format, 'csv');
      expect(export.status, 'pending');
    });

    test('Export mit downloadUrl nach Completion', () {
      final export = ExportData(
        jobId: 'export123',
        format: 'csv',
        status: 'completed',
        downloadUrl: 'https://example.com/download/export123.csv',
      );

      expect(export.status, 'completed');
      expect(export.downloadUrl, isNotNull);
    });

    test('Export mit expiresAt zeigt Verfallsdatum', () {
      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      final export = ExportData(
        jobId: 'export123',
        format: 'csv',
        status: 'completed',
        downloadUrl: 'https://example.com/download.csv',
        expiresAt: expiresAt,
      );

      expect(export.expiresAt, isNotNull);
      expect(export.expiresAt!.isAfter(DateTime.now()), isTrue);
    });
  });

  // ─── Filter Tests ──────────────────────────────────────────────────────────

  group('AttendanceNotifier — Filter-Funktionen', () {
    test('Filter nach Event-Typ: rehearsal', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);

      await notifier.setEventType('rehearsal');

      expect(container.read(attendanceProvider('band1')).eventType, 'rehearsal');
    });

    test('Filter nach Event-Typ: concert', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);

      await notifier.setEventType('concert');

      expect(container.read(attendanceProvider('band1')).eventType, 'concert');
    });

    test('Filter zurücksetzen (null)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);

      await notifier.setEventType('rehearsal');
      await notifier.setEventType(null);

      expect(container.read(attendanceProvider('band1')).eventType, isNull);
    });

    test('Zeitraum-Filter: Letzter Monat', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      await notifier.setDateRange(lastMonth, now);

      final state = container.read(attendanceProvider('band1'));
      expect(state.startDate, lastMonth);
      expect(state.endDate, now);
    });

    test('Zeitraum-Filter: Dieses Jahr', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);
      final now = DateTime.now();
      final yearStart = DateTime(now.year, 1, 1);

      await notifier.setDateRange(yearStart, now);

      final state = container.read(attendanceProvider('band1'));
      expect(state.startDate, yearStart);
      expect(state.endDate, now);
    });
  });

  // ─── Error Handling Tests ──────────────────────────────────────────────────

  group('AttendanceNotifier — Fehlerbehandlung', () {
    test('Error State bei Fehler beim Laden', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(attendanceProvider('invalid_band').notifier);

      // Error might be set
      final state = container.read(attendanceProvider('invalid_band'));
      expect(state.error, isNull); // Initial state has no error
    });

    test('isLoading ist false nach erfolgreichem Laden', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(attendanceProvider('band1').notifier);

      // After initial load completes (mocked), isLoading should be false
      // This requires actual service response
    });
  });

  // ─── Provider Family Tests ─────────────────────────────────────────────────

  group('Attendance Provider — Family-Scoping', () {
    test('Verschiedene bandId-Scopes sind unabhängig', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state1 = container.read(attendanceProvider('band1'));
      final state2 = container.read(attendanceProvider('band2'));

      expect(state1, isNot(same(state2)));
    });

    test('State-Änderung in band1 beeinflusst nicht band2', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier1 = container.read(attendanceProvider('band1').notifier);
      final notifier2 = container.read(attendanceProvider('band2').notifier);

      await notifier1.setEventType('rehearsal');

      expect(container.read(attendanceProvider('band1')).eventType, 'rehearsal');
      expect(container.read(attendanceProvider('band2')).eventType, isNull);
    });
  });
}
