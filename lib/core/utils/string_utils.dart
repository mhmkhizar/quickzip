class StringUtils {
  static String removeSpecialCharacters(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  static String convertLettersToNumbers(String input) {
    return input.split('').map((char) {
      if (RegExp(r'[0-9]').hasMatch(char)) {
        return char;
      }
      return (char.toLowerCase().codeUnitAt(0) - 96).toString();
    }).join();
  }

  static String incrementNumbers(String input) {
    return input.split('').map((char) {
      int num = int.parse(char);
      return ((num + 1) % 10).toString();
    }).join();
  }

  static String pairAndMix(String input) {
    List<String> chars = input.split('');
    List<String> result = [];
    int length = chars.length;
    
    for (int i = 0; i < length ~/ 2; i++) {
      result.add(chars[i]);
      result.add(chars[length - 1 - i]);
    }
    
    if (length % 2 != 0) {
      result.add(chars[length ~/ 2]);
    }
    
    return result.join();
  }
}