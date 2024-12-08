// screens/archived_checklists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/checklist_model.dart';

class ArchivedChecklistsScreen extends StatelessWidget {
  const ArchivedChecklistsScreen({super.key});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDetailsDialog(BuildContext context, Checklist checklist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(checklist.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailItem(
                title: 'Admin',
                value: checklist.adminName ?? 'N/A',
              ),
              const SizedBox(height: 8),
              _DetailItem(
                title: 'Description',
                value: checklist.description ?? 'N/A',
              ),
              const SizedBox(height: 16),
              _DetailItem(
                title: 'Started',
                value: _formatDateTime(checklist.startedAt!),
              ),
              const SizedBox(height: 8),
              _DetailItem(
                title: 'Completed',
                value: _formatDateTime(checklist.completedAt!),
              ),
              const SizedBox(height: 8),
              _DetailItem(
                title: 'Time Taken',
                value: _formatDuration(checklist.completionTime!),
              ),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...checklist.items.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          item.isChecked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20,
                          color: item.isChecked ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.text,
                            style: TextStyle(
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isChecked ? Colors.grey : null,
                            ),
                          ),
                        ),
                        if (item.checkedAt != null)
                          Text(
                            _formatDateTime(item.checkedAt!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Processes'),
      ),
      body: Consumer<ChecklistModel>(
        builder: (context, checklistModel, child) {
          if (checklistModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final archivedChecklists = checklistModel.archivedChecklists;

          if (archivedChecklists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No archived processes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Completed processes will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: archivedChecklists.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final checklist = archivedChecklists[index];
              final completedItems =
                  checklist.items.where((item) => item.isChecked).length;
              final progress = checklist.items.isEmpty
                  ? 0.0
                  : completedItems / checklist.items.length;

              return Card(
                child: InkWell(
                  onTap: () => _showDetailsDialog(context, checklist),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    checklist.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'By ${checklist.adminName}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatDuration(checklist.completionTime!),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$completedItems/${checklist.items.length} items completed',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Completed: ${_formatDateTime(checklist.completedAt!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String title;
  final String value;

  const _DetailItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
