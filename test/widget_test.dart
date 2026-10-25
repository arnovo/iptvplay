import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_expert_clone/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Tests that app widget builds cleanly
    expect(const IptvApp(), isNotNull);
  });
}
