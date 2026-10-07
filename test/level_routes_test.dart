import 'package:flutter_test/flutter_test.dart';
import 'package:vilka/features/level/presentation/level_routes.dart';

void main() {
  test('Level 0 nested routes keep the /level/0 prefix', () {
    expect(LevelRoutes.level0, '/level/0');
    expect(LevelRoutes.srs, '/level/0/srs');
    expect(LevelRoutes.hangul, '/level/0/hangul');
    expect(LevelRoutes.topics, '/level/0/topics');
    expect(LevelRoutes.topic(3), '/level/0/topics/3');
    expect(LevelRoutes.lesson(3, 12), '/level/0/topics/3/phrases/12');
    expect(LevelRoutes.player(3), '/level/0/topics/3/player');
    expect(LevelRoutes.exam(3), '/level/0/topics/3/exam');
  });
}
