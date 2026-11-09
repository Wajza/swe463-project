import 'package:flutter/material.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'category_icon.dart';
class ListingCard extends StatelessWidget { const ListingCard({required this.listing, required this.onTap, this.onSave, super.key}); final SkillListing listing; final VoidCallback onTap; final VoidCallback? onSave; @override Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, child: ListTile(leading: CategoryIcon(category: listing.category), title: Text(listing.title), subtitle: Text('${listing.owner} • ★ ${listing.rating}'), trailing: IconButton(onPressed: onSave, icon: Icon(listing.isSaved ? Icons.favorite : Icons.favorite_border))))); }
