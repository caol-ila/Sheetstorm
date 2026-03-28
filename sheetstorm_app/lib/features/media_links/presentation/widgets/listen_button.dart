import 'package:flutter/material.dart';
import 'package:sheetstorm/features/media_links/data/models/media_link_models.dart';
import 'package:url_launcher/url_launcher.dart';

class ListenButton extends StatelessWidget {
  const ListenButton({
    required this.url,
    required this.platform,
    super.key,
  });

  final String url;
  final MediaLinkType platform;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _launchUrl(context),
      icon: const Icon(Icons.play_arrow),
      tooltip: 'Anhören',
    );
  }

  Future<void> _launchUrl(BuildContext context) async {
    final uri = Uri.parse(url);
    
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link konnte nicht geöffnet werden'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }
}
