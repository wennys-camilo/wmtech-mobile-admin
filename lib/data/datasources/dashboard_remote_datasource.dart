import '../../core/api_client.dart';

class DashboardStats {
  const DashboardStats({
    required this.newOrders,
    required this.toShip,
    required this.shipped,
    required this.delivered,
    required this.cancelled,
    required this.cancellationRequested,
  });

  final int newOrders;
  final int toShip;
  final int shipped;
  final int delivered;
  final int cancelled;
  final int cancellationRequested;

  static DashboardStats fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return const DashboardStats(
        newOrders: 0,
        toShip: 0,
        shipped: 0,
        delivered: 0,
        cancelled: 0,
        cancellationRequested: 0,
      );
    }
    final map = Map<String, dynamic>.from(json);
    int v(String key) {
      final x = map[key];
      return x is num ? x.toInt() : 0;
    }
    return DashboardStats(
      newOrders: v('newOrders'),
      toShip: v('toShip'),
      shipped: v('shipped'),
      delivered: v('delivered'),
      cancelled: v('cancelled'),
      cancellationRequested: v('cancellationRequested'),
    );
  }
}

class DashboardRemoteDatasource {
  DashboardRemoteDatasource([ApiClient? apiClient])
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<DashboardStats> getStats() async {
    return _api.get<DashboardStats>('/dashboard', DashboardStats.fromJson);
  }
}
