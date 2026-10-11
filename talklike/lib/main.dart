import 'package:flutter/material.dart';
import 'data.dart';
import 'theme.dart';
import 'streak.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Streak.instance.init();
  runApp(TalkLikeApp(initial: await Profile.load()));
}

class TalkLikeApp extends StatefulWidget {
  final Profile? initial;
  const TalkLikeApp({super.key, this.initial});

  @override
  State<TalkLikeApp> createState() => _TalkLikeAppState();
}

class _TalkLikeAppState extends State<TalkLikeApp> {
  Profile? profile;

  @override
  void initState() {
    super.initState();
    profile = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalkLike',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      home: profile == null
          ? OnboardingScreen(onDone: (p) async {
              await p.save();
              setState(() => profile = p);
            })
          : HomeScreen(
              profile: profile!,
              onReset: () async {
                await Profile.clear();
                setState(() => profile = null);
              },
            ),
    );
  }
}
