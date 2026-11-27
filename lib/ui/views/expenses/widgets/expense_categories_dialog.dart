import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/expense_models.dart';
import '../../../../services/expense_service.dart';
import '../../../common/app_colors.dart';

class ExpenseCategoriesDialog extends StatefulWidget {
  final ExpenseService expenseService;
  final List<ExpenseCategoryModel> initialCategories;
  final VoidCallback onChanged;

  const ExpenseCategoriesDialog({
    super.key,
    required this.expenseService,
    required this.initialCategories,
    required this.onChanged,
  });

  @override
  State<ExpenseCategoriesDialog> createState() =>
      _ExpenseCategoriesDialogState();
}

class _ExpenseCategoriesDialogState extends State<ExpenseCategoriesDialog> {
  late List<ExpenseCategoryModel> _categories;
  final _nameController = TextEditingController();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.initialCategories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final fresh =
        await widget.expenseService.getCategories(includeInactive: true);
    if (mounted) {
      setState(() => _categories = fresh);
      widget.onChanged();
    }
  }

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      await widget.expenseService.createCategory(name: name);
      _nameController.clear();
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _toggleStatus(ExpenseCategoryModel cat) async {
    if (_isBusy || cat.isDefault) return;
    setState(() => _isBusy = true);
    try {
      await widget.expenseService.updateCategory(
        cat.id,
        status: cat.isActive ? 'inactive' : 'active',
      );
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _renameCategory(ExpenseCategoryModel cat) async {
    final controller = TextEditingController(text: cat.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || newName == cat.name) return;

    setState(() => _isBusy = true);
    try {
      await widget.expenseService.updateCategory(cat.id, name: newName);
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteCategory(ExpenseCategoryModel cat) async {
    if (_isBusy || cat.isDefault) return;
    setState(() => _isBusy = true);
    try {
      await widget.expenseService.deleteCategory(cat.id);
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expense Categories',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      enabled: !_isBusy,
                      decoration: const InputDecoration(
                        labelText: 'New Custom Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onPressed: _isBusy ? null : _addCategory,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        cat.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: cat.isActive
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                      subtitle: Text(
                        cat.isDefault
                            ? 'Global Default'
                            : (cat.isActive
                                ? 'Custom • Active'
                                : 'Custom • Disabled'),
                        style: GoogleFonts.inter(fontSize: 11),
                      ),
                      trailing: cat.isDefault
                          ? const Chip(
                              label: Text('Default',
                                  style: TextStyle(fontSize: 10)),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Edit',
                                  onPressed: _isBusy
                                      ? null
                                      : () => _renameCategory(cat),
                                ),
                                Switch(
                                  value: cat.isActive,
                                  onChanged: _isBusy
                                      ? null
                                      : (_) => _toggleStatus(cat),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 18, color: AppColors.error),
                                  tooltip: 'Delete',
                                  onPressed: _isBusy
                                      ? null
                                      : () => _deleteCategory(cat),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
