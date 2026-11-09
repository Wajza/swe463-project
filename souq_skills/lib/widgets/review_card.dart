import 'package:flutter/material.dart';
import 'package:souq_skills/models/review.dart';
class ReviewCard extends StatelessWidget { const ReviewCard({required this.review, super.key}); final Review review; @override Widget build(BuildContext context) => Card(child: ListTile(title: Text('${review.authorName} ★ ${review.rating}'), subtitle: Text(review.comment))); }
