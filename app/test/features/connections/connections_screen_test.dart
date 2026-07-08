import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krug/features/connections/connections_screen.dart';

void main() {
  testWidgets(
    'ConnectionsScreen shows invite creation and activation sections',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ConnectionsScreen())),
      );

      expect(find.text('Пригласить'), findsOneWidget);
      expect(find.text('Создать код приглашения'), findsOneWidget);
      expect(find.text('У меня есть код'), findsOneWidget);
      expect(find.text('Код приглашения'), findsOneWidget);
      expect(find.text('Активировать'), findsOneWidget);
    },
  );
}
