import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../providers/playlist_provider.dart';
import '../utils/time_utils.dart';

class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final repeatText = TimeUtils.formatRepeatDays(alarm.repeatDays);

    return Semantics(
      label: 'Alarm at ${TimeUtils.formatTime(alarm.hour, alarm.minute)}, '
          '$repeatText, ${alarm.isEnabled ? "enabled" : "disabled"}',
      child: Card(
        elevation: alarm.isEnabled ? 2 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            TimeUtils.formatTime(alarm.hour, alarm.minute),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: alarm.isEnabled
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface
                                          .withOpacity(0.4),
                                  fontWeight: FontWeight.w300,
                                ),
                          ),
                          const SizedBox(width: 8),
                          if (alarm.isCyclicEnabled)
                            Tooltip(
                              message: 'Cyclic playlist enabled',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.playlist_play,
                                        size: 14,
                                        color: colorScheme.primary),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Cyclic',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (alarm.label.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          alarm.label,
                          style: TextStyle(
                            color: alarm.isEnabled
                                ? colorScheme.onSurface.withOpacity(0.7)
                                : colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        repeatText,
                        style: TextStyle(
                          fontSize: 12,
                          color: alarm.isEnabled
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      if (alarm.isCyclicEnabled && alarm.playlistId != null)
                        _PlaylistNameText(playlistId: alarm.playlistId!),
                    ],
                  ),
                ),
                Semantics(
                  label:
                      '${alarm.isEnabled ? "Disable" : "Enable"} alarm at '
                      '${TimeUtils.formatTime(alarm.hour, alarm.minute)}',
                  child: Switch.adaptive(
                    value: alarm.isEnabled,
                    onChanged: (_) => onToggle(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistNameText extends StatelessWidget {
  final String playlistId;
  const _PlaylistNameText({required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        final playlist = provider.getPlaylistById(playlistId);
        if (playlist == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '♪ ${playlist.name}',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        );
      },
    );
  }
}
