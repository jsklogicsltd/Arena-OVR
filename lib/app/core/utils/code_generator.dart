import 'dart:math';

class CodeGenerator {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _rnd = Random();

  static String generate(int length) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ));
  }
}
