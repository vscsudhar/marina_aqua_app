import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

class CancelInvoiceDialog extends StatefulWidget {
  final InvoiceModel invoice;
  final Future<void> Function(String reason) onConfirm;

  const CancelInvoiceDialog({
    super.key,
    required this.invoice,
    required this.onConfirm,
  });

  @override
  State<CancelInvoiceDialog> createState() => _CancelInvoiceDialogState();
}

class _CancelInvoiceDialogState extends State<CancelInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  bool _isCancelling = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCancelling = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm(_reasonController.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: kcErrorColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel Issued Invoice',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Invoice: ${widget.invoice.invoiceNo}',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kcErrorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kcErrorColor),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(color: kcErrorColor, fontSize: 12),
                ),
              ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GST Compliance Warning: Once finalized, an invoice cannot be deleted. Cancelling will reverse any ledger debits and mark this invoice as void in reports.',
                        style: GoogleFonts.inter(fontSize: 13, color: kcTextSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Mandatory Cancellation Reason *',
                          hintText: 'e.g. Order cancelled by customer, duplicate entry, incorrect tax rate',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Cancellation reason is required' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: kcVeryLightGrey,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: kcBorderColor)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _isCancelling ? null : () => Navigator.of(context).pop(),
                    child: Text('Keep Invoice', style: GoogleFonts.inter(color: kcTextSecondary)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isCancelling ? null : _handleCancel,
                    icon: _isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel, size: 18, color: Colors.white),
                    label: Text(
                      _isCancelling ? 'Cancelling...' : 'Confirm Cancellation',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: kcErrorColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
