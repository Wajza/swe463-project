import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/services/location_service.dart';

import 'select_field.dart';

/// Picks a city from the list or from the device's location.
class LocationField extends StatefulWidget {
  const LocationField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  bool _isLocating = false;

  Future<void> _useDeviceLocation() async {
    setState(() => _isLocating = true);
    try {
      final city = await LocationService().currentCity();
      if (mounted) widget.onChanged(city);
    } on LocationUnavailable catch (error) {
      if (mounted) context.showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SelectField<String>(
        label: 'Location',
        value: widget.value.isEmpty ? null : widget.value,
        options: AppOptions.cities,
        onChanged: widget.onChanged,
      ),
      TextButton.icon(
        onPressed: _isLocating ? null : _useDeviceLocation,
        icon: _isLocating
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: const Text('Use my current location'),
      ),
    ],
  );
}
