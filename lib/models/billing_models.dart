class CompanySettingModel {
  final int id;
  final String companyName;
  final String tagline;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String stateName;
  final String stateCode;
  final String gstin;
  final String pan;
  final String? fssaiNo;
  final String bankName;
  final String bankBranch;
  final String accountNumber;
  final String ifscCode;
  final String upiId;
  final String currencySymbol;
  final String currencyCode;
  final double defaultTaxRate;
  final String? logoPath;
  final String? logoUrl;
  final String invoicePrefix;
  final int invoiceNumberPadding;
  final int nextInvoiceNumber;
  final String invoiceFooterNotes;

  const CompanySettingModel({
    required this.id,
    this.companyName = 'Marina Aqua Pure Water Co.',
    this.tagline = 'Pure & Mineral Rich Packaged Drinking Water',
    this.phone = '+91 94441 23456',
    this.email = 'billing@marinaaqua.com',
    this.website = 'www.marinaaqua.com',
    this.address = 'Plot No. 14, OMR IT Highway, Thoraipakkam, Chennai - 600097',
    this.stateName = 'Tamil Nadu',
    this.stateCode = '33',
    this.gstin = '33AABCM1234F1Z9',
    this.pan = 'AABCM1234F',
    this.fssaiNo,
    this.bankName = 'State Bank of India',
    this.bankBranch = 'Thoraipakkam, Chennai',
    this.accountNumber = '38992010045',
    this.ifscCode = 'SBIN0004567',
    this.upiId = 'marinaaqua@sbi',
    this.currencySymbol = '₹',
    this.currencyCode = 'INR',
    this.defaultTaxRate = 18.0,
    this.logoPath,
    this.logoUrl,
    this.invoicePrefix = '',
    this.invoiceNumberPadding = 4,
    this.nextInvoiceNumber = 1,
    this.invoiceFooterNotes = 'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
  });

  factory CompanySettingModel.fromJson(Map<String, dynamic> json) {
    return CompanySettingModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 1,
      companyName: json['company_name'] as String? ?? 'Marina Aqua Pure Water Co.',
      tagline: json['tagline'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      website: json['website'] as String? ?? '',
      address: json['address'] as String? ?? '',
      stateName: json['state_name'] as String? ?? 'Tamil Nadu',
      stateCode: json['state_code'] as String? ?? '33',
      gstin: json['gstin'] as String? ?? '',
      pan: json['pan'] as String? ?? '',
      fssaiNo: json['fssai_no'] as String?,
      bankName: json['bank_name'] as String? ?? '',
      bankBranch: json['bank_branch'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      ifscCode: json['ifsc_code'] as String? ?? '',
      upiId: json['upi_id'] as String? ?? '',
      currencySymbol: json['currency_symbol'] as String? ?? '₹',
      currencyCode: json['currency_code'] as String? ?? 'INR',
      defaultTaxRate: (json['default_tax_rate'] != null)
          ? double.tryParse(json['default_tax_rate'].toString()) ?? 18.0
          : 18.0,
      logoPath: json['logo_path'] as String?,
      logoUrl: json['logo_url'] as String?,
      invoicePrefix: json['invoice_prefix'] as String? ?? '',
      invoiceNumberPadding: json['invoice_number_padding'] is int
          ? json['invoice_number_padding']
          : int.tryParse(json['invoice_number_padding']?.toString() ?? '') ?? 4,
      nextInvoiceNumber: json['next_invoice_number'] is int
          ? json['next_invoice_number']
          : int.tryParse(json['next_invoice_number']?.toString() ?? '') ?? 1,
      invoiceFooterNotes: json['invoice_footer_notes'] as String? ?? '',
    );
  }

  CompanySettingModel copyWith({
    int? id,
    String? companyName,
    String? tagline,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? stateName,
    String? stateCode,
    String? gstin,
    String? pan,
    String? fssaiNo,
    String? bankName,
    String? bankBranch,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    String? currencySymbol,
    String? currencyCode,
    double? defaultTaxRate,
    String? logoPath,
    String? logoUrl,
    String? invoicePrefix,
    int? invoiceNumberPadding,
    int? nextInvoiceNumber,
    String? invoiceFooterNotes,
  }) {
    return CompanySettingModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      tagline: tagline ?? this.tagline,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      stateName: stateName ?? this.stateName,
      stateCode: stateCode ?? this.stateCode,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      fssaiNo: fssaiNo ?? this.fssaiNo,
      bankName: bankName ?? this.bankName,
      bankBranch: bankBranch ?? this.bankBranch,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      logoPath: logoPath ?? this.logoPath,
      logoUrl: logoUrl ?? this.logoUrl,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      invoiceNumberPadding: invoiceNumberPadding ?? this.invoiceNumberPadding,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      invoiceFooterNotes: invoiceFooterNotes ?? this.invoiceFooterNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_name': companyName,
        'tagline': tagline,
        'phone': phone,
        'email': email,
        'website': website,
        'address': address,
        'state_name': stateName,
        'state_code': stateCode,
        'gstin': gstin,
        'pan': pan,
        'fssai_no': fssaiNo,
        'bank_name': bankName,
        'bank_branch': bankBranch,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        'upi_id': upiId,
        'currency_symbol': currencySymbol,
        'currency_code': currencyCode,
        'default_tax_rate': defaultTaxRate,
        'logo_path': logoPath,
        'logo_url': logoUrl,
        'invoice_prefix': invoicePrefix,
        'invoice_number_padding': invoiceNumberPadding,
        'next_invoice_number': nextInvoiceNumber,
        'invoice_footer_notes': invoiceFooterNotes,
      };
}

class InvoiceItemModel {
  final int id;
  final int invoiceId;
  final int? productId;
  final String? productName;
  final String? productSku;
  final String itemDescription;
  final String hsnSac;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discountAmount;
  final double taxableAmount;
  final double taxRate;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double igstRate;
  final double igstAmount;
  final double lineTotal;
  final String? notes;

  const InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    this.productId,
    this.productName,
    this.productSku,
    required this.itemDescription,
    this.hsnSac = '2201',
    required this.quantity,
    this.unit = 'Unit',
    required this.unitPrice,
    this.discountAmount = 0.0,
    required this.taxableAmount,
    this.taxRate = 0.0,
    this.cgstRate = 0.0,
    this.cgstAmount = 0.0,
    this.sgstRate = 0.0,
    this.sgstAmount = 0.0,
    this.igstRate = 0.0,
    this.igstAmount = 0.0,
    required this.lineTotal,
    this.notes,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      invoiceId: json['invoice_id'] is int ? json['invoice_id'] : int.tryParse(json['invoice_id'].toString()) ?? 0,
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id']?.toString() ?? ''),
      productName: json['product_name'] as String?,
      productSku: json['product_sku'] as String?,
      itemDescription: json['item_description'] as String? ?? '',
      hsnSac: json['hsn_sac'] as String? ?? '2201',
      quantity: (json['quantity'] != null) ? double.tryParse(json['quantity'].toString()) ?? 0.0 : 0.0,
      unit: json['unit'] as String? ?? 'Unit',
      unitPrice: (json['unit_price'] != null) ? double.tryParse(json['unit_price'].toString()) ?? 0.0 : 0.0,
      discountAmount: (json['discount_amount'] != null) ? double.tryParse(json['discount_amount'].toString()) ?? 0.0 : 0.0,
      taxableAmount: (json['taxable_amount'] != null) ? double.tryParse(json['taxable_amount'].toString()) ?? 0.0 : 0.0,
      taxRate: (json['tax_rate'] != null) ? double.tryParse(json['tax_rate'].toString()) ?? 0.0 : 0.0,
      cgstRate: (json['cgst_rate'] != null) ? double.tryParse(json['cgst_rate'].toString()) ?? 0.0 : 0.0,
      cgstAmount: (json['cgst_amount'] != null) ? double.tryParse(json['cgst_amount'].toString()) ?? 0.0 : 0.0,
      sgstRate: (json['sgst_rate'] != null) ? double.tryParse(json['sgst_rate'].toString()) ?? 0.0 : 0.0,
      sgstAmount: (json['sgst_amount'] != null) ? double.tryParse(json['sgst_amount'].toString()) ?? 0.0 : 0.0,
      igstRate: (json['igst_rate'] != null) ? double.tryParse(json['igst_rate'].toString()) ?? 0.0 : 0.0,
      igstAmount: (json['igst_amount'] != null) ? double.tryParse(json['igst_amount'].toString()) ?? 0.0 : 0.0,
      lineTotal: (json['line_total'] != null) ? double.tryParse(json['line_total'].toString()) ?? 0.0 : 0.0,
      notes: json['notes'] as String?,
    );
  }
}

