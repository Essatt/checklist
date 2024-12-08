// screens/checklist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/checklist_model.dart';
import '../utils/date_time_utils.dart';
import '../utils/dialog_utils.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  void _showAddItemDialog(BuildContext context, Checklist checklist) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Step'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Step Description',
            hintText: 'Enter step description',
          ),
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                final newItem = ChecklistItem(
                  text: textController.text.trim(),
                  order: checklist.items.length,
                );
                checklist.items.add(newItem);
                if (!context.mounted) return;
                await Provider.of<ChecklistModel>(context, listen: false)
                    .updateChecklist(checklist);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    Checklist checklist,
    ChecklistItem item,
  ) {
    final textController = TextEditingController(text: item.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Step'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Step Description',
            hintText: 'Enter step description',
          ),
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                item.text = textController.text.trim();
                if (!context.mounted) return;
                await Provider.of<ChecklistModel>(context, listen: false)
                    .updateChecklist(checklist);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final checklist = ModalRoute.of(context)?.settings.arguments as Checklist?;

    debugPrint('ChecklistScreen build - Checklist: ${checklist?.id}');
    debugPrint('Items: ${checklist?.items.length}');

    if (checklist == null) {
      debugPrint('Checklist is null!');
      Navigator.pop(context);
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(checklist.title),
        actions: [
          if (checklist.canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddItemDialog(context, checklist),
            ),
        ],
      ),
      body: Column(
        children: [
          if (checklist.status != ChecklistStatus.template) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Admin: ${checklist.adminName}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (checklist.status == ChecklistStatus.archived)
                        Text(
                          'Completed: ${DateTimeUtils.formatDateTime(checklist.completedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    checklist.description ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: Consumer<ChecklistModel>(
              builder: (context, checklistModel, child) {
                if (checklist.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No steps yet',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        if (checklist.canEdit) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showAddItemDialog(context, checklist),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Step'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  key: ValueKey('checklist-items-list-${checklist.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: checklist.items.length,
                  buildDefaultDragHandles: checklist.canEdit,
                  onReorder: (int oldIndex, int newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    final item = checklist.items.removeAt(oldIndex);
                    checklist.items.insert(newIndex, item);
                    Future(() {
                      if (context.mounted) {
                        checklistModel.reorderItems(
                          checklist,
                          oldIndex,
                          newIndex,
                        );
                      }
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = checklist.items[index];
                    return Dismissible(
                      key: ValueKey('dismissible-${checklist.id}-${item.id}'),
                      direction: checklist.canEdit
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return DialogUtils.showConfirmationDialog(
                          context: context,
                          title: 'Delete Step',
                          content:
                              'Are you sure you want to delete "${item.text}"?',
                          confirmText: 'Delete',
                          isDangerous: true,
                        );
                      },
                      onDismissed: (direction) async {
                        checklist.items.removeAt(index);
                        await checklistModel.updateChecklist(checklist);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Step deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () async {
                                checklist.items.insert(index, item);
                                await checklistModel.updateChecklist(checklist);
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          key: ValueKey('tile-${checklist.id}-${item.id}'),
                          leading: checklist.status != ChecklistStatus.template
                              ? Checkbox(
                                  value: item.isChecked,
                                  onChanged: checklist.canEdit
                                      ? (bool? value) async {
                                          await checklistModel.toggleItemCheck(
                                            checklist,
                                            item.id,
                                          );
                                        }
                                      : null,
                                )
                              : CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.grey[300],
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                          title: Text(
                            item.text,
                            style: TextStyle(
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isChecked ? Colors.grey : null,
                            ),
                          ),
                          subtitle: item.checkedAt != null
                              ? Text(
                                  'Completed: ${DateTimeUtils.formatDateTime(item.checkedAt!)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              : null,
                          trailing: checklist.canEdit
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showEditItemDialog(
                                        context,
                                        checklist,
                                        item,
                                      ),
                                    ),
                                    if (checklist.canEdit)
                                      const Icon(Icons.drag_handle),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: checklist.status == ChecklistStatus.active
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton(
                  onPressed: checklist.canComplete
                      ? () async {
                          final hasUncheckedItems =
                              checklist.items.any((item) => !item.isChecked);
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
                            await Provider.of<ChecklistModel>(
                              context,
                              listen: false,
                            ).completeChecklist(checklist.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        }
                      : null,
                  child: const Text('Complete Process'),
                ),
              ),
            )
          : null,
    );
  }
}
