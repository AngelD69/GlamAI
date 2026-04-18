class Payment {
  final int id;
  final int appointmentId;
  final int userId;
  final double amount;
  final String paymentMethod;   // esewa | khalti | cash
  final String paymentStatus;   // completed
  final String transactionRef;
  final String? createdAt;

  const Payment({
    required this.id,
    required this.appointmentId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionRef,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as int,
        appointmentId: json['appointment_id'] as int,
        userId: json['user_id'] as int,
        amount: (json['amount'] as num).toDouble(),
        paymentMethod: json['payment_method'] as String,
        paymentStatus: json['payment_status'] as String,
        transactionRef: json['transaction_ref'] as String,
        createdAt: json['created_at'] as String?,
      );

  String get methodLabel => switch (paymentMethod.toLowerCase()) {
        'esewa' => 'eSewa',
        'khalti' => 'Khalti',
        _ => 'Cash on Arrival',
      };
}
