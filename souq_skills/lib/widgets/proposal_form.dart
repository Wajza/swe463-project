import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/category_config.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/services/wallet_service.dart';

import 'choice_chip_row.dart';
import 'form_section.dart';
import 'select_field.dart';
import 'souq_button.dart';

enum _OfferType {
  skill('My skill'),
  credits('Credits');

  const _OfferType(this.label);
  final String label;
}

/// Trade terms chosen entirely from selections. A member can offer one of
/// their skills, or wallet credits if they don't have the skill wanted.
class ProposalForm extends StatefulWidget {
  const ProposalForm({
    required this.initial,
    required this.mySkills,
    required this.theirSkills,
    required this.submitLabel,
    required this.onSubmit,
    super.key,
  });

  final TradeProposal initial;
  final List<String> mySkills;
  final List<String> theirSkills;
  final String submitLabel;
  final ValueChanged<TradeProposal> onSubmit;

  @override
  State<ProposalForm> createState() => _ProposalFormState();
}

class _ProposalFormState extends State<ProposalForm> {
  late TradeProposal _proposal = widget.initial;
  late _OfferType _offerType = widget.initial.creditsOffered > 0
      ? _OfferType.credits
      : _OfferType.skill;
  // Credits already held by this trade can be offered again in a counter.
  late final int _availableCredits = WalletService().availableCredits(
    excludingTradeId: widget.initial.tradeId,
  );
  bool _showErrors = false;

  bool get _isOfferingCredits => _offerType == _OfferType.credits;
  String get _offered => _proposal.offeredSkill;
  String get _requested => _proposal.requestedSkill;

  List<int> get _affordableAmounts => AppOptions.creditAmounts
      .where((amount) => amount <= _availableCredits)
      .toList();

  String? get _offeredError {
    if (_isOfferingCredits) {
      return _proposal.creditsOffered == 0 ? 'Choose an amount' : null;
    }
    return _offered.isEmpty ? 'Choose a skill to offer' : null;
  }

  String? get _requestedError {
    if (_requested.isEmpty) return 'Choose a skill you want';
    if (_requested == _offered) return 'Choose two different skills';
    return null;
  }

  List<String> _options(List<String> preferred) =>
      preferred.isEmpty ? CategoryConfig.allSkills : preferred;

  void _update(TradeProposal proposal) => setState(() => _proposal = proposal);

  void _changeOfferType(_OfferType type) {
    setState(() => _offerType = type);
    _update(
      _proposal.copyWith(
        offeredSkill: type == _OfferType.credits
            ? ''
            : widget.mySkills.firstOrNull ?? '',
        creditsOffered: type == _OfferType.credits
            ? _affordableAmounts.firstOrNull ?? 0
            : 0,
      ),
    );
  }

  void _submit() {
    if (_offeredError != null || _requestedError != null) {
      setState(() => _showErrors = true);
      return;
    }
    widget.onSubmit(_proposal);
  }

  Widget _buildSkillOffer() => SelectField<String>(
    label: 'Skill you offer',
    value: _offered.isEmpty ? null : _offered,
    options: _options(widget.mySkills),
    errorText: _showErrors ? _offeredError : null,
    onChanged: (skill) => _update(_proposal.copyWith(offeredSkill: skill)),
  );

  Widget _buildCreditOffer() {
    final amounts = _affordableAmounts;
    return FormSection(
      title: 'Credits to offer ($_availableCredits available)',
      errorText: _showErrors ? _offeredError : null,
      child: amounts.isEmpty
          ? const Text('You don’t have enough credits right now.')
          : ChoiceChipRow<int>(
              options: amounts,
              selected: _proposal.creditsOffered,
              labelOf: (amount) => '$amount credits',
              onSelected: (amount) =>
                  _update(_proposal.copyWith(creditsOffered: amount)),
            ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FormSection(
        title: 'You offer',
        child: ChoiceChipRow<_OfferType>(
          options: _OfferType.values,
          selected: _offerType,
          labelOf: (type) => type.label,
          onSelected: _changeOfferType,
        ),
      ),
      const SizedBox(height: 14),
      if (_isOfferingCredits) _buildCreditOffer() else _buildSkillOffer(),
      if (_isOfferingCredits) const SizedBox(height: 14),
      SelectField<String>(
        label: 'You want',
        value: _requested.isEmpty ? null : _requested,
        options: _options(widget.theirSkills),
        errorText: _showErrors ? _requestedError : null,
        onChanged: (skill) =>
            _update(_proposal.copyWith(requestedSkill: skill)),
      ),
      FormSection(
        title: 'Session length',
        child: ChoiceChipRow<int>(
          options: {
            ...AppOptions.sessionLengths,
            _proposal.sessionsMinutes,
          }.toList(),
          selected: _proposal.sessionsMinutes,
          labelOf: (minutes) => '$minutes min',
          onSelected: (value) =>
              _update(_proposal.copyWith(sessionsMinutes: value)),
        ),
      ),
      FormSection(
        title: 'Delivery',
        child: ChoiceChipRow<String>(
          options: AppOptions.deliveryMethods,
          selected: _proposal.deliveryMethod,
          onSelected: (value) =>
              _update(_proposal.copyWith(deliveryMethod: value)),
        ),
      ),
      const SizedBox(height: 20),
      SouqButton(label: widget.submitLabel, onPressed: _submit),
    ],
  );
}
