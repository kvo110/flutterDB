// Simple model for a category in Firestore
class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'name': name};

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(id: id, name: map['name'] ?? '');
  }
}
