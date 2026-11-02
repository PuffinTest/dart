# PuffinTest for Dart

PuffinTest is an early Dart package for named test cases and readable expectation failures. It currently provides equality, inequality, truth, falsehood, membership, and typed exception checks, explicit failure, tags, skips, name and tag filters, async callbacks and hooks, and sequential execution with a `0` or `1` result.

The package requires Dart SDK 3.3 or newer. It is not published to pub.dev.

## Run the example

From this directory:

```sh
dart pub get
dart run example/basic.dart
```

Declare cases with `test(name, callback)` and run them with `runTests`:

```dart
import 'dart:io';
import 'package:puffintest/puffintest.dart';

Future<void> main() async {
  final cases = [
    test('greets the user', () {
      expectEqual('HELLO', 'hello'.toUpperCase());
      expectBetween(18, 13, 19);
    }),
  ];
  exitCode = await runTests(cases);
}
```

Each case runs independently. Reports include the case, failed expectation, expected and actual values when available, and the source file and line when the Dart runtime provides them. `runTests` returns `1` when a case fails or no cases match.

The checks are `expectEqual`, `expectNotEqual`, `expectFinite`, `expectNotFinite`, `expectNaN`, `expectNotNaN`, `expectClose`, `expectNotClose`, `expectBetween`, `expectNotBetween`, `expectGreaterThan`, `expectLessThan`, `expectAtLeast`, `expectAtMost`, `expectLength`, `expectLengthBetween`, `expectTrue`, `expectFalse`, `expectNull`, `expectNotNull`, `expectEmpty`, `expectNotEmpty`, `expectStartsWith`, `expectEndsWith`, `expectNotStartsWith`, `expectNotEndsWith`, `expectContains`, `expectNotContains`, `expectThrows<T>`, `expectErrorMessage`, `expectMatches`, `expectNotMatches`, and `fail`. `expectFinite` rejects NaN and infinity; `expectNotFinite` accepts them and rejects finite numbers. `expectNaN` accepts only NaN; `expectNotNaN` rejects NaN and accepts other numbers. `expectBetween` uses inclusive numeric bounds. Prefix and suffix checks use Dart's case-sensitive `String.startsWith` and `String.endsWith` behavior. `runTests` accepts optional `filter`, `tag`, `failFast`, `beforeEach`, and `afterEach` arguments.

Length and empty/non-empty checks accept strings, iterables, and maps using Dart's native `length` behavior. Regex checks use Dart `RegExp` and search for a match anywhere in the string.

This package is an initial implementation and has not yet been verified. Equality uses Dart's `==` semantics, so collection values need their own equality implementation to compare by contents.
