class Service {
  final int id;
  final String name;
  final String? description;
  final double price;

  const Service({
    required this.id,
    required this.name,
    this.description,
    required this.price,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
      );
}
