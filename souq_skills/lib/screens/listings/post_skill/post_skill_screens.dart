import '../../../providers/listing_provider.dart';
import 'published_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../../providers/profile_provider.dart';

class PostSkillSkillsScreen extends StatefulWidget {
  const PostSkillSkillsScreen({super.key});

  @override
  State<PostSkillSkillsScreen> createState() => _PostSkillSkillsScreenState();
}

class _PostSkillSkillsScreenState extends State<PostSkillSkillsScreen> {
  final _skillsKey = GlobalKey<FormState>();
  final _detailsKey = GlobalKey<FormState>();

  final _offered = TextEditingController();
  final _wanted = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _availability = TextEditingController();

  int _step = 0;
  String? _category;
  bool _onlineOnly = false;
  bool _womenOnly = false;

  static const _categories = [
    'Creative & Design',
    'Languages',
    'Business',
    'Technology',
    'Teaching',
    'Cooking',
    'Repairs',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _location.text = context.read<ProfileProvider>().profile.city;
  }

  @override
  void dispose() {
    _offered.dispose();
    _wanted.dispose();
    _description.dispose();
    _location.dispose();
    _availability.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please complete this field.';
    }
    return null;
  }

  void _continue() {
    final form = _step == 0 ? _skillsKey : _detailsKey;
    if (form.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => _step++);
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _step > 0) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_step == 2 ? 'Preview listing' : 'Post a skill'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: _step == 0
              ? null
              : IconButton(
                  tooltip: 'Back',
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back),
                ),
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              color: souqGreen,
              backgroundColor: const Color(0xFFE3E8DF),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: switch (_step) {
                      0 => _skillsForm(),
                      1 => _detailsForm(),
                      _ => _preview(),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String label, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: souqGreen,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _skillsForm() {
    return Form(
      key: _skillsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('SKILLS · 1 OF 3', 'What will you exchange?'),
          const Text('Be specific so the right people can find you.'),
          const SizedBox(height: 24),
          TextFormField(
            controller: _offered,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Skill you offer',
              hintText: 'e.g. Product photography',
              prefixIcon: Icon(Icons.auto_awesome),
            ),
            validator: _required,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Icon(Icons.swap_horiz, color: souqLavender),
          ),
          TextFormField(
            controller: _wanted,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: "Skill you're looking for",
              hintText: 'e.g. Conversational Spanish',
              prefixIcon: Icon(Icons.search),
            ),
            validator: _required,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Category'),
            hint: const Text('Choose a category'),
            items: [
              for (final category in _categories)
                DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ),
            ],
            onChanged: (value) => setState(() => _category = value),
            validator: _required,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _continue,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _detailsForm() {
    return Form(
      key: _detailsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('DETAILS · 2 OF 3', 'Help people say yes'),
          TextFormField(
            controller: _description,
            minLines: 4,
            maxLines: 6,
            maxLength: 280,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Share your experience and what a session could look like.',
              alignLabelWithHint: true,
            ),
            validator: _required,
          ),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Online only'),
              subtitle: const Text('Meet remotely instead of at a location'),
              value: _onlineOnly,
              onChanged: (value) => setState(() => _onlineOnly = value),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _location,
            enabled: !_onlineOnly,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: 'Location',
              helperText: _onlineOnly ? 'Not required for online sessions.' : null,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            validator: (value) => _onlineOnly ? null : _required(value),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _availability,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Availability',
              hintText: 'e.g. Weekends, after 4 PM',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Women only'),
              value: _womenOnly,
              onChanged: (value) => setState(() => _womenOnly = value),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _continue,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview listing'),
          ),
        ],
      ),
    );
  }

  void _publish() {
    try {
      final listing = context.read<ListingProvider>().publish(
        owner: context.read<ProfileProvider>().profile,
        offered: _offered.text,
        wanted: _wanted.text,
        category: _category ?? '',
        description: _description.text,
        location: _location.text,
        availability: _availability.text,
        onlineOnly: _onlineOnly,
        womenOnly: _womenOnly,
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => PublishedScreen(listing: listing),
        ),
        (_) => false,
      );
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    }
  }

  Widget _preview() {
    final profile = context.watch<ProfileProvider>().profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'This is how your listing will appear',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 170,
                color: const Color(0xFFD0EADD),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome,
                  size: 64,
                  color: souqGreen,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: souqGreen,
                          child: Text(
                            profile.initials,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            profile.shownName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (profile.phoneVerified)
                          const Icon(
                            Icons.verified,
                            color: souqGreen,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _offered.text.trim(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(_category ?? ''),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECF0E9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('I offer: ${_offered.text.trim()}'),
                          const SizedBox(height: 8),
                          Text("I'd like: ${_wanted.text.trim()}"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(_description.text.trim()),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _onlineOnly
                            ? Icons.videocam_outlined
                            : Icons.location_on_outlined,
                      ),
                      title: Text(
                        _onlineOnly ? 'Online only' : _location.text.trim(),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(_availability.text.trim()),
                    ),
                    if (_womenOnly)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(label: Text('Women only')),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedButton(
              onPressed: _back,
              child: const Text('Edit'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _publish,
                child: const Text('Publish'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
