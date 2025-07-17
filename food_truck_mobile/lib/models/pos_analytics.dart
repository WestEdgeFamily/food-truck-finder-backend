/// Model representing POS analytics data
class PosAnalytics {
  final String period;
  final double totalRevenue;
  final int totalTransactions;
  final double averageTransactionValue;
  final List<Map<String, dynamic>> topLocations;
  final List<Map<String, dynamic>> topItems;
  final Map<DateTime, double> salesByDate;
  final Map<String, int> transactionsByLocation;

  PosAnalytics({
    required this.period,
    required this.totalRevenue,
    required this.totalTransactions,
    required this.averageTransactionValue,
    required this.topLocations,
    required this.topItems,
    required this.salesByDate,
    required this.transactionsByLocation,
  });

  /// Create empty analytics
  factory PosAnalytics.empty(String period) {
    return PosAnalytics(
      period: period,
      totalRevenue: 0,
      totalTransactions: 0,
      averageTransactionValue: 0,
      topLocations: [],
      topItems: [],
      salesByDate: {},
      transactionsByLocation: {},
    );
  }

  /// Get revenue growth percentage
  double getRevenueGrowth(PosAnalytics previousPeriod) {
    if (previousPeriod.totalRevenue == 0) return 0;
    return ((totalRevenue - previousPeriod.totalRevenue) / previousPeriod.totalRevenue) * 100;
  }

  /// Get transaction growth percentage
  double getTransactionGrowth(PosAnalytics previousPeriod) {
    if (previousPeriod.totalTransactions == 0) return 0;
    return ((totalTransactions - previousPeriod.totalTransactions) / previousPeriod.totalTransactions) * 100;
  }

  /// Get best performing location
  Map<String, dynamic>? getBestLocation() {
    return topLocations.isNotEmpty ? topLocations.first : null;
  }

  /// Get best selling item
  Map<String, dynamic>? getBestSellingItem() {
    return topItems.isNotEmpty ? topItems.first : null;
  }

  /// Get daily average revenue
  double getDailyAverageRevenue() {
    if (salesByDate.isEmpty) return 0;
    return totalRevenue / salesByDate.length;
  }

  /// Get peak sales day
  MapEntry<DateTime, double>? getPeakSalesDay() {
    if (salesByDate.isEmpty) return null;
    return salesByDate.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  /// Get insights and recommendations
  List<String> getInsights() {
    List<String> insights = [];

    // Revenue insights
    if (totalRevenue > 0) {
      insights.add('Total revenue: \$${totalRevenue.toStringAsFixed(2)}');
      insights.add('Average transaction: \$${averageTransactionValue.toStringAsFixed(2)}');
    }

    // Location insights
    if (topLocations.isNotEmpty) {
      final bestLocation = topLocations.first;
      insights.add('Best location: ${bestLocation['location']} (${bestLocation['percentage']}% of sales)');
      
      // Recommendation for underperforming locations
      if (topLocations.length > 3) {
        final worstLocation = topLocations.last;
        if (double.parse(worstLocation['percentage']) < 10) {
          insights.add('Consider spending less time at ${worstLocation['location']} (only ${worstLocation['percentage']}% of sales)');
        }
      }
    }

    // Item insights
    if (topItems.isNotEmpty) {
      final top3Items = topItems.take(3).map((item) => item['item']).join(', ');
      insights.add('Top sellers: $top3Items');
      
      // Recommendation for promoting items
      if (topItems.length > 5) {
        final bottomItems = topItems.skip(topItems.length - 3).map((item) => item['item']).toList();
        insights.add('Consider promoting or removing: ${bottomItems.join(', ')}');
      }
    }

    // Day of week insights
    if (salesByDate.isNotEmpty) {
      final peakDay = getPeakSalesDay();
      if (peakDay != null) {
        final dayName = _getDayName(peakDay.key.weekday);
        insights.add('Best day: $dayName (\$${peakDay.value.toStringAsFixed(2)})');
      }
    }

    return insights;
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  Map<String, dynamic> toJson() => {
    'period': period,
    'totalRevenue': totalRevenue,
    'totalTransactions': totalTransactions,
    'averageTransactionValue': averageTransactionValue,
    'topLocations': topLocations,
    'topItems': topItems,
    'salesByDate': salesByDate.map((k, v) => MapEntry(k.toIso8601String(), v)),
    'transactionsByLocation': transactionsByLocation,
  };
}