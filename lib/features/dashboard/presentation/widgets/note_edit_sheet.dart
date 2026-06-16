import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/category_constants.dart';

class NoteEditResult {
  final String title;
  final String? category;
  const NoteEditResult({required this.title, required this.category});
}

/// Shows the name + category sheet. Returns a [NoteEditResult] on save, or null
/// if the user dismisses/cancels.
Future<NoteEditResult?> showNoteEditSheet(
  BuildContext context, {
  String initialTitle = '',
  String? initialCategory,
  List<String> customCategories = const [],
  String saveLabel = 'Save',
}) {
  return showModalBottomSheet<NoteEditResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _NoteEditSheet(
      initialTitle: initialTitle,
      initialCategory: initialCategory,
      customCategories: customCategories,
      saveLabel: saveLabel,
    ),
  );
}

class _NoteEditSheet extends StatefulWidget {
  final String initialTitle;
  final String? initialCategory;
  final List<String> customCategories;
  final String saveLabel;

  const _NoteEditSheet({
    required this.initialTitle,
    required this.initialCategory,
    required this.customCategories,
    required this.saveLabel,
  });

  @override
  State<_NoteEditSheet> createState() => _NoteEditSheetState();
}

class _NoteEditSheetState extends State<_NoteEditSheet> {
  late final TextEditingController _titleController;
  late List<String> _categories;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _categories = mergeCategories(widget.customCategories);
    _selectedCategory = widget.initialCategory;
    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _categories = [..._categories, _selectedCategory!];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category name'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        if (!_categories.contains(name)) _categories = [..._categories, name];
        _selectedCategory = name;
      });
    }
  }

  void _save() {
    Navigator.of(context).pop(
      NoteEditResult(
        title: _titleController.text.trim(),
        category: _selectedCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Note name',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(hintText: 'e.g. Team standup'),
          ),
          const SizedBox(height: 20),
          Text(
            'Category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in _categories)
                ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (sel) {
                    setState(() => _selectedCategory = sel ? cat : null);
                  },
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                onPressed: _addCustomCategory,
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(text: widget.saveLabel, onPressed: _save),
          const SizedBox(height: 8),
          AppButton(
            text: 'Cancel',
            isOutlined: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
