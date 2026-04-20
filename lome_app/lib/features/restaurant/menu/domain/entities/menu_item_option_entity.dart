import 'package:equatable/equatable.dart';

/// Opción/modificador de un item del menú (tamaño, extra, salsa, etc.).
class MenuItemOption extends Equatable {
  final String id;
  final String menuItemId;
  final String tenantId;
  final String groupName;
  final String name;
  final double priceModifier;
  final bool isDefault;
  final int maxSelections;
  final int sortOrder;
  final bool isActive;

  const MenuItemOption({
    required this.id,
    required this.menuItemId,
    required this.tenantId,
    required this.groupName,
    required this.name,
    this.priceModifier = 0,
    this.isDefault = false,
    this.maxSelections = 1,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory MenuItemOption.fromJson(Map<String, dynamic> json) {
    return MenuItemOption(
      id: json['id'] as String,
      menuItemId: json['menu_item_id'] as String,
      tenantId: json['tenant_id'] as String,
      groupName: json['group_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceModifier: (json['price_modifier'] as num?)?.toDouble() ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
      maxSelections: json['max_selections'] as int? ?? 1,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'menu_item_id': menuItemId,
    'tenant_id': tenantId,
    'group_name': groupName,
    'name': name,
    'price_modifier': priceModifier,
    'is_default': isDefault,
    'max_selections': maxSelections,
    'sort_order': sortOrder,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [id, groupName, name];
}

/// Grupo de opciones (ej: "Tamaño" con opciones "S/M/L").
class OptionGroup {
  final String name;
  final int maxSelections;
  final List<MenuItemOption> options;

  const OptionGroup({
    required this.name,
    required this.maxSelections,
    required this.options,
  });

  /// Agrupa una lista plana de opciones por `groupName`.
  static List<OptionGroup> fromOptions(List<MenuItemOption> options) {
    final groups = <String, List<MenuItemOption>>{};
    for (final opt in options) {
      groups.putIfAbsent(opt.groupName, () => []).add(opt);
    }
    return groups.entries.map((e) {
      final maxSel = e.value.first.maxSelections;
      return OptionGroup(
        name: e.key,
        maxSelections: maxSel,
        options: e.value..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );
    }).toList();
  }
}
