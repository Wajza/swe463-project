import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_colors.dart';
class SouqLogo extends StatelessWidget { const SouqLogo({this.small = false, super.key}); final bool small; @override Widget build(BuildContext context) => Container(width: small ? 64 : 136, height: small ? 64 : 136, decoration: BoxDecoration(color: souqGreen, borderRadius: BorderRadius.circular(small ? 20 : 42)), child: Icon(Icons.notes_rounded, color: souqMint, size: small ? 34 : 70)); }
