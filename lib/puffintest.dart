library puffintest;

import 'dart:async';
import 'dart:math' as math;

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

/// Fail unless [actual] starts with [prefix].
void expectStartsWith(String actual, String prefix, [String? message]) {
  if (!actual.startsWith(prefix)) {
    _fail(message ?? 'Text does not start with the expected prefix', expected: 'text starting with "$prefix"', actual: actual, hasValues: true);
  }
}

/// Fail unless [actual] ends with [suffix].
void expectEndsWith(String actual, String suffix, [String? message]) {
  if (!actual.endsWith(suffix)) {
    _fail(message ?? 'Text does not end with the expected suffix', expected: 'text ending with "$suffix"', actual: actual, hasValues: true);
  }
}

/// Fail if [actual] starts with [prefix].
void expectNotStartsWith(String actual, String prefix, [String? message]) {
  if (actual.startsWith(prefix)) {
    _fail(message ?? 'Text unexpectedly starts with the prefix', expected: 'text not starting with "$prefix"', actual: actual, hasValues: true);
  }
}

/// Fail if [actual] ends with [suffix].
void expectNotEndsWith(String actual, String suffix, [String? message]) {
  if (actual.endsWith(suffix)) {
    _fail(message ?? 'Text unexpectedly ends with the suffix', expected: 'text not ending with "$suffix"', actual: actual, hasValues: true);
  }
}

/// Fail unless [actual] has a length in the inclusive [minimum] to [maximum] range.
void expectLengthBetween(Object? actual, int minimum, int maximum, [String? message]) {
  if (minimum < 0 || maximum < 0 || minimum > maximum) {
    throw ArgumentError('length bounds must be nonnegative and ordered');
  }
  final length = _lengthOf(actual);
  if (length < minimum || length > maximum) {
    _fail(message ?? 'Value length is outside the expected range', expected: 'length between $minimum and $maximum, inclusive', actual: length, hasValues: true);
  }
}

int _lengthOf(Object? actual) => switch (actual) {
      String value => value.length,
      Iterable values => value.length,
      Map values => values.length,
      _ => throw ArgumentError.value(actual, 'actual', 'must be a string, iterable, or map'),
    };

/// Fail unless [actual] has exactly [expected] items or characters.
void expectLength(Object? actual, int expected, [String? message]) {
  if (expected < 0) throw ArgumentError.value(expected, 'expected', 'must be nonnegative');
  final length = _lengthOf(actual);
  if (length != expected) {
    _fail(message ?? 'Value has an unexpected length', expected: expected, actual: length, hasValues: true);
  }
}

/// Fail unless [actual] has no items or characters.
void expectEmpty(Object? actual, [String? message]) {
  final length = _lengthOf(actual);
  if (length != 0) _fail(message ?? 'Expected an empty value', expected: 0, actual: length, hasValues: true);
}

/// Fail unless [actual] has at least one item or character.
void expectNotEmpty(Object? actual, [String? message]) {
  final length = _lengthOf(actual);
  if (length == 0) _fail(message ?? 'Expected a non-empty value', expected: 'at least 1 item', actual: length, hasValues: true);
}

/// Fail unless two numbers are close under relative and absolute tolerances.
void expectClose(num actual, num expected, {double relTol = 1e-9, double absTol = 0, String? message}) {
  if (!relTol.isFinite || !absTol.isFinite || relTol < 0 || absTol < 0) {
    throw ArgumentError('tolerances must be finite and nonnegative');
  }
  final difference = (actual - expected).abs();
  final scale = math.max(actual.abs(), expected.abs());
  final close = actual == expected || (actual.isFinite && expected.isFinite &&
      (difference <= absTol || (scale != 0 && difference / scale <= relTol)));
  if (!close) {
    _fail(message ?? 'Values are not close (relTol=$relTol, absTol=$absTol)', expected: expected, actual: actual, hasValues: true);
  }
}

