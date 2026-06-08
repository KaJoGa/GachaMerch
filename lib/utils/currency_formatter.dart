class CurrencyFormatter {
  static String format(dynamic price) {
    int value = price is int ? price : int.tryParse(price.toString()) ?? 0;
    String str = value.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      count++;
      result = str[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return '✦ $result';
  }
}
