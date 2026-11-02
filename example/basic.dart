import 'dart:io';

import 'package:puffintest/puffintest.dart';

Future<void> main() async {
  final status = await runTests([
    test('formats a title', () => expectEqual('HELLO', 'hello'.toUpperCase())),
    test('finds an item', () {
      expectTrue(['puffin', 'tern'].contains('puffin'));
      expectContains('puffin test', 'test');
      expectNotContains('puffin test', 'penguin');
    }),
    test('checks collection sizes', () {
      expectLength(['puffin', 'tern'], 2);
      expectLengthBetween(['puffin', 'tern'], 1, 3);
    }),
    test('checks nullable values', () { expectNull(null); expectNotNull('puffin'); }),
    test('checks an empty collection', () { expectEmpty(<String>[]); expectNotEmpty(['puffin']); }),
    test('checks an error message', () {
      final error = expectThrows<StateError>(() { throw StateError('missing puffin'); });
      expectErrorMessage(error, 'puffin');
    }),
    test('matches text patterns', () {
      expectMatches('order-4821 accepted', r'order-\d+ accepted');
      expectNotMatches('request failed', r'\b2xx\b');
    }),
    test('checks numeric thresholds', () {
      expectGreaterThan(5, 3);
      expectLessThan(2, 3);
      expectAtLeast(3, 3);
      expectAtMost(3, 3);
      expectNotBetween(4, 1, 3);
      expectNotClose(0.1, 0.9);
    }),
  ]);
  exitCode = status;
}