/// Fail unless [actual] is between [minimum] and [maximum], inclusive.
void expectBetween(num actual, num minimum, num maximum, [String? message]) {
  if (minimum > maximum) throw ArgumentError('minimum must be less than or equal to maximum');
  if (!(actual >= minimum && actual <= maximum)) {
    _fail(message ?? 'Value is outside the expected range', expected: 'between $minimum and $maximum, inclusive', actual: actual, hasValues: true);
  }
}

/// Fail unless [actual] is strictly greater than [threshold].
void expectGreaterThan(num actual, num threshold, [String? message]) {
  if (!(actual > threshold)) {
    _fail(message ?? 'Value is not greater than the threshold', expected: 'greater than $threshold', actual: actual, hasValues: true);
  }
}

/// Fail unless [actual] is strictly less than [threshold].
void expectLessThan(num actual, num threshold, [String? message]) {
  if (!(actual < threshold)) {
    _fail(message ?? 'Value is not less than the threshold', expected: 'less than $threshold', actual: actual, hasValues: true);
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

/// Fail unless [actual] is null.
void expectNull(Object? actual, [String? message]) {
  if (actual != null) _fail(message ?? 'Expected null', expected: null, actual: actual, hasValues: true);
}

/// Fail unless [actual] is non-null.
void expectNotNull(Object? actual, [String? message]) {
  if (actual == null) _fail(message ?? 'Expected a non-null value', expected: 'non-null', actual: null, hasValues: true);
}

/// Fail unless [item] is in an iterable, map key set, string, or array-like list.
void expectContains(Object? container, Object? item, [String? message]) {
  final contains = _containsValue(container, item);
  if (!contains) {
    _fail(message ?? 'Item is not present in the container', expected: 'a container containing $item', actual: container, hasValues: true);
  }
}

/// Fail if [item] is in an iterable, map key set, or string.
void expectNotContains(Object? container, Object? item, [String? message]) {
  if (_containsValue(container, item)) {
    _fail(message ?? 'Item is unexpectedly present in the container', expected: 'a container not containing $item', actual: container, hasValues: true);
  }
}

bool _containsValue(Object? container, Object? item) => switch (container) {
    Iterable values => values.contains(item),
    Map values => values.containsKey(item),
    String value when item is String => value.contains(item),
    _ => throw ArgumentError.value(container, 'container', 'must be an iterable, map, or string'),
  };

/// Require [callback] to throw an object of type [T] and return that object.
T expectThrows<T extends Object>(void Function() callback, [String? message]) {
  Object? thrown;
  var didThrow = false;
  try {
    callback();
  } catch (error) {
    thrown = error;
    didThrow = true;
  }
  if (didThrow && thrown is T) return thrown;
  _fail(message ?? 'Expected $T to be thrown', expected: T, actual: didThrow ? thrown : 'no exception', hasValues: true);
}

/// Fail unless [substring] occurs in [error]'s string representation.
void expectErrorMessage(Object error, String substring, [String? message]) {
  final actual = error.toString();
  if (!actual.contains(substring)) {
    _fail(message ?? 'Error message does not contain the expected text', expected: 'error message containing "$substring"', actual: actual, hasValues: true);
  }
}

/// Fail unless [pattern] matches somewhere in [actual].
void expectMatches(String actual, String pattern, [String? message]) {
  if (!RegExp(pattern).hasMatch(actual)) {
    _fail(message ?? 'Text does not match the expected pattern', expected: 'text matching "$pattern"', actual: actual, hasValues: true);
  }
}

/// Fail if [pattern] matches anywhere in [actual].
void expectNotMatches(String actual, String pattern, [String? message]) {
  if (RegExp(pattern).hasMatch(actual)) {
    _fail(message ?? 'Text unexpectedly matches the pattern', expected: 'text not matching "$pattern"', actual: actual, hasValues: true);
  }
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
