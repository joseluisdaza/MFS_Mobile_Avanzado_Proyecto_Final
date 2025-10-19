import 'package:equatable/equatable.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final List<SalesReportData> salesData;
  final ReportSummary summary;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? storeId;
  final int? sellerId;

  const ReportsLoaded({
    required this.salesData,
    required this.summary,
    this.startDate,
    this.endDate,
    this.storeId,
    this.sellerId,
  });

  @override
  List<Object?> get props => [
    salesData,
    summary,
    startDate,
    endDate,
    storeId,
    sellerId,
  ];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError({required this.message});

  @override
  List<Object> get props => [message];
}

// Clases de datos para los reportes
class SalesReportData {
  final String purchaseId;
  final DateTime purchaseDate;
  final String storeName;
  final String sellerName;
  final double totalAmount;
  final int itemsCount;
  final List<SalesItemDetail> items;

  const SalesReportData({
    required this.purchaseId,
    required this.purchaseDate,
    required this.storeName,
    required this.sellerName,
    required this.totalAmount,
    required this.itemsCount,
    required this.items,
  });
}

class SalesItemDetail {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const SalesItemDetail({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class ReportSummary {
  final int totalSales;
  final double totalRevenue;
  final double averageTicket;
  final int totalItems;
  final String topSellingProduct;
  final String topPerformingStore;
  final String topSeller;

  const ReportSummary({
    required this.totalSales,
    required this.totalRevenue,
    required this.averageTicket,
    required this.totalItems,
    required this.topSellingProduct,
    required this.topPerformingStore,
    required this.topSeller,
  });
}
