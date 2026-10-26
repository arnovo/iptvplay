import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_play/ui/widgets/tv_focusable.dart';

void main() {
  group('TvFocusable Widget Tests', () {
    testWidgets('Renders child correctly and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvFocusable(
              onPressed: () => tapped = true,
              child: const Text('Canal 1'),
            ),
          ),
        ),
      );

      expect(find.text('Canal 1'), findsOneWidget);

      await tester.tap(find.text('Canal 1'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('Responds to remote control Select / Enter key events', (tester) async {
      int pressCount = 0;
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvFocusable(
              focusNode: focusNode,
              autofocus: true,
              onPressed: () => pressCount++,
              child: const Text('Elemento Enfocable'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      // Simulate remote control "Select" button
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(pressCount, 1);

      // Simulate remote control "Enter" button
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressCount, 2);

      // Simulate keyboard / remote "Space" button
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(pressCount, 3);

      focusNode.dispose();
    });

    testWidgets('Builder provides focus state to customize child visual appearance', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvFocusable(
              focusNode: focusNode,
              builder: (context, isFocused, isHovered) {
                return Text(isFocused ? 'ENFOCADO' : 'DESENFOCADO');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('DESENFOCADO'), findsOneWidget);

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('ENFOCADO'), findsOneWidget);

      focusNode.dispose();
    });
  });
}
