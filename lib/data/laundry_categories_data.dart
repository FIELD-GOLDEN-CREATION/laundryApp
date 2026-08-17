import '../models/laundry_category.dart';

const kLaundryCategories = [
  LaundryCategory(
    id: 'standard-wear',
    name: 'Standard Everyday Wear',
    nameSwahili: 'Nguo za Kila Siku',
    description: 'Items cleaned using standard commercial wash-and-fold or light steam press processes.',
    imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800&q=80',
    items: [
      LaundryItem(
        id: 'tshirt-polo',
        name: 'T-Shirt / Polo',
        nameSwahili: 'T-Shirt / Polo',
        description: 'Wash, dry, & fold / light press',
        imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800&q=80',
        priceTzs: 2250,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'casual-shirt',
        name: 'Casual Shirt / Blouse',
        nameSwahili: 'Shati la Kawaida / Blausi',
        description: 'Button-down wash & steam press',
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=800&q=80',
        priceTzs: 3000,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'trousers-jeans',
        name: 'Trousers / Jeans / Chinos',
        nameSwahili: 'Suruali / Jeans / Chinos',
        description: 'Standard wash & press',
        imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800&q=80',
        priceTzs: 3500,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'shorts-skirt',
        name: 'Shorts / Skirt (Plain)',
        nameSwahili: 'Pajama / Sketi',
        description: 'Standard wash & fold',
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80',
        priceTzs: 2250,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'underwear-socks',
        name: 'Underwear / Socks',
        nameSwahili: 'Chupi / Socks',
        description: 'Per pair / piece (Wash & fold)',
        imageUrl: 'https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=800&q=80',
        priceTzs: 750,
        unit: 'per piece',
      ),
    ],
  ),
  LaundryCategory(
    id: 'formal-outerwear',
    name: 'Formal, Woolen & Outerwear',
    nameSwahili: 'Mavazi Rasmi & Nje',
    description: 'Items requiring delicate handling, dry-cleaning solvent treatment, or structured steam pressing.',
    imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80',
    items: [
      LaundryItem(
        id: 'suit-2piece',
        name: '2-Piece Suit (Jacket + Pants)',
        nameSwahili: 'Suti ya VIP 2 (Jaketi + Suruali)',
        description: 'Full dry clean & press',
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80',
        priceTzs: 9500,
        unit: 'per set',
      ),
      LaundryItem(
        id: 'suit-3piece',
        name: '3-Piece Suit (Jacket, Vest, Pants)',
        nameSwahili: 'Suti ya VIP 3 (Jaketi, Vest, Suruali)',
        description: 'Full dry clean & press',
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80',
        priceTzs: 12500,
        unit: 'per set',
      ),
      LaundryItem(
        id: 'suit-jacket',
        name: 'Suit Jacket / Blazer',
        nameSwahili: 'Jaketi ya Suti / Blazer',
        description: 'Standalone jacket dry clean',
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80',
        priceTzs: 6000,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'heavy-coat',
        name: 'Heavy Coat / Trench Coat',
        nameSwahili: 'Koti Nzito / Koti ya Mtaro',
        description: 'Winter/wool coat deep dry clean',
        imageUrl: 'https://images.unsplash.com/photo-1539533113208-f6df8cc8b543?w=800&q=80',
        priceTzs: 11500,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'sweater-cardigan',
        name: 'Sweater / Cardigan / Hoodie',
        nameSwahili: 'Sweta / Cardigan / Hoodie',
        description: 'Delicate wash or dry clean',
        imageUrl: 'https://images.unsplash.com/photo-1434389677669-e08b4cda3a40?w=800&q=80',
        priceTzs: 4500,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'evening-gown',
        name: 'Evening Gown / Dress',
        nameSwahili: 'Gauni ya Jioni / Avazi',
        description: 'Delicate fabric / beaded treatment',
        imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&q=80',
        priceTzs: 9000,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'wedding-dress',
        name: 'Wedding Dress / Suit',
        nameSwahili: 'Gauni ya Harusi / Suti',
        description: 'Deep stain removal & preservation',
        imageUrl: 'https://images.unsplash.com/photo-1594463750939-c2ced530f2f5?w=800&q=80',
        priceTzs: 45000,
        unit: 'per piece',
      ),
    ],
  ),
  LaundryCategory(
    id: 'footwear-bags',
    name: 'Footwear & Bags Care',
    nameSwahili: 'Viatu na Mifuko',
    description: 'Deep cleaning, brush washing, deodorization, and material treatment (canvas, leather, suede).',
    imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
    items: [
      LaundryItem(
        id: 'sneakers',
        name: 'Sneakers / Running Shoes',
        nameSwahili: 'Viatu vya Kukimbia',
        description: 'Mesh/canvas deep wash & sole whitening',
        imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
        priceTzs: 6000,
        unit: 'per pair',
      ),
      LaundryItem(
        id: 'leather-shoes',
        name: 'Leather Shoes / Boots',
        nameSwahili: 'Viatu vya Ngozi / Boots',
        description: 'Gentle clean, condition & polish',
        imageUrl: 'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?w=800&q=80',
        priceTzs: 8000,
        unit: 'per pair',
      ),
      LaundryItem(
        id: 'suede-shoes',
        name: 'Suede Shoes',
        nameSwahili: 'Viatu vya Suede',
        description: 'Specialized suede dry clean & brush',
        imageUrl: 'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?w=800&q=80',
        priceTzs: 10000,
        unit: 'per pair',
      ),
      LaundryItem(
        id: 'backpack-duffel',
        name: 'Backpack / Duffel Bag',
        nameSwahili: 'Begi / Begi ya Duffel',
        description: 'Fabric wash & strap cleaning',
        imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&q=80',
        priceTzs: 6000,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'handbag-leather',
        name: 'Handbag / Leather Bag',
        nameSwahili: 'Begi ya Mkono / Begi ya Ngozi',
        description: 'Condition & spot cleaning',
        imageUrl: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80',
        priceTzs: 11500,
        unit: 'per piece',
      ),
    ],
  ),
  LaundryCategory(
    id: 'bedding-household',
    name: 'Bedding, Household & Heavy Fabrics',
    nameSwahili: 'Mashuka, Vifaa vya Nyumba & Mitambizo',
    description: 'Large items that require industrial washing machines or specialized drying racks.',
    imageUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800&q=80',
    items: [
      LaundryItem(
        id: 'blanket-single',
        name: 'Blanket (Single Ply)',
        nameSwahili: 'Blanketi (Tabaka 1)',
        description: 'Deep wash & dry',
        imageUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800&q=80',
        priceTzs: 6500,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'blanket-duvet',
        name: 'Blanket / Duvet (Double / Heavy)',
        nameSwahili: 'Blanketi / Duvet (Mzito)',
        description: 'Heavy wash, fluff & dry',
        imageUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800&q=80',
        priceTzs: 11500,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'bedsheet',
        name: 'Bedsheet (Single / Double)',
        nameSwahili: 'Kitanda (Tangi / Pembe)',
        description: 'Wash, iron & fold',
        imageUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800&q=80',
        priceTzs: 3000,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'duvet-cover',
        name: 'Duvet Cover / Bedspread',
        nameSwahili: 'Gesi ya Duvet / Kitanda',
        description: 'Wash & iron',
        imageUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800&q=80',
        priceTzs: 4500,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'pillow-cushion',
        name: 'Pillow / Cushion',
        nameSwahili: 'Mto / Matakia',
        description: 'Spot clean & internal wash',
        imageUrl: 'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?w=800&q=80',
        priceTzs: 3750,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'curtains',
        name: 'Curtains (per kg or set)',
        nameSwahili: 'Mapazia (kwa kg au set)',
        description: 'Deep dry clean/wash per panel',
        imageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800&q=80',
        priceTzs: 4500,
        unit: 'per panel',
      ),
    ],
  ),
  LaundryCategory(
    id: 'bulk-addons',
    name: 'Bulk Services & Add-Ons',
    nameSwahili: 'Huduma za Wingi & Nyongeza',
    description: 'Pricing models based on weight or extra service handling.',
    imageUrl: 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=800&q=80',
    items: [
      LaundryItem(
        id: 'bulk-wash-kg',
        name: 'Bulk Wash & Fold (Per KG)',
        nameSwahili: 'Osha na Kunja (kwa KG)',
        description: 'General mixed laundry (Min 3kg)',
        imageUrl: 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=800&q=80',
        priceTzs: 2750,
        unit: 'per kg',
      ),
      LaundryItem(
        id: 'ironing-only',
        name: 'Ironing Only (Per Item)',
        nameSwahili: 'Kupiga Pasi (kwa Kitu)',
        description: 'Pressing pre-washed clothes',
        imageUrl: 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=800&q=80',
        priceTzs: 1150,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'express-fee',
        name: 'Express Service Fee',
        nameSwahili: 'Ada ya Haraka',
        description: 'Same-day or 24-hour delivery',
        imageUrl: 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=800&q=80',
        priceTzs: 0,
        unit: '+50% of total order',
      ),
      LaundryItem(
        id: 'pickup-delivery',
        name: 'Pickup & Delivery Fee',
        nameSwahili: 'Ada ya Kuchukua & Kuleta',
        description: 'Flat distance-based app fee',
        imageUrl: 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=800&q=80',
        priceTzs: 3500,
        unit: 'flat fee',
      ),
    ],
  ),
];

LaundryCategory? getCategoryById(String id) {
  try {
    return kLaundryCategories.firstWhere((cat) => cat.id == id);
  } catch (_) {
    return null;
  }
}

LaundryItem? getItemById(String itemId) {
  for (final cat in kLaundryCategories) {
    try {
      return cat.items.firstWhere((item) => item.id == itemId);
    } catch (_) {
      continue;
    }
  }
  return null;
}

List<LaundryItem> getAllItems() {
  return kLaundryCategories.expand((cat) => cat.items).toList();
}
