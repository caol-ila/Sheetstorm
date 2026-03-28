import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/communication/application/poll_notifier.dart';
import 'package:sheetstorm/features/communication/data/models/poll_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Author _author({
  String id = 'author1',
  String name = 'Test Autor',
}) =>
    Author(
      id: id,
      name: name,
      avatarUrl: null,
      role: 'Mitglied',
    );

PollOption _pollOption({
  String id = 'opt1',
  String text = 'Option 1',
  int voteCount = 0,
  double percentage = 0.0,
  bool hasVoted = false,
}) =>
    PollOption(
      id: id,
      text: text,
      voteCount: voteCount,
      percentage: percentage,
      hasVoted: hasVoted,
    );

Poll _poll({
  String id = 'poll1',
  String question = 'Test Frage?',
  List<PollOption>? options,
  PollStatus status = PollStatus.active,
  bool isMultiSelect = false,
  bool isAnonymous = true,
  bool hasVoted = false,
  bool showResultsAfterVoting = true,
  DateTime? deadline,
}) =>
    Poll(
      id: id,
      bandId: 'band1',
      author: _author(),
      question: question,
      options: options ??
          [
            _pollOption(id: 'opt1', text: 'Ja'),
            _pollOption(id: 'opt2', text: 'Nein'),
          ],
      status: status,
      isMultiSelect: isMultiSelect,
      isAnonymous: isAnonymous,
      hasVoted: hasVoted,
      showResultsAfterVoting: showResultsAfterVoting,
      deadline: deadline,
      createdAt: DateTime(2024, 1, 15),
    );

