
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Core/Utils/App Colors.dart';

import 'Features/Home/view/presentation/home_view.dart';
import 'bloc_observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = MyBlocObserver();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Widget widget;

  runApp(const MyApp(widget: OnboardingView()));
}

class MyApp extends StatelessWidget {
  final Widget widget;
  const MyApp({super.key, required this.widget});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColorsData.white,
          platform: TargetPlatform.iOS,
          primaryColor: AppColorsData.primarySwatch,
          canvasColor: Colors.transparent,
          fontFamily: "Urbanist",
          iconTheme: const IconThemeData(color: AppColorsData.primaryColor, size: 25),
          primarySwatch: Colors.orange,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColorsData.white,
            toolbarHeight: 50,
            elevation: 0,
            surfaceTintColor: AppColorsData.white,
            centerTitle: true,
          ),
        ),
        home: widget
    );
  }
}
