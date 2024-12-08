// models/checklist_model.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ChecklistStatus { template, active, archived }

class ChecklistItem {
  String id;
  String text;
  bool isChecked;
  int order;
  DateTime? checkedAt;

  ChecklistItem({
    String? id,
    required this.text,
    this.isChecked = false,
    required this.order,
    this.checkedAt,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}-${order}';

  void toggleChecked() {
    isChecked = !isChecked;
    checkedAt = isChecked ? DateTime.now() : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isChecked': isChecked,
      'order': order,
      'checkedAt': checkedAt?.toIso8601String(),
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      text: json['text'],
      isChecked: json['isChecked'],
      order: json['order'],
      checkedAt:
          json['checkedAt'] != null ? DateTime.parse(json['checkedAt']) : null,
    );
  }

  ChecklistItem copyWith({bool resetStatus = false}) {
    return ChecklistItem(
      id: resetStatus
          ? null
          : id, // This will force new ID generation if resetStatus is true
      text: text,
      order: order,
      isChecked: resetStatus ? false : isChecked,
      checkedAt: resetStatus ? null : checkedAt,
    );
  }
}

class Checklist {
  String id;
  String title;
  List<ChecklistItem> items;
  DateTime createdAt;
  DateTime updatedAt;
  ChecklistStatus status;
  String? adminName;
  String? description;
  DateTime? startedAt;
  DateTime? completedAt;
  Duration? completionTime;

  bool get canEdit => status != ChecklistStatus.archived;
  bool get canComplete => status == ChecklistStatus.active && items.isNotEmpty;

  Checklist({
    String? id,
    required this.title,
    List<ChecklistItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status = ChecklistStatus.template,
    this.adminName,
    this.description,
    this.startedAt,
    this.completedAt,
    this.completionTime,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.toString(),
      'adminName': adminName,
      'description': description,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'completionTime': completionTime?.inSeconds,
    };
  }

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'],
      title: json['title'],
      items: (json['items'] as List)
          .map((item) => ChecklistItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: ChecklistStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ChecklistStatus.template,
      ),
      adminName: json['adminName'],
      description: json['description'],
      startedAt:
          json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      completionTime: json['completionTime'] != null
          ? Duration(seconds: json['completionTime'])
          : null,
    );
  }

  Checklist copyWith({
    String? title,
    List<ChecklistItem>? items,
    ChecklistStatus? status,
    String? adminName,
    String? description,
  }) {
    return Checklist(
      id: id,
      title: title ?? this.title,
      items: items ?? List.from(this.items),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      status: status ?? this.status,
      adminName: adminName ?? this.adminName,
      description: description ?? this.description,
      startedAt: startedAt,
      completedAt: completedAt,
      completionTime: completionTime,
    );
  }

  Checklist createActiveFromTemplate({
    required String adminName,
    required String description,
  }) {
    return Checklist(
      title: title,
      items: items.map((item) => item.copyWith(resetStatus: true)).toList(),
      status: ChecklistStatus.active,
      adminName: adminName,
      description: description,
      startedAt: DateTime.now(),
    );
  }

  void complete() {
    if (status == ChecklistStatus.active && canComplete) {
      completedAt = DateTime.now();
      completionTime = completedAt!.difference(startedAt!);
      status = ChecklistStatus.archived;
    }
  }
}

class ChecklistModel extends ChangeNotifier {
  List<Checklist> _checklists = [];
  final String _storageKey = 'checklists';
  bool _isLoading = true;

  ChecklistModel() {
    _loadChecklists();
  }

  bool get isLoading => _isLoading;

  List<Checklist> get templates =>
      _checklists.where((c) => c.status == ChecklistStatus.template).toList();

  List<Checklist> get activeChecklists =>
      _checklists.where((c) => c.status == ChecklistStatus.active).toList();

  List<Checklist> get archivedChecklists =>
      _checklists.where((c) => c.status == ChecklistStatus.archived).toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

  Future<void> _loadChecklists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? checklistsJson = prefs.getString(_storageKey);

      if (checklistsJson != null) {
        final List<dynamic> decoded = jsonDecode(checklistsJson);
        _checklists = decoded.map((item) => Checklist.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading checklists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveChecklists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _checklists.map((checklist) => checklist.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving checklists: $e');
    }
  }

  Future<void> addChecklist(Checklist checklist) async {
    _checklists.add(checklist);
    await _saveChecklists();
    notifyListeners();
  }

  Future<void> updateChecklist(Checklist checklist) async {
    final index = _checklists.indexWhere((item) => item.id == checklist.id);
    if (index != -1) {
      checklist.updatedAt = DateTime.now();
      _checklists[index] = checklist;
      await _saveChecklists();
      notifyListeners();
    }
  }

  Future<void> deleteChecklist(String id) async {
    _checklists.removeWhere((checklist) => checklist.id == id);
    await _saveChecklists();
    notifyListeners();
  }

  Future<void> startNewChecklistFromTemplate(
    String templateId,
    String adminName,
    String description,
  ) async {
    final template = _checklists.firstWhere((c) => c.id == templateId);
    final activeChecklist = template.createActiveFromTemplate(
      adminName: adminName,
      description: description,
    );

    await addChecklist(activeChecklist);
  }

  Future<void> completeChecklist(String checklistId) async {
    final index = _checklists.indexWhere((c) => c.id == checklistId);
    if (index != -1 && _checklists[index].canComplete) {
      _checklists[index].complete();
      await _saveChecklists();
      notifyListeners();
    }
  }

  Future<void> toggleItemCheck(Checklist checklist, String itemId) async {
    final item = checklist.items.firstWhere((item) => item.id == itemId);
    item.toggleChecked();
    await updateChecklist(checklist);
  }

  Future<void> reorderItems(
      Checklist checklist, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final List<ChecklistItem> items = List.from(checklist.items);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Update order values
    for (var i = 0; i < items.length; i++) {
      items[i].order = i;
    }

    checklist.items = items;
    await updateChecklist(checklist);
  }

  Future<void> deleteAllActive() async {
    _checklists
        .removeWhere((checklist) => checklist.status == ChecklistStatus.active);
    await _saveChecklists();
    notifyListeners();
  }

  Future<void> refreshChecklists() async {
    notifyListeners();
  }
}
