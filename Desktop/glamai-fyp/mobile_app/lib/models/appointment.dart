import 'service.dart';

class Appointment {
  final int id;
  final int userId;
  final int serviceId;
  final Service service;
  final String appointmentDate; // 'yyyy-MM-dd'
  final String appointmentTime; // 'HH:mm:ss'
  final String? notes;
  final String status;
  final String? createdAt;

  const Appointment({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.service,
    required this.appointmentDate,
    required this.appointmentTime,
    this.notes,
    required this.status,
    this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        serviceId: json['service_id'] as int,
        service: Service.fromJson(json['service'] as Map<String, dynamic>),
        appointmentDate: json['appointment_date'] as String,
        appointmentTime: json['appointment_time'] as String,
        notes: json['notes'] as String?,
        status: (json['status'] as String?) ?? 'pending',
        createdAt: json['created_at'] as String?,
      );

  /// Returns a display-friendly date string: 'Mon, 16 Apr 2026'
  String get formattedDate {
    try {
      final d = DateTime.parse(appointmentDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return appointmentDate;
    }
  }

  /// True when the appointment date is today or in the past.
  bool get isPast {
    try {
      return DateTime.parse(appointmentDate).isBefore(
        DateTime.now().add(const Duration(days: 1)),
      );
    } catch (_) {
      return false;
    }
  }

  /// Returns display time: '10:30 AM'
  String get formattedTime {
    try {
      final parts = appointmentTime.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:$m $period';
    } catch (_) {
      return appointmentTime;
    }
  }
}
