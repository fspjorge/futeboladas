class FormatUtils {
  static String formatarPreco(num? price) {
    if (price == null || price <= 0) {
      return 'Grátis';
    }
    // Consistent format across the app
    return '€ ${price.toStringAsFixed(2)}';
  }
}