class InvoicePaymentModel {
  final int id;
  final int invoiceId;
  final String paymentNo;
  final String paymentDate;
  final double amount;
  final String paymentMethod;
  final String? referenceNo;
  final String? notes;
  final String? createdBy;
  final String? createdAt;

  const InvoicePaymentModel({
    required this.id,
    required this.invoiceId,
    required this.paymentNo,
    required this.paymentDate,
    required this.amount,
    this.paymentMethod = 'cash',
    this.referenceNo,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory InvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    return InvoicePaymentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      invoiceId: json['invoice_id'] is int ? json['invoice_id'] : int.tryParse(json['invoice_id'].toString()) ?? 0,
      paymentNo: json['payment_no'] as String? ?? '',
      paymentDate: json['payment_date'] as String? ?? '',
      amount: (json['amount'] != null) ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      referenceNo: json['reference_no'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class CreditNoteModel {
  final int id;
  final String creditNoteNo;
  final String creditNoteDate;
  final int invoiceId;
  final int? dealerId;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String reason;
  final String? notes;
  final String? createdBy;
  final String? createdAt;

  const CreditNoteModel({
    required this.id,
    required this.creditNoteNo,
    required this.creditNoteDate,
    required this.invoiceId,
    this.dealerId,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.reason,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory CreditNoteModel.fromJson(Map<String, dynamic> json) {
    return CreditNoteModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      creditNoteNo: json['credit_note_no'] as String? ?? '',
      creditNoteDate: json['credit_note_date'] as String? ?? '',
      invoiceId: json['invoice_id'] is int ? json['invoice_id'] : int.tryParse(json['invoice_id'].toString()) ?? 0,
      dealerId: json['dealer_id'] is int ? json['dealer_id'] : int.tryParse(json['dealer_id']?.toString() ?? ''),
      subtotal: (json['subtotal'] != null) ? double.tryParse(json['subtotal'].toString()) ?? 0.0 : 0.0,
      taxAmount: (json['tax_amount'] != null) ? double.tryParse(json['tax_amount'].toString()) ?? 0.0 : 0.0,
      totalAmount: (json['total_amount'] != null) ? double.tryParse(json['total_amount'].toString()) ?? 0.0 : 0.0,
      reason: json['reason'] as String? ?? '',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class InvoiceModel {
  final int id;
  final String invoiceNo;
  final String invoiceDate;
  final String? dueDate;
  final int? dealerId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerAddress;
  final String? customerGstin;
  final String placeOfSupply;
  final bool isInterstate;
  final int? dealerSupplyId;
  final String? dealerSupplyNo;
  final double subtotal;
  final double discountTotal;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double taxTotal;
  final double roundOff;
  final double grandTotal;
  final double paidAmount;
  final double balanceDue;
  final String status;
  final String paymentStatus;
  final String? cancellationReason;
  final String? cancelledAt;
  final String? cancelledBy;
  final String? finalizedAt;
  final String? finalizedBy;
  final String? notes;
  final String? terms;
  final int itemsCount;
  final List<InvoiceItemModel> items;
  final List<InvoicePaymentModel> payments;
  final List<CreditNoteModel> creditNotes;
  final Map<String, dynamic>? dealer;
  final String? createdBy;
  final String? createdAt;

  const InvoiceModel({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    this.dueDate,
    this.dealerId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    this.customerGstin,
    this.placeOfSupply = '33-Tamil Nadu',
    this.isInterstate = false,
    this.dealerSupplyId,
    this.dealerSupplyNo,
    this.subtotal = 0.0,
    this.discountTotal = 0.0,
    this.taxableAmount = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.taxTotal = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    this.paidAmount = 0.0,
    this.balanceDue = 0.0,
    this.status = 'draft',
    this.paymentStatus = 'unpaid',
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledBy,
    this.finalizedAt,
    this.finalizedBy,
    this.notes,
    this.terms,
    this.itemsCount = 0,
    this.items = const [],
    this.payments = const [],
    this.creditNotes = const [],
    this.dealer,
    this.createdBy,
    this.createdAt,
  });

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isFinalized => status.toLowerCase() == 'finalized';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      invoiceNo: json['invoice_no'] as String? ?? '',
      invoiceDate: json['invoice_date'] as String? ?? '',
      dueDate: json['due_date'] as String?,
      dealerId: json['dealer_id'] is int ? json['dealer_id'] : int.tryParse(json['dealer_id']?.toString() ?? ''),
      customerName: json['customer_name'] as String? ?? 'Valued Customer',
      customerPhone: json['customer_phone'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerAddress: json['customer_address'] as String?,
      customerGstin: json['customer_gstin'] as String?,
      placeOfSupply: json['place_of_supply'] as String? ?? '33-Tamil Nadu',
      isInterstate: json['is_interstate'] == true || json['is_interstate'] == 1,
      dealerSupplyId: json['dealer_supply_id'] is int ? json['dealer_supply_id'] : int.tryParse(json['dealer_supply_id']?.toString() ?? ''),
      dealerSupplyNo: json['dealer_supply_no'] as String?,
      subtotal: (json['subtotal'] != null) ? double.tryParse(json['subtotal'].toString()) ?? 0.0 : 0.0,
      discountTotal: (json['discount_total'] != null) ? double.tryParse(json['discount_total'].toString()) ?? 0.0 : 0.0,
      taxableAmount: (json['taxable_amount'] != null) ? double.tryParse(json['taxable_amount'].toString()) ?? 0.0 : 0.0,
      cgstAmount: (json['cgst_amount'] != null) ? double.tryParse(json['cgst_amount'].toString()) ?? 0.0 : 0.0,
      sgstAmount: (json['sgst_amount'] != null) ? double.tryParse(json['sgst_amount'].toString()) ?? 0.0 : 0.0,
      igstAmount: (json['igst_amount'] != null) ? double.tryParse(json['igst_amount'].toString()) ?? 0.0 : 0.0,
      taxTotal: (json['tax_total'] != null) ? double.tryParse(json['tax_total'].toString()) ?? 0.0 : 0.0,
      roundOff: (json['round_off'] != null) ? double.tryParse(json['round_off'].toString()) ?? 0.0 : 0.0,
      grandTotal: (json['grand_total'] != null) ? double.tryParse(json['grand_total'].toString()) ?? 0.0 : 0.0,
      paidAmount: (json['paid_amount'] != null) ? double.tryParse(json['paid_amount'].toString()) ?? 0.0 : 0.0,
      balanceDue: (json['balance_due'] != null) ? double.tryParse(json['balance_due'].toString()) ?? 0.0 : 0.0,
      status: json['status'] as String? ?? 'draft',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      finalizedAt: json['finalized_at'] as String?,
      finalizedBy: json['finalized_by'] as String?,
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      itemsCount: json['items_count'] is int ? json['items_count'] : 0,
      items: (json['items'] as List?)
              ?.map((item) => InvoiceItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      payments: (json['payments'] as List?)
              ?.map((p) => InvoicePaymentModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      creditNotes: (json['credit_notes'] as List?)
              ?.map((cn) => CreditNoteModel.fromJson(cn as Map<String, dynamic>))
              .toList() ??
          const [],
      dealer: json['dealer'] as Map<String, dynamic>?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class GstSupplyCode {
  final String code;
  final String stateName;
  final String displayName;
  final String placeOfSupply;

  const GstSupplyCode({
    required this.code,
    required this.stateName,
    required this.displayName,
    required this.placeOfSupply,
  });
}

const List<GstSupplyCode> kGstSupplyCodes = [
  GstSupplyCode(
    code: '33',
    stateName: 'Tamil Nadu',
    displayName: '33 - Tamil Nadu (Coimbatore)',
    placeOfSupply: '33-Tamil Nadu (Coimbatore)',
  ),
  GstSupplyCode(
    code: '33',
    stateName: 'Tamil Nadu',
    displayName: '33 - Tamil Nadu',
    placeOfSupply: '33-Tamil Nadu',
  ),
  GstSupplyCode(
    code: '33',
    stateName: 'Tamil Nadu',
    displayName: '33 - Tamil Nadu (Chennai)',
    placeOfSupply: '33-Tamil Nadu (Chennai)',
  ),
  GstSupplyCode(
    code: '33',
    stateName: 'Tamil Nadu',
    displayName: '33 - Tamil Nadu (Madurai)',
    placeOfSupply: '33-Tamil Nadu (Madurai)',
  ),
  GstSupplyCode(
    code: '33',
    stateName: 'Tamil Nadu',
    displayName: '33 - Tamil Nadu (Tirupur)',
    placeOfSupply: '33-Tamil Nadu (Tirupur)',
  ),
  GstSupplyCode(
    code: '33',
    stateName: 'Tamil Nadu',
    displayName: '33 - Tamil Nadu (Salem)',
    placeOfSupply: '33-Tamil Nadu (Salem)',
  ),
  GstSupplyCode(
    code: '32',
    stateName: 'Kerala',
    displayName: '32 - Kerala',
    placeOfSupply: '32-Kerala',
  ),
  GstSupplyCode(
    code: '29',
    stateName: 'Karnataka',
    displayName: '29 - Karnataka',
    placeOfSupply: '29-Karnataka',
  ),
  GstSupplyCode(
    code: '37',
    stateName: 'Andhra Pradesh',
    displayName: '37 - Andhra Pradesh',
    placeOfSupply: '37-Andhra Pradesh',
  ),
  GstSupplyCode(
    code: '36',
    stateName: 'Telangana',
    displayName: '36 - Telangana',
    placeOfSupply: '36-Telangana',
  ),
  GstSupplyCode(
    code: '34',
    stateName: 'Puducherry',
    displayName: '34 - Puducherry',
    placeOfSupply: '34-Puducherry',
  ),
  GstSupplyCode(
    code: '27',
    stateName: 'Maharashtra',
    displayName: '27 - Maharashtra',
    placeOfSupply: '27-Maharashtra',
  ),
  GstSupplyCode(
    code: '07',
    stateName: 'Delhi',
    displayName: '07 - Delhi',
    placeOfSupply: '07-Delhi',
  ),
];
