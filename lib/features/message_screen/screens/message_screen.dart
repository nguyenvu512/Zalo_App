import 'package:flutter/material.dart';
import 'package:zalo_mobile_app/features/conversation/screens/conversation_list.dart';
import 'package:zalo_mobile_app/features/message_screen/screens/message_screen_appbar.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MessageScreenAppbar(),
      body: const ConversationList(),

    );
  }
}