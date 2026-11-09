import 'package:flutter/material.dart';
import 'package:souq_skills/models/skill_listing.dart';

/// Holds the editable values of a listing across its form fields.
class ListingFormController {
  ListingFormController(SkillListing listing)
    : title = TextEditingController(text: listing.title),
      offers = TextEditingController(text: listing.offers),
      description = TextEditingController(text: listing.description),
      wants = TextEditingController(text: listing.wants),
      availability = TextEditingController(text: listing.availability),
      minutes = TextEditingController(text: '${listing.sessionsMinutes}'),
      city = listing.city,
      onlineOnly = listing.onlineOnly,
      womenOnly = listing.womenOnly;

  final TextEditingController title;
  final TextEditingController offers;
  final TextEditingController description;
  final TextEditingController wants;
  final TextEditingController availability;
  final TextEditingController minutes;
  String city;
  bool onlineOnly;
  bool womenOnly;

  SkillListing applyTo(SkillListing listing) => listing.copyWith(
    title: title.text.trim(),
    offers: offers.text.trim(),
    description: description.text.trim(),
    wants: wants.text.trim(),
    availability: availability.text.trim(),
    sessionsMinutes: int.tryParse(minutes.text.trim()),
    city: city,
    onlineOnly: onlineOnly,
    womenOnly: womenOnly,
  );

  void dispose() {
    title.dispose();
    offers.dispose();
    description.dispose();
    wants.dispose();
    availability.dispose();
    minutes.dispose();
  }
}
