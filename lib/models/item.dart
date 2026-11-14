class Item {
  const Item({
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String title;
  final String body;
  final DateTime createdAt;

  factory Item.fromJson(Map<String, dynamic> json) {
    if (json['title'] is! String ||
        json['body'] is! String ||
        json['createdAt'] is! String) {
      throw const FormatException('Invalid item data');
    }
    return Item(
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}
