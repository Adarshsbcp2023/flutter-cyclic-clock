import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../models/cyclic_playlist.dart';
import '../providers/alarm_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/day_selector.dart';
import '../utils/time_utils.dart';
import 'music_selector_screen.dart';

class AlarmEditorScreen extends StatefulWidget {
  final Alarm? alarm;
  const AlarmEditorScreen({super.key, this.alarm});

  @override
  State<AlarmEditorScreen> createState() => _AlarmEditorScreenState();
}

class _AlarmEditorScreenState extends State<AlarmEditorScreen> {
  late int _hour;
  late int _minute;
  late String _label;
  late List<bool> _repeatDays;
  late bool _isCyclicEnabled;
  late String? _selectedPlaylistId;
  late int _snoozeMinutes;
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    final now = TimeOfDay.now();
    _hour = alarm?.hour ?? now.hour;
    _minute = alarm?.minute ?? now.minute;
    _label = alarm?.label ?? '';
    _repeatDays = alarm?.repeatDays ?? List.filled(7, false);
    _isCyclicEnabled = alarm?.isCyclicEnabled ?? false;
    _selectedPlaylistId = alarm?.playlistId;
    _snoozeMinutes = alarm?.snoozeMinutes ?? 5;
    _labelController = TextEditingController(text: _label);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  Future<void> _save() async {
    final alarm = Alarm(
      id: widget.alarm?.id ?? const Uuid().v4(),
      hour: _hour,
      minute: _minute,
      label: _labelController.text.trim(),
      isEnabled: true,
      repeatDays: _repeatDays,
      isCyclicEnabled: _isCyclicEnabled,
      playlistId: _isCyclicEnabled ? _selectedPlaylistId : null,
      snoozeMinutes: _snoozeMinutes,
    );

    final provider = context.read<AlarmProvider>();
    if (widget.alarm == null) {
      await provider.addAlarm(alarm);
    } else {
      await provider.updateAlarm(alarm);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm == null ? 'New Alarm' : 'Edit Alarm'),
        actions: [
          Semantics(
            label: 'Save alarm',
            child: TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Time display
          Semantics(
            label:
                'Selected time: ${TimeUtils.formatTime(_hour, _minute)}. Tap to change',
            child: GestureDetector(
              onTap: _pickTime,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 24, horizontal: 16),
                  child: Center(
                    child: Text(
                      TimeUtils.formatTime(_hour, _minute),
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w300,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Label
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Alarm Label',
              hintText: 'e.g. Morning Workout',
              prefixIcon: Icon(Icons.label_outline),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            maxLength: 50,
          ),
          const SizedBox(height: 16),

          // Repeat Days
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Repeat',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DaySelector(
                    selectedDays: _repeatDays,
                    onChanged: (days) =>
                        setState(() => _repeatDays = days),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TimeUtils.formatRepeatDays(_repeatDays),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Snooze
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Snooze Duration',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '$_snoozeMinutes min',
                        style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Semantics(
                    label: 'Snooze duration: $_snoozeMinutes minutes',
                    child: Slider(
                      value: _snoozeMinutes.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$_snoozeMinutes min',
                      onChanged: (v) =>
                          setState(() => _snoozeMinutes = v.round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cyclic Music Toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Semantics(
                    label:
                        'Cyclic music ${_isCyclicEnabled ? "enabled" : "disabled"}',
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cyclic Playlist'),
                      subtitle:
                          const Text('Play a different track each day'),
                      secondary: Icon(
                        Icons.playlist_play,
                        color:
                            _isCyclicEnabled ? colorScheme.primary : null,
                      ),
                      value: _isCyclicEnabled,
                      onChanged: (v) =>
                          setState(() => _isCyclicEnabled = v),
                    ),
                  ),
                  if (_isCyclicEnabled) ...[
                    const Divider(),
                    _buildPlaylistSelector(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPlaylistSelector() {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, _) {
        final playlists = playlistProvider.playlists;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No playlists yet. Create one below.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedPlaylistId,
                decoration: const InputDecoration(
                  labelText: 'Select Playlist',
                  border: OutlineInputBorder(),
                ),
                items: playlists
                    .map((p) =>
                        DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedPlaylistId = v),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_selectedPlaylistId != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Playlist'),
                      onPressed: () => _openPlaylistEditor(
                        playlistProvider
                            .getPlaylistById(_selectedPlaylistId!),
                      ),
                    ),
                  ),
                if (_selectedPlaylistId != null) const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('New Playlist'),
                    onPressed: () =>
                        _createAndOpenPlaylist(playlistProvider),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAndOpenPlaylist(PlaylistProvider provider) async {
    final name = await _promptPlaylistName();
    if (name == null || name.isEmpty) return;
    final playlist = await provider.createPlaylist(name);
    setState(() => _selectedPlaylistId = playlist.id);
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MusicSelectorScreen(playlist: playlist)),
      );
    }
  }

  Future<void> _openPlaylistEditor(CyclicPlaylist? playlist) async {
    if (playlist == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => MusicSelectorScreen(playlist: playlist)),
    );
  }

  Future<String?> _promptPlaylistName() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
