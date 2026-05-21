import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/announcement_form_sheet.dart';

/// `/manager/announcement` — duyuru bottom sheet ile açılır (B5).
class SendAnnouncementScreen extends StatefulWidget {
  const SendAnnouncementScreen({super.key});

  @override
  State<SendAnnouncementScreen> createState() => _SendAnnouncementScreenState();
}

class _SendAnnouncementScreenState extends State<SendAnnouncementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ok = await AnnouncementFormSheet.show(context);
      if (!mounted) return;
      context.pop(ok == true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
