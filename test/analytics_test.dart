import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:propay/features/transaction/domain/transaction_model.dart';
import 'package:propay/features/wallet/presentation/wallet_provider.dart';

void main() {
  test('businessAnalyticsProvider aggregates data from multiple platforms correctly', () {
    final container = ProviderContainer(
      overrides: [
        analyticsTransactionsProvider.overrideWith((ref) => AsyncValue.data([
          TransactionModel(
            id: '1',
            senderId: 'user1',
            receiverId: 'merchant',
            amount: 100.0,
            timestamp: DateTime.now(),
            type: TransactionType.payment,
            status: TransactionStatus.completed,
            platform: 'Stripe',
            isRevenue: true,
          ),
          TransactionModel(
            id: '2',
            senderId: 'user2',
            receiverId: 'merchant',
            amount: 50.0,
            timestamp: DateTime.now(),
            type: TransactionType.payment,
            status: TransactionStatus.completed,
            platform: 'Chapa',
            isRevenue: true,
          ),
        ])),
      ],
    );

    final analytics = container.read(businessAnalyticsProvider).value!;
    
    expect(analytics['totalNet'], 150.0);
    expect(analytics['revenueByPlatform']['ProShop'], 150.0); // Stripe/Chapa mapped to ProShop in provider
    expect(analytics['activeTerminals'], 1);
  });
}
