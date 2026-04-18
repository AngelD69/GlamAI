class ServiceBookingCount {
  final String serviceName;
  final int count;
  const ServiceBookingCount({required this.serviceName, required this.count});
  factory ServiceBookingCount.fromJson(Map<String, dynamic> j) =>
      ServiceBookingCount(serviceName: j['service_name'] as String, count: j['count'] as int);
}

class StatusCount {
  final String status;
  final int count;
  const StatusCount({required this.status, required this.count});
  factory StatusCount.fromJson(Map<String, dynamic> j) =>
      StatusCount(status: j['status'] as String, count: j['count'] as int);
}

class SentimentCount {
  final String sentimentLabel;
  final int count;
  const SentimentCount({required this.sentimentLabel, required this.count});
  factory SentimentCount.fromJson(Map<String, dynamic> j) =>
      SentimentCount(sentimentLabel: j['sentiment_label'] as String, count: j['count'] as int);
}

class HourCount {
  final int hour;
  final int count;
  const HourCount({required this.hour, required this.count});
  factory HourCount.fromJson(Map<String, dynamic> j) =>
      HourCount(hour: j['hour'] as int, count: j['count'] as int);

  String get label {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h${hour < 12 ? 'am' : 'pm'}';
  }
}

class DayCount {
  final int dayOfWeek;
  final String dayName;
  final int count;
  const DayCount({required this.dayOfWeek, required this.dayName, required this.count});
  factory DayCount.fromJson(Map<String, dynamic> j) => DayCount(
        dayOfWeek: j['day_of_week'] as int,
        dayName: j['day_name'] as String,
        count: j['count'] as int,
      );

  String get shortName => dayName.substring(0, 3);
}

class RecentAppointment {
  final int id;
  final String userName;
  final String serviceName;
  final String appointmentDate;
  final String appointmentTime;
  final String status;
  const RecentAppointment({
    required this.id,
    required this.userName,
    required this.serviceName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
  });
  factory RecentAppointment.fromJson(Map<String, dynamic> j) => RecentAppointment(
        id: j['id'] as int,
        userName: j['user_name'] as String,
        serviceName: j['service_name'] as String,
        appointmentDate: j['appointment_date'] as String,
        appointmentTime: j['appointment_time'] as String,
        status: j['status'] as String,
      );
}

class AdminStats {
  final int totalUsers;
  final int totalBookings;
  final double? averageRating;
  final List<ServiceBookingCount> bookingsByService;
  final List<StatusCount> statusBreakdown;
  final List<SentimentCount> sentimentSummary;
  final List<HourCount> bookingsByHour;
  final List<DayCount> bookingsByDay;
  final List<RecentAppointment> recentAppointments;

  const AdminStats({
    required this.totalUsers,
    required this.totalBookings,
    this.averageRating,
    required this.bookingsByService,
    required this.statusBreakdown,
    required this.sentimentSummary,
    required this.bookingsByHour,
    required this.bookingsByDay,
    required this.recentAppointments,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalUsers: j['total_users'] as int,
        totalBookings: j['total_bookings'] as int,
        averageRating: (j['average_rating'] as num?)?.toDouble(),
        bookingsByService: (j['bookings_by_service'] as List)
            .map((e) => ServiceBookingCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        statusBreakdown: (j['status_breakdown'] as List)
            .map((e) => StatusCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        sentimentSummary: (j['sentiment_summary'] as List)
            .map((e) => SentimentCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        bookingsByHour: (j['bookings_by_hour'] as List)
            .map((e) => HourCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        bookingsByDay: (j['bookings_by_day'] as List)
            .map((e) => DayCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentAppointments: (j['recent_appointments'] as List)
            .map((e) => RecentAppointment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
