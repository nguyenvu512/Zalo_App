import 'package:flutter/material.dart';
import 'package:zalo_mobile_app/features/conversation/screens/conversation_list.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: const ConversationList(),

    );
  }
}