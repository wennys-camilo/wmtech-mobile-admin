/// One entry of the reconciliation log (count-at-store save) for a consignment.
class ConsignmentReconciliationLog {
  const ConsignmentReconciliationLog({
    required this.id,
    required this.loggedAt,
    required this.countAtStore,
    this.notes,
  });

  final String id;
  final String loggedAt;
  final int countAtStore;
  final String? notes;

  static ConsignmentReconciliationLog fromJson(dynamic json) {
    if (json == null || json is! Map) throw FormatException('Invalid reconciliation log json');
    final map = Map<String, dynamic>.from(json);
    final loggedAt = map['loggedAt'] ?? map['logged_at'];
    final countAtStore = map['countAtStore'] ?? map['count_at_store'];
    return ConsignmentReconciliationLog(
      id: map['id'] as String? ?? '',
      loggedAt: loggedAt is String ? loggedAt : (loggedAt?.toString() ?? ''),
      countAtStore: _toInt(countAtStore) ?? 0,
      notes: map['notes'] as String?,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
