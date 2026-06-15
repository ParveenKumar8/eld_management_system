import 'package:eld_management_system/features/ble/data/parsers/geometris_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GeometrisParser parser;

  setUp(() {
    parser = GeometrisParser();
  });

  test('parses standard Geometris frame', () {
    final bytes = <int>[
      0x7E, // header
      0, 0, 0, 0,
      0, 0, 100, 50, // odometer raw
      0, 55, // speed 5.5 mph -> 55 tenths
      0x01, // moving flag
      0, 10,
      0, 0, 0x12, 0x34,
      0, 0, 0x56, 0x78,
    ];

    final result = parser.parse(bytes);

    expect(result, isNotNull);
    expect(result!.isMoving, true);
    expect(result.speedMph, closeTo(5.5, 0.1));
  });

  test('returns null for too-short payload', () {
    expect(parser.parse([1, 2, 3]), isNull);
  });
}