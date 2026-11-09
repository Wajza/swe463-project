import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/screens/listings/shared/listing_form_controller.dart';
import 'package:souq_skills/screens/listings/shared/listing_information_fields.dart';
import 'package:souq_skills/screens/listings/shared/skill_details_fields.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';
import 'package:souq_skills/widgets/settings_switch_tile.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class EditListingScreen extends StatefulWidget {
  const EditListingScreen({required this.listingId, super.key});

  final String listingId;

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SkillListing? _original = ListingService().byId(widget.listingId);
  late final _form = ListingFormController(
    _original ?? const SkillListing(ownerId: '', category: ''),
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _save(SkillListing current) {
    if (!_formKey.currentState!.validate()) return;
    ListingService().update(_form.applyTo(current));
    context.back();
    context.showMessage('Listing updated');
  }

  Future<void> _delete() async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Delete listing?',
      message: 'This removes the listing for everyone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    context
      ..back()
      ..back();
    ListingService().delete(widget.listingId);
  }

  @override
  Widget build(BuildContext context) => LiveEntity<SkillListing>(
    find: () => ListingService().byId(widget.listingId),
    builder: (context, listing) => AppPage(
      title: 'Manage listing',
      footer: [
        SouqButton(label: 'Save changes', onPressed: () => _save(listing)),
        SouqButton(
          label: 'Delete listing',
          outlined: true,
          destructive: true,
          onPressed: _delete,
        ),
      ],
      children: [
        Card(
          child: SettingsSwitchTile(
            title: 'Pause listing',
            subtitle: 'Paused listings are hidden from search.',
            value: listing.isPaused,
            onChanged: (value) => ListingService().setPaused(listing.id, value),
          ),
        ),
        const SizedBox(height: 8),
        Form(
          key: _formKey,
          child: Column(
            children: [
              SkillDetailsFields(controller: _form),
              ListingInformationFields(controller: _form),
            ],
          ),
        ),
      ],
    ),
  );
}
