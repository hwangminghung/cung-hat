class BoostCreditSummary {
  const BoostCreditSummary({
    required this.availableCount,
    this.nextExpiringAt,
  });

  factory BoostCreditSummary.fromJson(Map<String, dynamic> json) =>
      BoostCreditSummary(
        availableCount: json['available_count'] as int? ?? 0,
        nextExpiringAt: json['next_expiring_at'] as String?,
      );

  final int availableCount;
  final String? nextExpiringAt;
}
