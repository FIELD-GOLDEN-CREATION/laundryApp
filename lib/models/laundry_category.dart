class LaundryCategory {
  const LaundryCategory({
    required this.id,
    required this.name,
    required this.nameSwahili,
    required this.description,
    required this.imageUrl,
    required this.items,
  });

  final String id;
  final String name;
  final String nameSwahili;
  final String description;
  final String imageUrl;
  final List<LaundryItem> items;
}

class LaundryItem {
  const LaundryItem({
    required this.id,
    required this.name,
    required this.nameSwahili,
    required this.description,
    required this.imageUrl,
    required this.priceTzs,
    required this.unit,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final String nameSwahili;
  final String description;
  final String imageUrl;
  final double priceTzs;
  final String unit;
  final bool isAvailable;

  LaundryItem copyWith({
    String? id,
    String? name,
    String? nameSwahili,
    String? description,
    String? imageUrl,
    double? priceTzs,
    String? unit,
    bool? isAvailable,
  }) => LaundryItem(
    id: id ?? this.id,
    name: name ?? this.name,
    nameSwahili: nameSwahili ?? this.nameSwahili,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    priceTzs: priceTzs ?? this.priceTzs,
    unit: unit ?? this.unit,
    isAvailable: isAvailable ?? this.isAvailable,
  );
}
