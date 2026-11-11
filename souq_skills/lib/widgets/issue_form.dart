import 'package:flutter/material.dart';

import 'choice_chip_row.dart';
import 'form_section.dart';
import 'souq_button.dart';

/// Shared form for reporting a member, reporting a trade and opening a dispute.
class IssueForm extends StatefulWidget {
  const IssueForm({
    required this.intro,
    required this.reasons,
    required this.submitLabel,
    this.onSubmit,
    this.onSend,
    this.askDetails = false,
    this.busyLabel = 'Sending…',
    super.key,
  }) : assert(onSubmit != null || onSend != null, 'Provide onSubmit or onSend');

  /// The most details a member can add.
  static const maxDetailsLength = 500;

  final String intro;
  final List<String> reasons;
  final String submitLabel;

  /// Called with the chosen reason, straight away.
  final ValueChanged<String>? onSubmit;

  /// Called with the reason and any details. While the future runs the
  /// button shows [busyLabel] and cannot be pressed; the caller handles
  /// its errors. Used instead of [onSubmit] when given.
  final Future<void> Function(String reason, String details)? onSend;

  /// Whether to offer an optional details field.
  final bool askDetails;
  final String busyLabel;

  @override
  State<IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends State<IssueForm> {
  final _details = TextEditingController();
  String? _reason;
  bool _showError = false;
  bool _busy = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String? get _detailsError =>
      _details.text.trim().length > IssueForm.maxDetailsLength
      ? 'Keep the details to ${IssueForm.maxDetailsLength} characters or fewer.'
      : null;

  Future<void> _submit() async {
    if (_busy) return;
    final reason = _reason;
    if (reason == null || _detailsError != null) {
      setState(() => _showError = true);
      return;
    }
    final send = widget.onSend;
    if (send == null) {
      widget.onSubmit!(reason);
      return;
    }
    setState(() => _busy = true);
    try {
      await send(reason, _details.text.trim());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.intro),
      FormSection(
        title: 'Reason',
        errorText: _showError && _reason == null ? 'Choose a reason' : null,
        child: ChoiceChipRow<String?>(
          options: widget.reasons,
          selected: _reason,
          onSelected: (value) => setState(() => _reason = value),
        ),
      ),
      if (widget.askDetails)
        FormSection(
          title: 'Details (optional)',
          child: TextField(
            controller: _details,
            enabled: !_busy,
            minLines: 2,
            maxLines: 5,
            maxLength: IssueForm.maxDetailsLength,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Anything that helps us understand what happened',
              errorText: _showError ? _detailsError : null,
            ),
          ),
        ),
      const SizedBox(height: 20),
      SouqButton(
        label: _busy ? widget.busyLabel : widget.submitLabel,
        onPressed: _busy ? null : _submit,
      ),
    ],
  );
}
