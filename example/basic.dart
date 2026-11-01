import 'dart:io';

import 'package:puffintest/puffintest.dart';

Future<void> main() async {
  final status = await runTests([
    test('formats a title', () => expectEqual('HELLO', 'hello'.toUpperCase())),
    test('finds an item', () => expectTrue(['puffin', 'tern'].contains('puffin'))),
  ]);
  exitCode = status;
}
