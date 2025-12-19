extension EList on List {
  String inString() {
    String result = '';
    for(int i = 0; i < length; i++) {
      result += '${this[i]}${(i < length - 1) ? ', ' : ''}';
    }

    return result;
  }
}