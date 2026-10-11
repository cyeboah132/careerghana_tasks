import 'package:flutter_test/flutter_test.dart';
import 'package:talklike/data.dart';
import 'package:talklike/main.dart';

void main() {
  testWidgets('TalkLike app starts', (WidgetTester tester) async {
    final profile = await Profile.load();

    await tester.pumpWidget(TalkLikeApp(initial: profile));

    expect(find.byType(TalkLikeApp), findsOneWidget);
  });
}
