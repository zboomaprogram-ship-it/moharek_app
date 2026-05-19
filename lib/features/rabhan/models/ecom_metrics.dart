class EcomMetrics {
  final double totalSales, prevSales, roas, prevRoas, conversionRate, netProfit, adSpend;
  final int ordersCount, prevOrders;
  final DateTime periodStart, periodEnd;

  double get salesDeltaPercent =>
    prevSales == 0 ? 0 : ((totalSales - prevSales) / prevSales) * 100;
  double get ordersDeltaPercent =>
    prevOrders == 0 ? 0 : ((ordersCount - prevOrders) / prevOrders) * 100;
  double get roasDeltaPercent =>
    prevRoas == 0 ? 0 : ((roas - prevRoas) / prevRoas) * 100;
  double get conversionDeltaPercent => 0; // compute from prev if available

  EcomMetrics({
    required this.totalSales,
    required this.prevSales,
    required this.ordersCount,
    required this.prevOrders,
    required this.roas,
    required this.prevRoas,
    required this.conversionRate,
    required this.netProfit,
    required this.adSpend,
    required this.periodStart,
    required this.periodEnd,
  });

  factory EcomMetrics.fromJson(Map<String, dynamic> j) => EcomMetrics(
    totalSales: (j['total_sales'] ?? 0).toDouble(),
    prevSales: (j['prev_sales'] ?? 0).toDouble(),
    ordersCount: j['orders_count'] ?? 0,
    prevOrders: j['prev_orders'] ?? 0,
    roas: (j['roas'] ?? 0).toDouble(),
    prevRoas: (j['prev_roas'] ?? 0).toDouble(),
    conversionRate: (j['conversion_rate'] ?? 0).toDouble(),
    netProfit: (j['net_profit'] ?? 0).toDouble(),
    adSpend: (j['ad_spend'] ?? 0).toDouble(),
    periodStart: DateTime.parse(j['period_start'].toString()),
    periodEnd: DateTime.parse(j['period_end'].toString()),
  );
}
