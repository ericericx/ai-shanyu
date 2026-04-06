import 'package:intl/intl.dart';

final _formatter = NumberFormat('#,###');

/// 格式化價格為千分位字串，例如 1000 → "NT$ 1,000"
String formatPrice(int price) => 'NT\$ ${_formatter.format(price)}';
