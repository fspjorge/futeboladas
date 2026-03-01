class FormatUtils {
  static String formatarPreco(num? preco) {
    if (preco == null || preco <= 0) {
      return 'Grátis';
    }
    // Consistent format across the app
    return '€ ${preco.toStringAsFixed(2)}';
  }
}
