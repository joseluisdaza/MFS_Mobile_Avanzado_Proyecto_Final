import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSalesReports extends ReportsEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? storeId;
  final int? sellerId;

  const LoadSalesReports({
    this.startDate,
    this.endDate,
    this.storeId,
    this.sellerId,
  });

  @override
  List<Object?> get props => [startDate, endDate, storeId, sellerId];
}

class LoadTodaysReport extends ReportsEvent {}

class LoadWeeklyReport extends ReportsEvent {}

class LoadMonthlyReport extends ReportsEvent {}

class LoadYearlyReport extends ReportsEvent {}

class LoadReportsByStore extends ReportsEvent {
  final int storeId;

  const LoadReportsByStore({required this.storeId});

  @override
  List<Object?> get props => [storeId];
}

class LoadReportsBySeller extends ReportsEvent {
  final int sellerId;

  const LoadReportsBySeller({required this.sellerId});

  @override
  List<Object?> get props => [sellerId];
}

class ClearReports extends ReportsEvent {}
