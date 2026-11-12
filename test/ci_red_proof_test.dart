// Deliberately broken (ticket #32 red proof). Never merge.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CI red proof: this test must fail',   () {
    expect(1 + 1, 3);
  });
}
