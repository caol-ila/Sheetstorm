import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sheetstorm_pdf_labeler/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PdfLabelerApp()));
    await tester.pumpAndSettle();
    
    expect(find.text('Sheetstorm PDF Labeler'), findsWidgets);
  });
}

