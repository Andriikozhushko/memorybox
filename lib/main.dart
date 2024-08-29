import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:memory_box/blocs/buttomnavbar_cubit/buttombar_cubit.dart';
import 'package:memory_box/blocs/miniplayer_offset_cubit/miniplayer_cubit.dart';
import 'package:memory_box/blocs/navigation_bloc/navigation_bloc.dart';
import 'package:memory_box/pages/auth_screens/you_amazing.dart';
import 'package:memory_box/pages/collection_page/cubit/selected_cubit.dart';
import 'package:memory_box/pages/home_screen/homescreen.dart';
import 'package:memory_box/pages/recorder_screen/cubit/records_cubit.dart';
import 'package:memory_box/pages/subscribe_screen/bloc/subscribe_bloc.dart';
import 'package:memory_box/widgets/splash_screen.dart';

import 'blocs/audio_cubit/audio_cubit.dart';
import 'blocs/auth_bloc/auth_bloc.dart';
import 'blocs/auth_bloc/auth_state.dart';
import 'pages/search_screen/bloc/search_bloc.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => AudioCubit()),
        BlocProvider(create: (context) => SelectedAudioCubit()),
        BlocProvider(create: (context) => SubscriptionBloc()),
        BlocProvider(create: (context) => RecordPageCubit()),
        BlocProvider(create: (context) => BottomNavBarVisibilityCubit()),
        BlocProvider(create: (context) => OffsetCubit()),
        BlocProvider(
            create: (context) => NavigationBloc(onNavigate: (index) {})),
        BlocProvider(
            create: (context) => AudioBloc(FirebaseFirestore.instance)),
      ],
      child: ScreenUtilInit(
        designSize: const Size(411, 797),
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'TTNorms',
            ),
            navigatorKey: navigatorKey,
            routes: {
              '/home': (context) => const HomeScreen(),
              '/asplashScreen': (context) => const AuthenticatedSplashScreen(),
              '/splashScreen': (context) => const SplashScreen(),
            },
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoggedInState) {
                  return const AuthenticatedSplashScreen();
                } else if (state is AuthLoggedOutState) {
                  return const UnauthenticatedSplashScreen();
                } else {
                  return const SplashScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
