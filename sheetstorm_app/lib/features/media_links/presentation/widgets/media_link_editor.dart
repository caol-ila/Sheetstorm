import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/media_links/application/media_link_notifier.dart';

class MediaLinkEditor extends ConsumerStatefulWidget {
  const MediaLinkEditor({
    required this.kapelleId,
    required this.stueckId,
    super.key,
  });

  final String kapelleId;
  final String stueckId;

  @override
  ConsumerState<MediaLinkEditor> createState() => _MediaLinkEditorState();
}

class _MediaLinkEditorState extends ConsumerState<MediaLinkEditor> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Link hinzufügen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'youtube.com/watch?v=... oder open.spotify.com/...',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte gib eine URL ein';
                }
                if (!_isValidUrl(value)) {
                  return 'Bitte gib eine gültige YouTube- oder Spotify-URL ein';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Unterstützte Formate:\n• YouTube: youtube.com, youtu.be\n• Spotify: open.spotify.com/track',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _isLoading ? null : _onSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('spotify.com');
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final notifier = ref.read(
      mediaLinkProvider(widget.kapelleId, widget.stueckId).notifier,
    );

    final link = await notifier.addLink(_urlController.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);
      if (link != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link hinzugefügt')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Hinzufügen des Links')),
        );
      }
    }
  }
}
