import '../app/app.locator.dart';
import '../models/dashboard_charts_model.dart';
import '../models/dashboard_summary_model.dart';
import 'api_service.dart';

class DashboardService {
  final ApiService _apiService;

  DashboardService([ApiService? apiService])
      : _apiService = apiService ?? locator<ApiService>();

  /// Fetch dashboard metrics, low-stock items, and recent transactions
  Future<DashboardSummaryModel> getSummary({
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }
    if (startDate != null && startDate.isNotEmpty && endDate != null && endDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
      queryParams['end_date'] = endDate;
    }

    final response = await _apiService.get<DashboardSummaryModel>(
      '/dashboard/summary',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      fromData: (data) => DashboardSummaryModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiException(message: response.message.isNotEmpty ? response.message : 'Failed to fetch dashboard summary.');
    }
  }

  /// Fetch collections and monthly sales charts
  Future<DashboardChartsModel> getCharts({
    int days = 14,
    int months = 6,
  }) async {
    final response = await _apiService.get<DashboardChartsModel>(
      '/dashboard/charts',
      queryParameters: {
        'days': days,
        'months': months,
      },
      fromData: (data) => DashboardChartsModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiException(message: response.message.isNotEmpty ? response.message : 'Failed to fetch dashboard charts.');
    }
  }
}
