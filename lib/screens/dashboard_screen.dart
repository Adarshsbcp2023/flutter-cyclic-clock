import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alarm_provider.dart';
import '../models/alarm.dart';
import '../utils/permission_utils.dart';
import '../widgets/alarm_card.dart';
import 'alarm_editor_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionUtils.checkAndRequestAll(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cyclic Alarm Clock'),
        centerTitle: false,
        actions: [
          Semantics(
            label: 'Settings',
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<AlarmProvider>(
        builder: (context, alarmProvider, _) {
          if (alarmProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (alarmProvider.alarms.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: alarmProvider.alarms.length,
            itemBuilder: (context, index) {
              final alarm = alarmProvider.alarms[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: ValueKey(alarm.id),
                  direction: DismissDirection.endToStart,
                  background: _buildDismissBackground(),
                  confirmDismiss: (direction) => _confirmDelete(context),
                  onDismissed: (_) {
                    context.read<AlarmProvider>().deleteAlarm(alarm.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Alarm deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            context.read<AlarmProvider>().addAlarm(alarm);
                          },
                        ),
                      ),
                    );
                  },
                  child: AlarmCard(
                    alarm: alarm,
                    onToggle: () {
                      context.read<AlarmProvider>().toggleAlarm(alarm.id);
                    },
                    onTap: () => _editAlarm(context, alarm),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Semantics(
        label: 'Add new alarm',
        child: FloatingActionButton.extended(
          onPressed: () => _addAlarm(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Alarm'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No alarms yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first cyclic alarm',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Alarm'),
            content:
                const Text('Are you sure you want to delete this alarm?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  void _addAlarm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlarmEditorScreen()),
    );
  }

  void _editAlarm(BuildContext context, Alarm alarm) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AlarmEditorScreen(alarm: alarm)),
    );
  }
}