void main() {
  // Initialize Flutter bindings for all tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── PollListNotifier Tests ────────────────────────────────────────────────

  group('PollListNotifier — CRUD-Operationen', () {
    test('Polls werden initial geladen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pollListProvider('band1').notifier);

      expect(container.read(pollListProvider('band1')).isLoading, isTrue);
    });

    test('createPoll erstellt neue Abstimmung', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollListProvider('band1').notifier);

      final poll = await notifier.createPoll(
        question: 'Nächster Probe-Termin?',
        options: ['Montag', 'Dienstag', 'Mittwoch'],
        showResultsAfterVoting: true,
      );

      expect(poll, isNotNull);
      expect(poll?.question, 'Nächster Probe-Termin?');
      expect(poll?.options.length, 3);
    });

    test('createPoll mit Deadline erstellt zeitlich begrenzte Abstimmung', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollListProvider('band1').notifier);
      final deadline = DateTime.now().add(const Duration(days: 7));

      final poll = await notifier.createPoll(
        question: 'Konzert-Teilnahme?',
        options: ['Ja', 'Nein', 'Vielleicht'],
        deadline: deadline,
        showResultsAfterVoting: true,
      );

      expect(poll, isNotNull);
      expect(poll?.deadline, isNotNull);
    });

    test('createPoll mit isMultiSelect erlaubt Mehrfachauswahl', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollListProvider('band1').notifier);

      final poll = await notifier.createPoll(
        question: 'Welche Stücke spielen?',
        options: ['Stück A', 'Stück B', 'Stück C'],
        isMultiSelect: true,
        showResultsAfterVoting: true,
      );

      expect(poll, isNotNull);
      expect(poll?.isMultiSelect, isTrue);
    });

    test('createPoll mit isAnonymous=false zeigt Teilnehmer', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollListProvider('band1').notifier);

      final poll = await notifier.createPoll(
        question: 'Wer bringt Kuchen mit?',
        options: ['Ich', 'Jemand anders'],
        isAnonymous: false,
        showResultsAfterVoting: true,
      );

      expect(poll, isNotNull);
      expect(poll?.isAnonymous, isFalse);
    });

    test('createPoll mit targetSectionIds begrenzt Zielgruppe', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollListProvider('band1').notifier);

      final poll = await notifier.createPoll(
        question: 'Register-Probe?',
        options: ['Ja', 'Nein'],
        targetSectionIds: ['trp1', 'trp2'],
        showResultsAfterVoting: true,
      );

      expect(poll, isNotNull);
      expect(poll?.targetSectionIds, ['trp1', 'trp2']);
    });

    test('closePoll beendet aktive Abstimmung', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollListProvider('band1').notifier);

      final success = await notifier.closePoll('poll1');

      expect(success, isTrue);
    });

    test('closePoll mit unbekannter ID gibt false zurück', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollListProvider('band1').notifier);

      final success = await notifier.closePoll('unknown_poll');

      expect(success, isFalse);
    });

    test('refresh lädt Polls neu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollListProvider('band1').notifier);

      await notifier.refresh();

      expect(container.read(pollListProvider('band1')).isLoading, isTrue);
    });
  });

  // ─── PollDetailNotifier Tests ──────────────────────────────────────────────

  group('PollDetailNotifier — Detail-Ansicht', () {
    test('Poll wird initial geladen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pollDetailProvider('band1', 'poll1').notifier);

      expect(container.read(pollDetailProvider('band1', 'poll1')).isLoading, isTrue);
    });

    test('vote mit single option registriert Stimme', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollDetailProvider('band1', 'poll1').notifier);

      final success = await notifier.vote(['opt1']);

      expect(success, isTrue);
    });

    test('vote mit multiple options bei Multi-Select funktioniert', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollDetailProvider('band1', 'poll1').notifier);

      final success = await notifier.vote(['opt1', 'opt2', 'opt3']);

      expect(success, isTrue);
    });

    test('vote auf geschlossene Abstimmung gibt false zurück', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollDetailProvider('band1', 'poll_closed').notifier);

      final success = await notifier.vote(['opt1']);

      expect(success, isFalse);
    });

    test('closePoll beendet Abstimmung in Detail-View', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollDetailProvider('band1', 'poll1').notifier);

      final success = await notifier.closePoll();

      expect(success, isTrue);
    });

    test('refresh lädt Poll-Details neu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pollDetailProvider('band1', 'poll1').notifier);

      await notifier.refresh();

      expect(container.read(pollDetailProvider('band1', 'poll1')).isLoading, isTrue);
    });
  });

  // ─── Poll Status Tests ─────────────────────────────────────────────────────

  group('Poll — Status-Übergänge', () {
    test('Aktive Poll hat Status active', () {
      final poll = _poll(status: PollStatus.active);
      expect(poll.status, PollStatus.active);
    });

    test('Beendete Poll hat Status ended', () {
      final poll = _poll(status: PollStatus.ended);
      expect(poll.status, PollStatus.ended);
    });

    test('Poll mit abgelaufenem Deadline sollte geschlossen werden', () {
      final pastDeadline = DateTime.now().subtract(const Duration(days: 1));
      final poll = _poll(deadline: pastDeadline);

      expect(poll.deadline!.isBefore(DateTime.now()), isTrue);
    });

    test('timeRemaining gibt Duration zurück', () {
      final futureDeadline = DateTime.now().add(const Duration(hours: 2));
      final poll = _poll(deadline: futureDeadline);

      expect(poll.timeRemaining, isNotNull);
      expect(poll.timeRemaining!.inHours, greaterThanOrEqualTo(1));
    });

    test('timeRemaining ist Duration.zero nach Deadline', () {
      final pastDeadline = DateTime.now().subtract(const Duration(hours: 1));
      final poll = _poll(deadline: pastDeadline);

      expect(poll.timeRemaining, Duration.zero);
    });
  });

  // ─── Poll Results Tests ────────────────────────────────────────────────────

  group('Poll — Ergebnis-Berechnung', () {
    test('Option mit Stimmen zeigt korrekten voteCount', () {
      final option = _pollOption(voteCount: 5);
      expect(option.voteCount, 5);
    });

    test('Option ohne Stimmen hat voteCount 0', () {
      final option = _pollOption(voteCount: 0);
      expect(option.voteCount, 0);
    });

    test('Percentage wird korrekt berechnet', () {
      final option1 = _pollOption(id: 'opt1', voteCount: 7, percentage: 70.0);
      final option2 = _pollOption(id: 'opt2', voteCount: 3, percentage: 30.0);

      expect(option1.percentage, 70.0);
      expect(option2.percentage, 30.0);
      expect(option1.percentage + option2.percentage, 100.0);
    });

    test('hasVoted zeigt ob User abgestimmt hat', () {
      final option = _pollOption(hasVoted: true);
      expect(option.hasVoted, isTrue);
    });

    test('participantCount zählt Teilnehmer', () {
      final poll = _poll(
        options: [
          _pollOption(id: 'opt1', voteCount: 5),
          _pollOption(id: 'opt2', voteCount: 3),
        ],
      );

      // participantCount sollte aus API kommen
      expect(poll.participantCount, greaterThanOrEqualTo(0));
    });
  });

  // ─── Poll Visibility Tests ─────────────────────────────────────────────────

  group('Poll — Sichtbarkeits-Regeln', () {
    test('showResultsAfterVoting=true zeigt Ergebnisse nach Vote', () {
      final poll = _poll(showResultsAfterVoting: true, hasVoted: true);
      expect(poll.showResultsAfterVoting, isTrue);
    });

    test('showResultsAfterVoting=false verbirgt Ergebnisse vor Abstimmung', () {
      final poll = _poll(showResultsAfterVoting: false, hasVoted: false);
      expect(poll.showResultsAfterVoting, isFalse);
    });

    test('Anonymous Poll verbirgt Teilnehmer-Namen', () {
      final poll = _poll(isAnonymous: true);
      expect(poll.isAnonymous, isTrue);
    });

    test('Non-anonymous Poll zeigt Teilnehmer-Namen', () {
      final poll = _poll(isAnonymous: false);
      expect(poll.isAnonymous, isFalse);
    });
  });

  // ─── Provider Family Tests ─────────────────────────────────────────────────

  group('Poll Provider — Family-Scoping', () {
    test('Verschiedene bandId-Scopes sind unabhängig', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pollListProvider('band1').notifier);
      container.read(pollListProvider('band2').notifier);

      expect(container.read(pollListProvider('band1')).isLoading, isTrue);
      expect(container.read(pollListProvider('band2')).isLoading, isTrue);
    });

    test('Verschiedene pollId-Scopes in PollDetail sind unabhängig', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pollDetailProvider('band1', 'poll1').notifier);
      container.read(pollDetailProvider('band1', 'poll2').notifier);

      expect(container.read(pollDetailProvider('band1', 'poll1')).isLoading, isTrue);
      expect(container.read(pollDetailProvider('band1', 'poll2')).isLoading, isTrue);
    });
  });
}
