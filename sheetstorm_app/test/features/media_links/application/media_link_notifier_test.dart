import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/media_links/application/media_link_notifier.dart';
import 'package:sheetstorm/features/media_links/data/models/media_link_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

MediaLink _link({
  String id = 'ml1',
  String url = 'https://www.youtube.com/watch?v=test',
  MediaLinkType plattform = MediaLinkType.youtube,
  String? titel,
}) =>
    MediaLink(
      id: id,
      stueckId: 'piece1',
      plattform: plattform,
      url: url,
      titel: titel ?? 'Test Video',
      thumbnailUrl: 'https://img.youtube.com/vi/test/default.jpg',
      dauerSekunden: 180,
      vorgeschlagenVonAi: false,
      erstelltAm: DateTime(2025, 1, 1),
    );

MediaLinkVorschlag _vorschlag({
  String url = 'https://www.youtube.com/watch?v=suggested',
  MediaLinkType plattform = MediaLinkType.youtube,
  String titel = 'Vorgeschlagenes Video',
}) =>
    MediaLinkVorschlag(
      plattform: plattform,
      url: url,
      titel: titel,
      thumbnailUrl: 'https://img.youtube.com/vi/suggested/default.jpg',
      dauerSekunden: 240,
      kuenstler: 'Test Künstler',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── MediaLinkNotifier — Provider ─────────────────────────────────────────

  group('MediaLinkNotifier — Provider', () {
    test('provider exists and initial state is AsyncLoading', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state =
          container.read(mediaLinkProvider('band1', 'piece1'));
      expect(state, isA<AsyncLoading<List<MediaLink>>>());
    });

    test('notifier can be read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        mediaLinkProvider('band1', 'piece1').notifier,
      );
      expect(notifier, isA<MediaLinkNotifier>());
    });
  });

  // ─── MediaLink — Model Tests ──────────────────────────────────────────────

  group('MediaLink — Model', () {
    test('MediaLink model construction', () {
      final link = _link(id: 'ml1', url: 'https://yt.com/test');
      expect(link.id, 'ml1');
      expect(link.url, 'https://yt.com/test');
      expect(link.plattform, MediaLinkType.youtube);
      expect(link.stueckId, 'piece1');
      expect(link.dauerSekunden, 180);
    });

    test('MediaLinkVorschlag model construction', () {
      final v = _vorschlag(titel: 'Vorschlag');
      expect(v.titel, 'Vorschlag');
      expect(v.plattform, MediaLinkType.youtube);
      expect(v.kuenstler, 'Test Künstler');
    });

    test('MediaLink with different platforms', () {
      final yt = _link(plattform: MediaLinkType.youtube);
      expect(yt.plattform, MediaLinkType.youtube);

      final sp = _link(plattform: MediaLinkType.spotify);
      expect(sp.plattform, MediaLinkType.spotify);

      final sc = _link(plattform: MediaLinkType.soundcloud);
      expect(sc.plattform, MediaLinkType.soundcloud);

      final other = _link(plattform: MediaLinkType.other);
      expect(other.plattform, MediaLinkType.other);
    });
  });

  // ─── MediaLink — Dauer-Formatierung ───────────────────────────────────────

  group('MediaLink — formattedDuration', () {
    test('180 Sekunden → 3:00', () {
      final link = _link(id: 'ml1', url: 'https://test.com');
      final formatted =
          MediaLink.fromJson(link.toJson()..['dauerSekunden'] = 180)
              .formattedDuration;
      expect(formatted, '3:00');
    });

    test('125 Sekunden → 2:05', () {
      final link = _link(id: 'ml1', url: 'https://test.com');
      final formatted =
          MediaLink.fromJson(link.toJson()..['dauerSekunden'] = 125)
              .formattedDuration;
      expect(formatted, '2:05');
    });

    test('59 Sekunden → 0:59', () {
      final link = _link(id: 'ml1', url: 'https://test.com');
      final formatted =
          MediaLink.fromJson(link.toJson()..['dauerSekunden'] = 59)
              .formattedDuration;
      expect(formatted, '0:59');
    });

    test('Null Dauer → leerer String', () {
      final link = _link(id: 'ml1', url: 'https://test.com');
      final formatted =
          MediaLink.fromJson(link.toJson()..remove('dauerSekunden'))
              .formattedDuration;
      expect(formatted, '');
    });
  });

  // ─── MediaLinkType — Plattform-Erkennung ──────────────────────────────────

  group('MediaLinkType — Plattform-Erkennung', () {
    test('YouTube-URL wird erkannt', () {
      final type = MediaLinkType.fromJson('youtube');
      expect(type, MediaLinkType.youtube);
    });

    test('Spotify-URL wird erkannt', () {
      final type = MediaLinkType.fromJson('spotify');
      expect(type, MediaLinkType.spotify);
    });

    test('SoundCloud-URL wird erkannt', () {
      final type = MediaLinkType.fromJson('soundcloud');
      expect(type, MediaLinkType.soundcloud);
    });

    test('Unbekannte URL → other', () {
      final type = MediaLinkType.fromJson('unknown');
      expect(type, MediaLinkType.other);
    });

    test('Case-insensitive Erkennung', () {
      expect(MediaLinkType.fromJson('YouTube'), MediaLinkType.youtube);
      expect(MediaLinkType.fromJson('SPOTIFY'), MediaLinkType.spotify);
      expect(MediaLinkType.fromJson('SoundCloud'), MediaLinkType.soundcloud);
    });
  });
}
