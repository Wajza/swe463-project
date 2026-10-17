class Trade {
  const Trade({
    required this.offeredSkill,
    required this.requestedSkill,
    this.isComplete = false,
  });

  final String offeredSkill;
  final String requestedSkill;
  final bool isComplete;
}
