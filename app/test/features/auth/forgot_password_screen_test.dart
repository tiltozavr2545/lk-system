import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amicus/features/auth/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen shows email field and a submit button', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ForgotPasswordScreen())),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Отправить ссылку'), findsOneWidget);
  });
}
