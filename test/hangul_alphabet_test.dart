import 'package:flutter_test/flutter_test.dart';
import 'package:vilka/domain/hangul/hangul_alphabet.dart';

void main() {
  test('HangulAlphabet has 14 consonants and 10 vowels', () {
    expect(HangulAlphabet.consonants, hasLength(14));
    expect(HangulAlphabet.vowels, hasLength(10));
  });

  test('HangulAlphabet.findByChar returns the matching letter', () {
    expect(HangulAlphabet.findByChar('ㄱ')?.nameRu, 'г/k');
    expect(HangulAlphabet.findByChar('ㅣ')?.isVowel, isTrue);
    expect(HangulAlphabet.findByChar('x'), isNull);
  });
}
