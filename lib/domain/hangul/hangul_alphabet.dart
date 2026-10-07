class HangulLetter {
  const HangulLetter({
    required this.char,
    required this.nameRu,
    required this.nameEn,
    required this.isVowel,
  });

  final String char;
  final String nameRu;
  final String nameEn;
  final bool isVowel;

  String nameFor({required bool useEnglish}) => useEnglish ? nameEn : nameRu;
}

class HangulAlphabet {
  const HangulAlphabet._();

  static const consonants = <HangulLetter>[
    HangulLetter(char: 'ㄱ', nameRu: 'г/k', nameEn: 'g/k', isVowel: false),
    HangulLetter(char: 'ㄴ', nameRu: 'н/n', nameEn: 'n', isVowel: false),
    HangulLetter(char: 'ㄷ', nameRu: 'д/t', nameEn: 'd/t', isVowel: false),
    HangulLetter(char: 'ㄹ', nameRu: 'р/r', nameEn: 'r', isVowel: false),
    HangulLetter(char: 'ㅁ', nameRu: 'м/m', nameEn: 'm', isVowel: false),
    HangulLetter(char: 'ㅂ', nameRu: 'б/p', nameEn: 'b/p', isVowel: false),
    HangulLetter(char: 'ㅅ', nameRu: 'с/s', nameEn: 's', isVowel: false),
    HangulLetter(char: 'ㅇ', nameRu: 'н/ ng', nameEn: 'ng', isVowel: false),
    HangulLetter(char: 'ㅈ', nameRu: 'дж/ch', nameEn: 'j/ch', isVowel: false),
    HangulLetter(char: 'ㅊ', nameRu: "ч/ch'", nameEn: 'ch', isVowel: false),
    HangulLetter(char: 'ㅋ', nameRu: "к/k'", nameEn: 'k', isVowel: false),
    HangulLetter(char: 'ㅌ', nameRu: "т/t'", nameEn: 't', isVowel: false),
    HangulLetter(char: 'ㅍ', nameRu: "п/p'", nameEn: 'p', isVowel: false),
    HangulLetter(char: 'ㅎ', nameRu: 'х/h', nameEn: 'h', isVowel: false),
  ];

  static const vowels = <HangulLetter>[
    HangulLetter(char: 'ㅏ', nameRu: 'а/a', nameEn: 'a', isVowel: true),
    HangulLetter(char: 'ㅑ', nameRu: 'я/ya', nameEn: 'ya', isVowel: true),
    HangulLetter(char: 'ㅓ', nameRu: 'о/eo', nameEn: 'eo', isVowel: true),
    HangulLetter(char: 'ㅕ', nameRu: 'ё/yeo', nameEn: 'yeo', isVowel: true),
    HangulLetter(char: 'ㅗ', nameRu: 'о/o', nameEn: 'o', isVowel: true),
    HangulLetter(char: 'ㅛ', nameRu: 'ё/yo', nameEn: 'yo', isVowel: true),
    HangulLetter(char: 'ㅜ', nameRu: 'у/u', nameEn: 'u', isVowel: true),
    HangulLetter(char: 'ㅠ', nameRu: 'ю/yu', nameEn: 'yu', isVowel: true),
    HangulLetter(char: 'ㅡ', nameRu: 'ы/eu', nameEn: 'eu', isVowel: true),
    HangulLetter(char: 'ㅣ', nameRu: 'и/i', nameEn: 'i', isVowel: true),
  ];

  static HangulLetter? findByChar(String char) {
    for (final letter in [...consonants, ...vowels]) {
      if (letter.char == char) {
        return letter;
      }
    }
    return null;
  }
}
