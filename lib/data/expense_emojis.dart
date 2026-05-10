class ExpenseEmojis {
  static const Map<String, List<String>> catalog = {
    'Vivienda': ['🏠', '🏡', '🏢', '🛋️', '🪑', '🛏️'],
    'Transporte': ['🚗', '🚙', '🏍️', '🚌', '🚎', '✈️'],
    'Alimentación': ['🍔', '🍕', '🥗', '🍱', '🛒', '☕'],
    'Salud': ['💊', '🏥', '🩺', '🦷', '👁️', '🧘'],
    'Entretenimiento': ['🎬', '🎮', '🎵', '📚', '🎭', '🏖️'],
    'Suscripciones': ['📱', '💻', '📺', '🎧', '📡', '🔔'],
    'Finanzas': ['💳', '💵', '🏦', '📈', '💸', '🪙'],
    'Educación': ['📚', '🎓', '✏️', '🖊️', '📐', '🏫'],
    'Mascotas': ['🐶', '🐱', '🐾', '🦴', '🐠', '🐇'],
    'Otros': ['📦', '🎁', '🛍️', '✂️', '🧰', '🪴'],
  };

  // Todos los emojis en una lista plana (para búsqueda)
  static List<String> get all => catalog.values.expand((e) => e).toList();

  //predeterminads
  static const List<Map<String, String>> systemCategories = [
    {'id': 'sys_housing', 'name': 'Vivienda', 'emoji': '🏠'},
    {'id': 'sys_transport', 'name': 'Transporte', 'emoji': '🚗'},
    {'id': 'sys_food', 'name': 'Alimentación', 'emoji': '🍔'},
    {'id': 'sys_health', 'name': 'Salud', 'emoji': '💊'},
    {'id': 'sys_entertainment', 'name': 'Entretenimiento', 'emoji': '🎬'},
    {'id': 'sys_subscriptions', 'name': 'Suscripciones', 'emoji': '📱'},
  ];
}
