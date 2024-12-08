// screens/templates_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/checklist_model.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  void _showStartProcessDialog(BuildContext context, Checklist template) {
    final adminController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Process'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Template: ${template.title}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adminController,
              decoration: const InputDecoration(
                labelText: 'Admin Name',
                hintText: 'Enter your name',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter process description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (adminController.text.isEmpty ||
                  descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                  ),
                );
                return;
              }

              if (context.mounted) {
                await Provider.of<ChecklistModel>(context, listen: false)
                    .startNewChecklistFromTemplate(
                  template.id,
                  adminController.text,
                  descriptionController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Process started successfully'),
                    ),
                  );
                }
              }
            },
            child: const Text('Start Process'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Templates'),
      ),
      body: Consumer<ChecklistModel>(
        builder: (context, checklistModel, child) {
          if (checklistModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final templates = checklistModel.templates;

          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No templates yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a template to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: templates.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.list_alt),
                  ),
                  title: Text(template.title),
                  subtitle: Text('${template.items.length} steps'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/checklist',
                            arguments: template,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _showStartProcessDialog(
                          context,
                          template,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
