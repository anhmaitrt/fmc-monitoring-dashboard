extension EList on List? {
  bool isNullOrEmpty() => this == null || this!.isEmpty;

  String inString() {
    String result = '';
    if(this == null) return result;

    for(int i = 0; i < this!.length; i++) {
      result += '${this![i]}${(i < this!.length - 1) ? ', ' : ''}';
    }

    return result;
  }
}