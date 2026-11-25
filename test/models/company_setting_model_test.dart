import 'package:flutter_test/flutter_test.dart';
import 'package:marina_aqua/models/billing_models.dart';

void main() {
  group('CompanySettingModel Contact Number Tests', () {
    test('Default model has empty phone and hasContactNumber is false', () {
      const model = CompanySettingModel(id: 1);
      expect(model.phone, '');
      expect(model.hasContactNumber, false);
      expect(model.effectiveContactNumber, '');
    });

    test(
        'When phone is set, hasContactNumber is true and effectiveContactNumber returns it',
        () {
      const model = CompanySettingModel(
        id: 1,
        phone: '+91 98765 43210',
      );
      expect(model.hasContactNumber, true);
      expect(model.effectiveContactNumber, '+91 98765 43210');
    });

    test('When companyContactNumber is explicitly provided, it takes priority',
        () {
      const model = CompanySettingModel(
        id: 1,
        phone: '+91 98765 00000',
        companyContactNumber: '+91 98765 11111',
      );
      expect(model.hasContactNumber, true);
      expect(model.effectiveContactNumber, '+91 98765 11111');
    });

    test('When phone is null-like or empty string, hasContactNumber is false',
        () {
      const model1 = CompanySettingModel(id: 1, phone: '   ');
      expect(model1.hasContactNumber, false);

      const model2 = CompanySettingModel(id: 1, phone: 'null');
      expect(model2.hasContactNumber, false);
    });

    test('fromJson parses company_contact_number and phone interchangeably',
        () {
      final json1 = {
        'id': 10,
        'company_name': 'Aqua Test',
        'phone': '+91 94441 23456',
        'optional_phone': '+91 99999 88888',
      };
      final model1 = CompanySettingModel.fromJson(json1);
      expect(model1.phone, '+91 94441 23456');
      expect(model1.optionalPhone, '+91 99999 88888');
      expect(model1.hasContactNumber, true);
      expect(model1.effectiveContactNumber, '+91 99999 88888');

      final json2 = {
        'id': 11,
        'company_name': 'Aqua Test 2',
        'phone': '+91 77777 66666',
      };
      final model2 = CompanySettingModel.fromJson(json2);
      expect(model2.phone, '+91 77777 66666');
      expect(model2.optionalPhone, '');
      expect(model2.hasContactNumber, true);
      expect(model2.effectiveContactNumber, '+91 77777 66666');
    });

    test('toJson outputs both phone and company_contact_number keys', () {
      const model = CompanySettingModel(
        id: 20,
        phone: '+91 91234 56789',
      );
      final json = model.toJson();
      expect(json['phone'], '+91 91234 56789');
      expect(json['company_contact_number'], '+91 91234 56789');
      expect(json['show_phone_on_invoice'], true);
    });

    test(
        'When showPhoneOnInvoice is false, hasContactNumber is false even if phone exists',
        () {
      const model = CompanySettingModel(
        id: 1,
        phone: '+91 98765 43210',
        showPhoneOnInvoice: false,
      );
      expect(model.hasContactNumber, false);
      expect(model.effectiveContactNumber, '+91 98765 43210');
    });

    test('InvoiceModel parses show_contact_number correctly', () {
      final invJson1 = {
        'id': 1,
        'invoice_no': 'INV-001',
        'invoice_date': '2026-11-20',
        'customer_name': 'Test Dealer',
        'grand_total': 500.0,
        'show_contact_number': false,
      };
      final inv1 = InvoiceModel.fromJson(invJson1);
      expect(inv1.showContactNumber, false);

      final invJson2 = {
        'id': 2,
        'invoice_no': 'INV-002',
        'invoice_date': '2026-11-20',
        'customer_name': 'Test Dealer 2',
        'grand_total': 300.0,
      };
      final inv2 = InvoiceModel.fromJson(invJson2);
      expect(inv2.showContactNumber, true);
    });
  });
}
