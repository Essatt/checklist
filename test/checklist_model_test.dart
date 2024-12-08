// test/checklist_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_flutter/models/checklist_model.dart';

void main() {
  group('ChecklistModel Tests', () {
    late ChecklistModel model;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      model = ChecklistModel();
      // Wait for the model to initialize
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('Create Template', () async {
      final template = Checklist(
        title: 'Test Template',
        items: [
          ChecklistItem(text: 'Step 1', order: 0),
          ChecklistItem(text: 'Step 2', order: 1),
        ],
      );

      await model.addChecklist(template);
      expect(model.templates.length, 1);
      expect(model.templates.first.title, 'Test Template');
      expect(model.templates.first.items.length, 2);
      expect(model.templates.first.status, ChecklistStatus.template);
    });

    test('Start Process from Template', () async {
      final template = Checklist(
        title: 'Test Template',
        items: [
          ChecklistItem(text: 'Step 1', order: 0),
          ChecklistItem(text: 'Step 2', order: 1),
        ],
      );

      await model.addChecklist(template);
      await model.startNewChecklistFromTemplate(
        template.id,
        'Test Admin',
        'Test Description',
      );

      expect(model.templates.length, 1);
      expect(model.activeChecklists.length, 1);

      final active = model.activeChecklists.first;
      expect(active.adminName, 'Test Admin');
      expect(active.description, 'Test Description');
      expect(active.items.length, 2);
      expect(active.startedAt, isNotNull);
      expect(active.items.every((item) => !item.isChecked), true);
      expect(active.status, ChecklistStatus.active);
    });

    test('Complete Process', () async {
      // Create and start a checklist
      final template = Checklist(
        title: 'Test Template',
        items: [
          ChecklistItem(text: 'Step 1', order: 0),
          ChecklistItem(text: 'Step 2', order: 1),
        ],
      );

      await model.addChecklist(template);
      await model.startNewChecklistFromTemplate(
        template.id,
        'Test Admin',
        'Test Description',
      );

      // Mark all items as checked
      final active = model.activeChecklists.first;
      for (var item in active.items) {
        await model.toggleItemCheck(active, item.id);
      }

      // Complete the checklist
      await model.completeChecklist(active.id);

      // Verify results
      expect(model.activeChecklists.length, 0);
      expect(model.archivedChecklists.length, 1);

      final archived = model.archivedChecklists.first;
      expect(archived.completedAt, isNotNull);
      expect(archived.completionTime, isNotNull);
      expect(archived.status, ChecklistStatus.archived);
    });

    test('Cannot complete process with unchecked items', () async {
      final template = Checklist(
        title: 'Test Template',
        items: [
          ChecklistItem(text: 'Step 1', order: 0),
          ChecklistItem(text: 'Step 2', order: 1),
        ],
      );

      await model.addChecklist(template);
      await model.startNewChecklistFromTemplate(
        template.id,
        'Test Admin',
        'Test Description',
      );

      final active = model.activeChecklists.first;
      // Only check one item
      await model.toggleItemCheck(active, active.items.first.id);

      // Try to complete
      await model.completeChecklist(active.id);

      // Verify checklist wasn't completed
      expect(model.activeChecklists.length, 1);
      expect(model.archivedChecklists.length, 0);
      expect(active.status, ChecklistStatus.active);
    });

    test('Reorder Items', () async {
      final checklist = Checklist(
        title: 'Test Checklist',
        items: [
          ChecklistItem(text: 'Step 1', order: 0),
          ChecklistItem(text: 'Step 2', order: 1),
          ChecklistItem(text: 'Step 3', order: 2),
        ],
      );

      await model.addChecklist(checklist);
      await model.reorderItems(checklist, 0, 2);

      // Verify item order
      expect(checklist.items[0].text, 'Step 2');
      expect(checklist.items[1].text, 'Step 3');
      expect(checklist.items[2].text, 'Step 1');

      // Verify order values are updated
      expect(checklist.items[0].order, 0);
      expect(checklist.items[1].order, 1);
      expect(checklist.items[2].order, 2);
    });

    test('Archive sorting', () async {
      // Create two checklists
      final template = Checklist(
        title: 'Test Template',
        items: [ChecklistItem(text: 'Step 1', order: 0)],
      );

      await model.addChecklist(template);

      // Start and complete first checklist
      await model.startNewChecklistFromTemplate(
        template.id,
        'Admin 1',
        'First checklist',
      );
      var active1 = model.activeChecklists.first;
      await model.toggleItemCheck(active1, active1.items.first.id);
      await model.completeChecklist(active1.id);

      await Future.delayed(const Duration(seconds: 1));

      // Start and complete second checklist
      await model.startNewChecklistFromTemplate(
        template.id,
        'Admin 2',
        'Second checklist',
      );
      var active2 = model.activeChecklists.first;
      await model.toggleItemCheck(active2, active2.items.first.id);
      await model.completeChecklist(active2.id);

      // Verify archive order (newest first)
      expect(model.archivedChecklists.length, 2);
      expect(model.archivedChecklists[0].description, 'Second checklist');
      expect(model.archivedChecklists[1].description, 'First checklist');
    });
  });
}
