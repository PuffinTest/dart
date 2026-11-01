library puffintest;

import 'dart:async';

typedef TestBody = FutureOr<void> Function();

/// A named test callback with optional tags or a skip reason.
final class TestCase {
  TestCase(String name, this.body, {Iterable<String> tags = const [], this.skipReason})
      : name = name.trim(),
        tags = List.unmodifiable(tags.map((tag) => tag.trim())) {
    if (this.name.isEmpty) throw ArgumentError.value(name, 'name', 'must not be blank');
    if (this.tags.any((tag) => tag.isEmpty)) {
      throw ArgumentError.value(tags, 'tags', 'must contain nonempty names');
    }
    if (skipReason != null && skipReason!.trim().isEmpty) {
      throw ArgumentError.value(skipReason, 'skipReason', 'must not be blank');
    }
  }

  final String name;
  final TestBody body;
  final List<String> tags;
  final String? skipReason;
}

/// Create a named test case.
TestCase test(String name, TestBody body, {Iterable<String> tags = const [], String? skipReason}) =>
    TestCase(name, body, tags: tags, skipReason: skipReason);

/// Failure thrown by an expectation, including its call site when available.
final class ExpectationFailure implements Exception {
  ExpectationFailure(this.message, {this.expected, this.actual, this.hasValues = false})
      : source = _callerLocation();

  final String message;
  final Object? expected;
  final Object? actual;
  final bool hasValues;
  final String? source;

  @override
  String toString() => message;
}

String? _callerLocation() {
  final frames = StackTrace.current.toString().split('\n');
  for (final frame in frames) {
    if (frame.contains('package:puffintest/')) continue;
    final match = RegExp(r'\((.*):(\d+):(\d+)\)$').firstMatch(frame.trim());
    if (match != null) return '${match.group(1)}:${match.group(2)}';
  }
  return null;
}

Never _fail(String message, {Object? expected, Object? actual, bool hasValues = false}) =>
    throw ExpectationFailure(message, expected: expected, actual: actual, hasValues: hasValues);

/// Fail unless [actual] equals [expected] according to Dart's `==` operator.
void expectEqual(Object? actual, Object? expected, [String? message]) {
  if (actual != expected) {
    _fail(message ?? 'Values are not equal', expected: expected, actual: actual, hasValues: true);
  }
}

/// Fail unless [actual] and [unexpected] differ according to `==`.
void expectNotEqual(Object? actual, Object? unexpected, [String? message]) {
  if (actual == unexpected) {
    _fail(message ?? 'Values are unexpectedly equal', expected: 'different from $unexpected', actual: actual, hasValues: true);
  }
}

/// Fail unless [actual] is true.
void expectTrue(bool actual, [String? message]) {
  if (!actual) _fail(message ?? 'Expected true', expected: true, actual: actual, hasValues: true);
}

/// Fail unless [actual] is false.
void expectFalse(bool actual, [String? message]) {
  if (actual) _fail(message ?? 'Expected false', expected: false, actual: actual, hasValues: true);
}

/// Explicitly fail the current test case.
Never fail([String message = 'Explicit failure']) => _fail(message);

typedef TestHook = FutureOr<void> Function();

/// Run selected cases sequentially and return 0 on success or 1 on failure.
Future<int> runTests(
  Iterable<TestCase> cases, {
  String? filter,
  String? tag,
  bool failFast = false,
  TestHook? beforeEach,
  TestHook? afterEach,
}) async {
  final normalizedFilter = filter?.toLowerCase();
  final normalizedTag = tag?.toLowerCase();
  final selected = cases.where((testCase) {
    final nameMatches = normalizedFilter == null || testCase.name.toLowerCase().contains(normalizedFilter);
    final tagMatches = normalizedTag == null || testCase.tags.any((value) => value.toLowerCase() == normalizedTag);
    return nameMatches && tagMatches;
  }).toList();

  var passed = 0;
  var failed = 0;
  var skipped = 0;
  var processed = 0;
  for (final testCase in selected) {
    processed++;
    if (testCase.skipReason != null) {
      print('SKIP  ${testCase.name} (${testCase.skipReason})');
      skipped++;
      continue;
    }

    var didFail = false;
    String phase = 'beforeEach';
    var setupSucceeded = false;
    try {
      await beforeEach?.call();
      setupSucceeded = true;
      phase = 'test';
      await testCase.body();
      phase = 'afterEach';
      await afterEach?.call();
      print('PASS  ${testCase.name}');
      passed++;
    } catch (caught, stack) {
      didFail = true;
      failed++;
      _printFailure(testCase, caught, stack, phase);
      if (setupSucceeded && phase != 'afterEach' && afterEach != null) {
        try {
          await afterEach();
        } catch (teardownError, teardownStack) {
          failed++;
          _printFailure(testCase, teardownError, teardownStack, 'afterEach');
        }
      }
    }
    if (didFail && failFast) break;
  }

  print('\n$processed processed: $passed passed, $failed failed, $skipped skipped');
  if (selected.isEmpty) {
    if (filter != null && tag != null) {
      print('No test cases matched name "$filter" and tag "$tag"');
    } else if (filter != null) {
      print('No test cases matched name "$filter"');
    } else if (tag != null) {
      print('No test cases matched tag "$tag"');
    } else {
      print('No test cases were found');
    }
    return 1;
  }
  return failed == 0 ? 0 : 1;
}

void _printFailure(TestCase testCase, Object error, StackTrace stack, String phase) {
  final suffix = phase == 'test' ? '' : ' ($phase)';
  print('FAIL  ${testCase.name}$suffix');
  if (error is ExpectationFailure) {
    print('      ${error.message}');
    if (error.hasValues) {
      print('      Expected: ${error.expected}');
      print('      Actual:   ${error.actual}');
    }
    if (error.source != null) print('      ${error.source}');
  } else {
    print('      ${error.runtimeType}: $error');
    final frame = stack.toString().split('\n').firstWhere(
          (line) => line.trim().startsWith('#') && !line.contains('package:puffintest/'),
          orElse: () => '',
        );
    if (frame.isNotEmpty) print('      ${frame.trim()}');
  }
}
