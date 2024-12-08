// screens/active_checklists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/checklist_model.dart';
import '../utils/date_time_utils.dart';
import '../utils/dialog_utils.dart';

class ActiveChecklistsScreen extends StatelessWidget {
  const ActiveChecklistsScreen({super.key});

  void _showDeleteAllDialog(BuildContext context) async {
    final confirmed = await DialogUtils.showConfirmationDialog(
      context: context,
      title: 'Delete All Active Processes',
      content:
          'Are you sure you want to delete all active processes? This action cannot be undone.',
      confirmText: 'Delete All',
      isDangerous: true,
    );

    if (confirmed && context.mounted) {
      await Provider.of<ChecklistModel>(context, listen: false)
          .deleteAllActive();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All active processes deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Processes'),
        actions: [
          Consumer<ChecklistModel>(
            builder: (context, model, child) {
              if (model.activeChecklists.isEmpty)
                return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () => _showDeleteAllDialog(context),
                tooltip: 'Delete All Active',
              );
            },
          ),
        ],
      ),
      body: Consumer<ChecklistModel>(
        builder: (context, checklistModel, child) {
          if (checklistModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeChecklists = checklistModel.activeChecklists;

          if (activeChecklists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pending_actions,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active processes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a new process from templates',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: activeChecklists.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final checklist = activeChecklists[index];
              final completedItems =
                  checklist.items.where((item) => item.isChecked).length;
              final progress = checklist.items.isEmpty
                  ? 0.0
                  : completedItems / checklist.items.length;

              return Card(
                key: ValueKey('active-card-${checklist.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(checklist.title),
                      subtitle: Text(checklist.description ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: checklist.canComplete
                            ? () async {
                                final hasUncheckedItems = checklist.items
                                    .any((item) => !item.isChecked);
                                String dialogContent =
                                    'Are you sure you want to complete this process?';
                                if (hasUncheckedItems) {
                                  dialogContent =
                                      'This process has unchecked items. Are you sure you want to complete it anyway?';
                                }

                                final confirmed =
                                    await DialogUtils.showConfirmationDialog(
                                  context: context,
                                  title: 'Complete Process',
                                  content: dialogContent,
                                  confirmText: 'Complete',
                                );

                                if (confirmed && context.mounted) {
                                  await checklistModel
                                      .completeChecklist(checklist.id);
                                }
                              }
                            : null,
                      ),
                      onTap: () async {
                        debugPrint(
                            'Tapping checklist with ID: ${checklist.id}');
                        debugPrint(
                            'Number of items: ${checklist.items.length}');
                        debugPrint(
                            'Items IDs: ${checklist.items.map((e) => e.id).toList()}');

                        await Navigator.pushNamed(
                          context,
                          '/checklist',
                          arguments: checklist,
                        );

                        if (context.mounted) {
                          await checklistModel.refreshChecklists();
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Admin: ${checklist.adminName}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Running: ${DateTimeUtils.formatRunningTime(checklist.startedAt!)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedItems of ${checklist.items.length} items completed',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
