import 'dart:io';

import 'package:puffintest/puffintest.dart';

Future<void> main() async {
  final status = await runTests([
    test('formats a title', () => expectEqual('HELLO', 'hello'.toUpperCase())),
    test('finds an item', () => expectTrue(['puffin', 'tern'].contains('puffin'))),
    test('keeps a collection within a size range', () => expectLengthBetween(['puffin', 'tern'], 1, 3)),
    test('checks nullable values', () { expectNull(null); expectNotNull('puffin'); }),
  ]);
  exitCode = status;
}
