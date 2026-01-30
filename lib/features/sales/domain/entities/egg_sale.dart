import 'package:equatable/equatable.dart';

/// Payment status for sales
enum PaymentStatus {
  paid,
  pending,
  overdue,
  advance;

  String displayName(String locale) {
    switch (this) {
      case PaymentStatus.paid:
        return locale == 'pt' ? 'Pago' : 'Paid';
      case PaymentStatus.pending:
        return locale == 'pt' ? 'Pendente' : 'Pending';
      case PaymentStatus.overdue:
        return locale == 'pt' ? 'Atrasado' : 'Overdue';
      case PaymentStatus.advance:
        return locale == 'pt' ? 'Adiantado' : 'Advance';
    }
  }

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Domain entity representing an egg sale
class EggSale extends Equatable {
  final String id;
  final String date;
  final int quantitySold;
  final double pricePerEgg;
  final double pricePerDozen;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? notes;
  final PaymentStatus paymentStatus;
  final String? paymentDate;
  final bool isReservation;
  final String? reservationNotes;
  final bool isLost;
  final DateTime createdAt;

  const EggSale({
    required this.id,
    required this.date,
    required this.quantitySold,
    required this.pricePerEgg,
    required this.pricePerDozen,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.notes,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentDate,
    this.isReservation = false,
    this.reservationNotes,
    this.isLost = false,
    required this.createdAt,
  });

  double get totalAmount => quantitySold * pricePerEgg;
  int get dozens => quantitySold ~/ 12;
  int get individualEggs => quantitySold % 12;
  double get totalByDozen => (dozens * pricePerDozen) + (individualEggs * pricePerEgg);

  EggSale copyWith({
    String? id,
    String? date,
    int? quantitySold,
    double? pricePerEgg,
    double? pricePerDozen,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
    PaymentStatus? paymentStatus,
    String? paymentDate,
    bool? isReservation,
    String? reservationNotes,
    bool? isLost,
    DateTime? createdAt,
  }) {
    return EggSale(
      id: id ?? this.id,
      date: date ?? this.date,
      quantitySold: quantitySold ?? this.quantitySold,
      pricePerEgg: pricePerEgg ?? this.pricePerEgg,
      pricePerDozen: pricePerDozen ?? this.pricePerDozen,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      isReservation: isReservation ?? this.isReservation,
      reservationNotes: reservationNotes ?? this.reservationNotes,
      isLost: isLost ?? this.isLost,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, date, quantitySold, pricePerEgg, pricePerDozen,
        customerName, customerEmail, customerPhone, notes,
        paymentStatus, paymentDate, isReservation, reservationNotes,
        isLost, createdAt,
      ];
}
