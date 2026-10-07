import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Korean course asset has 22 topics and 330 phrases', () {
    final file = File('assets/course/ko/course.json');
    expect(file.existsSync(), isTrue);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(json['learningLanguageCode'], 'ko');
    expect(json['topics'], hasLength(22));
    expect(json['phrases'], hasLength(330));
  });
}
