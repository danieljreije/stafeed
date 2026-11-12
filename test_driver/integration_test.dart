// Host side of the web end-to-end test (#36). `flutter drive` runs this on
// the machine and it waits for integration_test/ to report its result.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
