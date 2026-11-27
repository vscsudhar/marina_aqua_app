import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../models/expense_models.dart';
import '../../../../services/expense_service.dart';
import '../../../../services/file_picker_helper.dart';
import '../../../common/app_colors.dart';

class ExpenseFormDialog extends StatefulWidget {
  final ExpenseService expenseService;
  final List<ExpenseCategoryModel> categories;
  final ExpenseModel? existingExpense;
  final VoidCallback onSaved;

  const ExpenseFormDialog({
    super.key,
    required this.expenseService,
    required this.categories,
    this.existingExpense,
    required this.onSaved,
  });

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paidToController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();

  int? _selectedCategoryId;
  late DateTime _selectedDate;
  String _paymentMode = 'Cash';

  Uint8List? _attachmentBytes;
  String? _attachmentName;
  bool _removeExistingAttachment = false;
  bool _isSaving = false;
  double _uploadProgress = 0.0;
  String? _attachmentError;

  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
  static const int _maxFileBytes = 5 * 1024 * 1024; // 5 MB

  bool get _isEdit => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existingExpense;
    if (e != null) {
      _selectedCategoryId = e.categoryId;
      _amountController.text = e.amount.toStringAsFixed(2);
      _selectedDate = DateTime.tryParse(e.expenseDate) ?? DateTime.now();
      _timeController.text = e.expenseTime ?? '';
      _paymentMode = e.paymentMode;
      _paidToController.text = e.paidTo ?? '';
      _descriptionController.text = e.description ?? '';
    } else {
      _selectedDate = DateTime.now();
      _timeController.text = DateFormat('hh:mm a').format(DateTime.now());
      final active = widget.categories.where((c) => c.isActive).toList();
      if (active.isNotEmpty) {
        _selectedCategoryId = active.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paidToController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickAttachment() async {
    setState(() => _attachmentError = null);
    final file = await pickImageFile(allowedExtensions: _allowedExtensions);
    if (file == null) return;

    final ext =
        file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
    if (!_allowedExtensions.contains(ext)) {
      setState(() => _attachmentError =
          'Invalid file type. Allowed: JPG, JPEG, PNG, WEBP, PDF.');
      return;
    }

    if (file.bytes.isEmpty) {
      setState(() => _attachmentError = 'Unable to read selected file.');
      return;
    }
    if (file.size > _maxFileBytes) {
      setState(
          () => _attachmentError = 'File size exceeds 5 MB maximum limit.');
      return;
    }

    setState(() {
      _attachmentBytes = file.bytes;
      _attachmentName = file.name;
      _removeExistingAttachment = false;
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expense category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final amount = double.parse(_amountController.text.trim());

      if (_isEdit) {
        await widget.expenseService.updateExpense(
          id: widget.existingExpense!.id,
          categoryId: _selectedCategoryId!,
          amount: amount,
          expenseDate: dateStr,
          expenseTime: _timeController.text.trim(),
          paymentMode: _paymentMode,
          paidTo: _paidToController.text.trim(),
          description: _descriptionController.text.trim(),
          removeAttachment: _removeExistingAttachment,
          attachmentBytes: _attachmentBytes,
          attachmentFileName: _attachmentName,
          onSendProgress: (sent, total) {
            if (mounted && total > 0) {
              setState(() => _uploadProgress = sent / total);
            }
          },
        );
      } else {
        await widget.expenseService.createExpense(
          categoryId: _selectedCategoryId!,
          amount: amount,
          expenseDate: dateStr,
          expenseTime: _timeController.text.trim(),
          paymentMode: _paymentMode,
          paidTo: _paidToController.text.trim(),
          description: _descriptionController.text.trim(),
          attachmentBytes: _attachmentBytes,
          attachmentFileName: _attachmentName,
          onSendProgress: (sent, total) {
            if (mounted && total > 0) {
              setState(() => _uploadProgress = sent / total);
            }
          },
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Expense updated successfully'
                : 'Expense added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = widget.categories
        .where((c) => c.isActive || c.id == _selectedCategoryId)
        .toList();
    final hasExisting = _isEdit &&
        widget.existingExpense!.hasAttachment &&
        !_removeExistingAttachment &&
        _attachmentBytes == null;
    final isImageSelected = _attachmentName != null &&
        !_attachmentName!.toLowerCase().endsWith('.pdf');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEdit ? 'Edit Expense' : 'Add Expense',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Category
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Expense Category *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: activeCategories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) =>
                        val == null ? 'Category is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Amount & Payment Mode
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          enabled: !_isSaving,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Amount (₹) *',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) {
                            final parsed = double.tryParse(v?.trim() ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Enter amount > 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _paymentMode,
                          decoration: const InputDecoration(
                            labelText: 'Payment Mode *',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const ['Cash', 'UPI', 'Bank']
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ))
                              .toList(),
                          onChanged: _isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() => _paymentMode = val);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _isSaving ? null : _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Expense Date *',
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixIcon:
                                  Icon(Icons.calendar_today_rounded, size: 18),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _timeController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Expense Time (Optional)',
                            hintText: 'e.g. 10:30 AM',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Paid To
                  TextFormField(
                    controller: _paidToController,
                    enabled: !_isSaving,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Paid To (Optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isSaving,
                    maxLines: 2,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Description / Notes (Optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Attachment Picker
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bill Attachment (Image / PDF, max 5MB)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _isSaving ? null : _pickAttachment,
                              icon: const Icon(Icons.attach_file_rounded,
                                  size: 16),
                              label: Text(
                                (_attachmentBytes != null || hasExisting)
                                    ? 'Replace'
                                    : 'Choose File',
                              ),
                            ),
                          ],
                        ),
                        if (_attachmentError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _attachmentError!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 12),
                            ),
                          ),
                        if (_attachmentBytes != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (isImageSelected)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    _attachmentBytes!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                const Icon(Icons.picture_as_pdf_rounded,
                                    color: AppColors.error, size: 32),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _attachmentName ?? 'Selected file',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.error, size: 18),
                                tooltip: 'Remove Attachment',
                                onPressed: _isSaving
                                    ? null
                                    : () => setState(() {
                                          _attachmentBytes = null;
                                          _attachmentName = null;
                                        }),
                              ),
                            ],
                          ),
                        ] else if (hasExisting) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.insert_drive_file_rounded,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.existingExpense!
                                          .attachmentOriginalName ??
                                      'Existing attachment',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.error, size: 18),
                                tooltip: 'Remove Existing Attachment',
                                onPressed: _isSaving
                                    ? null
                                    : () => setState(
                                        () => _removeExistingAttachment = true),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_isSaving && _attachmentBytes != null) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      color: AppColors.primary,
                    ),
                  ],

                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onPressed: _isSaving ? null : _submit,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isEdit ? 'Update Expense' : 'Save Expense'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
