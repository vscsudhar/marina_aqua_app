import 'package:flutter_test/flutter_test.dart';
import 'package:marina_aqua/models/user_model.dart';
import 'package:marina_aqua/services/subscription_guard.dart';

void main() {
  group('UserModel Subscription Expiry & Days Remaining Calculation', () {
    test('Active user with 30 days remaining', () {
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 30));
      final dateStr =
          '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';

      final user = UserModel(
        id: 1,
        name: 'Active User',
        email: 'user@example.com',
        role: 'admin',
        isActive: true,
        planExpiresAt: dateStr,
      );

      expect(user.isPlanExpired, isFalse);
      expect(user.isNearExpiry, isFalse);
      expect(user.planDaysRemaining, greaterThanOrEqualTo(29));
    });

    test('Near expiry user with 2 days left', () {
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 2));
      final dateStr =
          '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';

      final user = UserModel(
        id: 2,
        name: 'Near Expiry User',
        email: 'user@example.com',
        role: 'admin',
        isActive: true,
        planExpiresAt: dateStr,
      );

      expect(user.isPlanExpired, isFalse);
      expect(user.isNearExpiry, isTrue);
      expect(user.planDaysRemaining, equals(2));
      expect(user.remainingDaysText, equals('2 days left'));
    });

    test('Near expiry user with 1 day left', () {
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 1));
      final dateStr =
          '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';

      final user = UserModel(
        id: 3,
        name: 'Near Expiry User',
        email: 'user@example.com',
        role: 'admin',
        isActive: true,
        planExpiresAt: dateStr,
      );

      expect(user.isPlanExpired, isFalse);
      expect(user.isNearExpiry, isTrue);
      expect(user.planDaysRemaining, equals(1));
      expect(user.remainingDaysText, equals('1 day left'));
    });

    test('Near expiry user with 0 days left (expires today)', () {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final user = UserModel(
        id: 4,
        name: 'Expires Today User',
        email: 'user@example.com',
        role: 'admin',
        isActive: true,
        planExpiresAt: dateStr,
      );

      expect(user.isPlanExpired, isFalse);
      expect(user.isNearExpiry, isTrue);
      expect(user.planDaysRemaining, equals(0));
      expect(user.remainingDaysText, equals('Expires today'));
    });

    test('Expired user (expired yesterday)', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final user = UserModel(
        id: 5,
        name: 'Expired User',
        email: 'user@example.com',
        role: 'admin',
        isActive: true,
        planExpiresAt: dateStr,
      );

      expect(user.isPlanExpired, isTrue);
      expect(user.isNearExpiry, isFalse);
    });

    test('Super admin is never expired', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 10));
      final dateStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final user = UserModel(
        id: 6,
        name: 'Super Admin',
        email: 'super@example.com',
        role: 'super_admin',
        isActive: true,
        planExpiresAt: dateStr,
      );

      expect(user.isPlanExpired, isFalse);
      expect(user.isNearExpiry, isFalse);
    });

    test('Backend API overrides are respected if provided', () {
      final user = UserModel(
        id: 7,
        name: 'API Synced User',
        email: 'user@example.com',
        role: 'admin',
        isActive: true,
        isPlanExpiredFromApi: true,
        planDaysRemainingFromApi: -1,
        isNearExpiryFromApi: false,
      );

      expect(user.isPlanExpired, isTrue);
      expect(user.isNearExpiry, isFalse);
      expect(user.planDaysRemaining, equals(-1));
    });
  });
}
