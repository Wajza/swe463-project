import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_colors.dart';
import 'package:souq_skills/models/message.dart';
class MessageBubble extends StatelessWidget { const MessageBubble({required this.message, super.key}); final Message message; @override Widget build(BuildContext context) => Align(alignment: message.isFromCurrentUser ? Alignment.centerRight : Alignment.centerLeft, child: Container(padding: const EdgeInsets.all(13), margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: message.isFromCurrentUser ? souqGreen : Colors.white, borderRadius: BorderRadius.circular(16)), child: Text(message.text, style: TextStyle(color: message.isFromCurrentUser ? Colors.white : souqNavy)))); }
