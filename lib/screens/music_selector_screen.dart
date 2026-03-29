import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/cyclic_playlist.dart';
import '../providers/playlist_provider.dart';
import '../services/audio_service.dart';

class MusicSelectorScreen extends StatefulWidget {
  final CyclicPlaylist playlist;
  const MusicSelectorScreen({super.key, required this.playlist});

  @override
  State<MusicSelectorScreen> createState() => _MusicSelectorScreenState();
}

class _MusicSelectorScreenState extends State<MusicSelectorScreen> {
  final AudioService _audio = AudioService();
  int? _playingIndex;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
  }

  @override
  void dispose() {
    _audio.stop();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addTracks() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null) return;
    final provider = context.read<PlaylistProvider>();
    final playlist =
        provider.getPlaylistById(widget.playlist.id) ?? widget.playlist;
    for (final file in result.files) {
      if (file.path != null) {
        await provider.addTrack(playlist.id, file.path!);
      }
    }
  }

  Future<void> _saveName() async {
    final provider = context.read<PlaylistProvider>();
    final playlist =
        provider.getPlaylistById(widget.playlist.id) ?? widget.playlist;
    final updated = playlist.copyWith(name: _nameController.text.trim());
    await provider.updatePlaylist(updated);
  }

  Future<void> _togglePreview(CyclicPlaylist playlist, int index) async {
    if (_playingIndex == index) {
      await _audio.stop();
      setState(() => _playingIndex = null);
    } else {
      await _audio.stop();
      final track = Track.fromPath(playlist.trackPaths[index]);
      await _audio.playTrack(playlist.trackPaths[index],
          trackName: track.name);
      setState(() => _playingIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist Editor'),
        actions: [
          Semantics(
            label: 'Save playlist name',
            child: TextButton(
              onPressed: () async {
                await _saveName();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, _) {
          final playlist =
              provider.getPlaylistById(widget.playlist.id) ?? widget.playlist;
          final todayIndex = playlist.trackPaths.isEmpty
              ? -1
              : playlist.currentIndex % playlist.trackPaths.length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Playlist Name',
                    prefixIcon: Icon(Icons.playlist_play),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _saveName(),
                ),
              ),
              if (playlist.trackPaths.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_off_outlined,
                          size: 60,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text('No tracks added yet'),
                        const SizedBox(height: 4),
                        const Text(
                            'Tap the button below to add audio files'),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ReorderableListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: playlist.trackPaths.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      provider.reorderTracks(
                          playlist.id, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final track =
                          Track.fromPath(playlist.trackPaths[index]);
                      final isToday = index == todayIndex;
                      final isPlaying = _playingIndex == index;

                      return Dismissible(
                        key: ValueKey(playlist.trackPaths[index]),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: Colors.red.shade400,
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) {
                          if (_playingIndex == index) {
                            _audio.stop();
                            setState(() => _playingIndex = null);
                          }
                          provider.removeTrack(playlist.id, index);
                        },
                        child: Card(
                          child: ListTile(
                            leading: Semantics(
                              label: isPlaying
                                  ? 'Stop preview'
                                  : 'Preview track ${track.name}',
                              child: IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.stop_circle_outlined
                                      : Icons.play_circle_outline,
                                ),
                                color: isPlaying
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                    : null,
                                onPressed: () =>
                                    _togglePreview(playlist, index),
                              ),
                            ),
                            title: Text(
                              track.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: isToday
                                ? Text(
                                    "Today's track",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                            trailing: Semantics(
                              label: 'Drag to reorder',
                              child: const Icon(Icons.drag_handle),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _addTracks,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Audio Files'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
