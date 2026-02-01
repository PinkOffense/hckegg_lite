import 'package:test/test.dart';
import 'package:hckegg_api/features/sales/domain/entities/sale.dart';

void main() {
  group('Sale', () {
    final testSale = Sale(
      id: 'sale-id',
      userId: 'user-123',
      date: '2024-01-15',
      quantitySold: 24,
      pricePerEgg: 0.30,
      pricePerDozen: 3.00,
      customerName: 'John Doe',
      customerEmail: 'john@example.com',
      customerPhone: '+351912345678',
      notes: 'Regular customer',
      paymentStatus: PaymentStatus.pending,
      paymentDate: null,
      isReservation: false,
      reservationNotes: null,
      isLost: false,
      createdAt: DateTime(2024, 1, 15),
    );

    group('computed properties', () {
      test('totalAmount should calculate correctly', () {
        // 24 eggs * 0.30 = 7.20
        expect(testSale.totalAmount, 7.20);
      });

      test('dozens should calculate correctly', () {
        // 24 / 12 = 2 dozens
        expect(testSale.dozens, 2);
      });

      test('individualEggs should calculate correctly', () {
        // 24 % 12 = 0 individual eggs
        expect(testSale.individualEggs, 0);
      });

      test('should handle non-dozen quantities', () {
        final sale = Sale(
          id: 'id',
          userId: 'user',
          date: '2024-01-15',
          quantitySold: 17,
          pricePerEgg: 0.25,
          pricePerDozen: 2.50,
          paymentStatus: PaymentStatus.paid,
          isReservation: false,
          isLost: false,
          createdAt: DateTime.now(),
        );

        expect(sale.dozens, 1);
        expect(sale.individualEggs, 5);
        expect(sale.totalAmount, 4.25); // 17 * 0.25
      });
    });

    group('PaymentStatus', () {
      test('fromString should parse valid status', () {
        expect(PaymentStatus.fromString('paid'), PaymentStatus.paid);
        expect(PaymentStatus.fromString('pending'), PaymentStatus.pending);
        expect(PaymentStatus.fromString('overdue'), PaymentStatus.overdue);
        expect(PaymentStatus.fromString('advance'), PaymentStatus.advance);
      });

      test('fromString should default to pending for invalid status', () {
        expect(PaymentStatus.fromString('invalid'), PaymentStatus.pending);
        expect(PaymentStatus.fromString(''), PaymentStatus.pending);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        final json = testSale.toJson();

        expect(json['id'], 'sale-id');
        expect(json['user_id'], 'user-123');
        expect(json['quantity_sold'], 24);
        expect(json['price_per_egg'], 0.30);
        expect(json['payment_status'], 'pending');
        expect(json['total_amount'], 7.20);
        expect(json['customer_name'], 'John Doe');
      });
    });

    group('fromJson', () {
      test('should deserialize correctly', () {
        final json = {
          'id': 'sale-id',
          'user_id': 'user-123',
          'date': '2024-01-15',
          'quantity_sold': 24,
          'price_per_egg': 0.30,
          'price_per_dozen': 3.00,
          'customer_name': 'John Doe',
          'payment_status': 'paid',
          'is_reservation': false,
          'is_lost': false,
          'created_at': '2024-01-15T10:00:00.000Z',
        };

        final sale = Sale.fromJson(json);

        expect(sale.id, 'sale-id');
        expect(sale.quantitySold, 24);
        expect(sale.paymentStatus, PaymentStatus.paid);
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'sale-id',
          'user_id': 'user-123',
          'date': '2024-01-15',
          'quantity_sold': 10,
          'price_per_egg': 0.25,
          'price_per_dozen': 2.50,
          'created_at': '2024-01-15T10:00:00.000Z',
        };

        final sale = Sale.fromJson(json);

        expect(sale.customerName, isNull);
        expect(sale.paymentStatus, PaymentStatus.pending);
        expect(sale.isReservation, false);
        expect(sale.isLost, false);
      });
    });

    group('equality', () {
      test('sales with same props should be equal', () {
        final sale1 = Sale(
          id: 'id',
          userId: 'user',
          date: '2024-01-15',
          quantitySold: 12,
          pricePerEgg: 0.30,
          pricePerDozen: 3.00,
          paymentStatus: PaymentStatus.paid,
          isReservation: false,
          isLost: false,
          createdAt: DateTime(2024, 1, 15),
        );

        final sale2 = Sale(
          id: 'id',
          userId: 'user',
          date: '2024-01-15',
          quantitySold: 12,
          pricePerEgg: 0.30,
          pricePerDozen: 3.00,
          paymentStatus: PaymentStatus.paid,
          isReservation: false,
          isLost: false,
          createdAt: DateTime(2024, 1, 15),
        );

        expect(sale1, equals(sale2));
      });
    });
  });

  group('SaleStatistics', () {
    test('should serialize to JSON correctly', () {
      const stats = SaleStatistics(
        totalSales: 50,
        totalQuantity: 600,
        totalRevenue: 180.00,
        totalPending: 30.00,
        totalLost: 10.00,
        averagePrice: 0.30,
      );

      final json = stats.toJson();

      expect(json['total_sales'], 50);
      expect(json['total_quantity'], 600);
      expect(json['total_revenue'], 180.00);
      expect(json['total_pending'], 30.00);
      expect(json['total_lost'], 10.00);
      expect(json['average_price'], 0.30);
    });
  });
}
