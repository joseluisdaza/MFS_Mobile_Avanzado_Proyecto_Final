import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final AppDatabase database;

  ReportsBloc({required this.database}) : super(ReportsInitial()) {
    on<LoadSalesReports>(_onLoadSalesReports);
    on<LoadTodaysReport>(_onLoadTodaysReport);
    on<LoadWeeklyReport>(_onLoadWeeklyReport);
    on<LoadMonthlyReport>(_onLoadMonthlyReport);
    on<LoadYearlyReport>(_onLoadYearlyReport);
    on<LoadReportsByStore>(_onLoadReportsByStore);
    on<LoadReportsBySeller>(_onLoadReportsBySeller);
    on<ClearReports>(_onClearReports);
  }

  Future<void> _onLoadSalesReports(
    LoadSalesReports event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final salesData = await database.getSalesReport(
        startDate: event.startDate,
        endDate: event.endDate,
        storeId: event.storeId,
        sellerId: event.sellerId,
      );

      final summaryData = await database.getSalesSummary(
        startDate: event.startDate,
        endDate: event.endDate,
        storeId: event.storeId,
        sellerId: event.sellerId,
      );

      final reportData = salesData
          .map(
            (data) => SalesReportData(
              purchaseId: data['purchaseId'] as String,
              purchaseDate: data['purchaseDate'] as DateTime,
              storeName: data['storeName'] as String,
              sellerName: data['sellerName'] as String,
              totalAmount: data['totalAmount'] as double,
              itemsCount: data['itemsCount'] as int,
              items: (data['items'] as List)
                  .map(
                    (item) => SalesItemDetail(
                      productName: item['productName'] as String,
                      quantity: item['quantity'] as int,
                      unitPrice: item['unitPrice'] as double,
                      totalPrice: item['totalPrice'] as double,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();

      final summary = ReportSummary(
        totalSales: summaryData['totalSales'] as int,
        totalRevenue: summaryData['totalRevenue'] as double,
        averageTicket: summaryData['averageTicket'] as double,
        totalItems: summaryData['totalItems'] as int,
        topSellingProduct: summaryData['topSellingProduct'] as String,
        topPerformingStore: summaryData['topPerformingStore'] as String,
        topSeller: summaryData['topSeller'] as String,
      );

      emit(
        ReportsLoaded(
          salesData: reportData,
          summary: summary,
          startDate: event.startDate,
          endDate: event.endDate,
          storeId: event.storeId,
          sellerId: event.sellerId,
        ),
      );
    } catch (e) {
      emit(ReportsError(message: 'Error al cargar reportes: $e'));
    }
  }

  Future<void> _onLoadTodaysReport(
    LoadTodaysReport event,
    Emitter<ReportsState> emit,
  ) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    add(LoadSalesReports(startDate: startOfDay, endDate: today));
  }

  Future<void> _onLoadWeeklyReport(
    LoadWeeklyReport event,
    Emitter<ReportsState> emit,
  ) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    add(LoadSalesReports(startDate: startOfDay, endDate: now));
  }

  Future<void> _onLoadMonthlyReport(
    LoadMonthlyReport event,
    Emitter<ReportsState> emit,
  ) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    add(LoadSalesReports(startDate: startOfMonth, endDate: now));
  }

  Future<void> _onLoadYearlyReport(
    LoadYearlyReport event,
    Emitter<ReportsState> emit,
  ) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);

    add(LoadSalesReports(startDate: startOfYear, endDate: now));
  }

  Future<void> _onLoadReportsByStore(
    LoadReportsByStore event,
    Emitter<ReportsState> emit,
  ) async {
    add(LoadSalesReports(storeId: event.storeId));
  }

  Future<void> _onLoadReportsBySeller(
    LoadReportsBySeller event,
    Emitter<ReportsState> emit,
  ) async {
    add(LoadSalesReports(sellerId: event.sellerId));
  }

  Future<void> _onClearReports(
    ClearReports event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsInitial());
  }
}
