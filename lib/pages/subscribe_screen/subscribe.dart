import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:memory_box/pages/subscribe_screen/bloc/subscribe_bloc.dart';
import 'package:memory_box/styles/colors.dart';
import 'package:memory_box/styles/ellipse_clipper.dart';
import 'package:memory_box/styles/fonts.dart';

import '../../widgets/drawer.dart';

class SubscribePage extends StatelessWidget {
  const SubscribePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionBloc(),
      child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          return const SubscribeView();
        },
      ),
    );
  }
}

class SubscribeView extends StatefulWidget {
  const SubscribeView({super.key});

  @override
  State<SubscribeView> createState() => _SubscribeViewState();
}

Future<void> checkAndUpdateSubscription(
    BuildContext context, Duration subscriptionDuration) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
  final docSnapshot = await userDoc.get();

  if (docSnapshot.exists && docSnapshot.data() != null) {
    final data = docSnapshot.data()!;
    final expirationDate = data['subscriptionExpirationDate']?.toDate();

    if (expirationDate != null && expirationDate.isAfter(DateTime.now())) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'У вас уже есть подписка до ${expirationDate.toString()}')),
      );
      return;
    }
  }

  final newExpirationDate = DateTime.now().add(subscriptionDuration);
  await userDoc.set({
    'subscriptionActive': true,
    'subscriptionExpirationDate': newExpirationDate,
  }, SetOptions(merge: true));

  // ignore: use_build_context_synchronously
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text(
            'Подписка успешно оплачена! До: ${newExpirationDate.toString()}')),
  );
}

class _SubscribeViewState extends State<SubscribeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: collectionsColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, size: 36),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        centerTitle: true,
        title: const Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 0.0),
              child: Text(
                'Подписка',
                style: graysize36,
              ),
            ),
          ],
        ),
      ),
      drawer: const CustomDrawer(),
      body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          return Stack(
            children: [
              Container(
                color: const Color(0xFFF6F6F6),
              ),
              FractionallySizedBox(
                heightFactor: 0.4,
                child: ClipPath(
                  clipper: EllipseClipper(),
                  child: Container(
                    color: collectionsColor,
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Расширь возможности',
                    style: graysize16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 50, 5, 10),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: grayTextColor,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        offset: Offset(0, 4),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 30.h),
                      const Text('Выбери подписку', style: dark24),
                      SizedBox(height: 30.h),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSubscriptionOption(
                              context,
                              '300грн',
                              'в месяц',
                              state.selectedPlan == 'monthly',
                              () => BlocProvider.of<SubscriptionBloc>(context)
                                  .add(
                                SelectMonthly(),
                              ),
                            ),
                            _buildSubscriptionOption(
                              context,
                              '1800грн',
                              'в год',
                              state.selectedPlan == 'yearly',
                              () => BlocProvider.of<SubscriptionBloc>(context)
                                  .add(SelectYearly()),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 25.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.0.w),
                        child: _buildSubscriptionBenefits(),
                      ),
                      SizedBox(height: 25.h),
                      ElevatedButton(
                        onPressed: () {
                          if (state.selectedPlan == 'monthly') {
                            checkAndUpdateSubscription(
                              context,
                              const Duration(days: 30),
                            );
                          } else if (state.selectedPlan == 'yearly') {
                            checkAndUpdateSubscription(
                              context,
                              const Duration(days: 365),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1B488),
                          minimumSize: Size(300.w, 50.h),
                        ),
                        child: Text(
                          state.selectedPlan == 'monthly'
                              ? 'Подписаться на месяц'
                              : 'Подписаться на год',
                          style: graysize18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionOption(
    BuildContext context,
    String price,
    String period,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180.w,
        height: 220.h,
        decoration: BoxDecoration(
          color: grayTextColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(price, style: dark24),
              SizedBox(height: 10.h),
              Text(period, style: dark16),
              SizedBox(height: 30.h),
              SvgPicture.asset(
                isSelected
                    ? 'assets/img/icon/svg/selected.svg'
                    : 'assets/img/icon/svg/circlesel.svg',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBenefits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Что дает подписка:', style: dark20),
        SizedBox(height: 20.h),
        Row(
          children: [
            SvgPicture.asset('assets/img/icon/svg/cil_infinity.svg'),
            SizedBox(width: 6.w),
            const Text('Неограниченая память'),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            SvgPicture.asset('assets/img/icon/svg/cil_cloud-upload.svg'),
            SizedBox(width: 6.w),
            const Text('Все файлы хранятся в облаке'),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            SvgPicture.asset('assets/img/icon/svg/Paper Download.svg'),
            SizedBox(width: 6.w),
            const Text('Возможность скачивать без ограничений'),
          ],
        ),
      ],
    );
  }
}
