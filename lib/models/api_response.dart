class ApiResponse<T> {
  final String status;
  final String message;
  final T? data;
  final dynamic errors;

  const ApiResponse({
    required this.status,
    required this.message,
    this.data,
    this.errors,
  });

  bool get isSuccess => status == 'success';

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic rawData)? fromData,
  ) {
    return ApiResponse<T>(
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String? ?? '',
      data: (json['data'] != null && fromData != null)
          ? fromData(json['data'])
          : json['data'] as T?,
      errors: json['errors'],
    );
  }
}
