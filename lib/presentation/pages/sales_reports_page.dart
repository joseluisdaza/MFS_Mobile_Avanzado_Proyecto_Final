import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/reports/reports_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/reports/reports_event.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/reports/reports_state.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/stores/stores_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/stores/stores_state.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/users/users_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/users/users_state.dart';

class SalesReportsPage extends StatefulWidget {
  const SalesReportsPage({super.key});

  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedStoreId;
  int? _selectedSellerId;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    // Cargar reporte del día por defecto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsBloc>().add(LoadTodaysReport());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Ventas'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Panel de filtros
          _buildFiltersPanel(),

          // Contenido principal
          Expanded(
            child: BlocBuilder<ReportsBloc, ReportsState>(
              builder: (context, state) {
                if (state is ReportsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ReportsLoaded) {
                  return _buildReportsContent(state);
                } else if (state is ReportsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ReportsBloc>().add(LoadTodaysReport());
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: Text(
                      'Selecciona un período para ver los reportes',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Botones de filtros rápidos
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<ReportsBloc>().add(LoadTodaysReport());
                  },
                  icon: const Icon(Icons.today, size: 18),
                  label: const Text('Hoy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<ReportsBloc>().add(LoadWeeklyReport());
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text('Semana'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<ReportsBloc>().add(LoadMonthlyReport());
                  },
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Mes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<ReportsBloc>().add(LoadYearlyReport());
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Año'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filtros personalizados
          ExpansionTile(
            title: const Text('Filtros Avanzados'),
            leading: const Icon(Icons.filter_list),
            children: [
              const SizedBox(height: 8),

              // Rango de fechas
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Fecha Inicio'),
                      subtitle: Text(
                        _startDate != null
                            ? _dateFormat.format(_startDate!)
                            : 'Seleccionar',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectStartDate(),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Fecha Fin'),
                      subtitle: Text(
                        _endDate != null
                            ? _dateFormat.format(_endDate!)
                            : 'Seleccionar',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectEndDate(),
                    ),
                  ),
                ],
              ),

              // Filtros por tienda y vendedor
              Row(
                children: [
                  Expanded(child: _buildStoreDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSellerDropdown()),
                ],
              ),

              const SizedBox(height: 16),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ReportsBloc>().add(
                        LoadSalesReports(
                          startDate: _startDate,
                          endDate: _endDate,
                          storeId: _selectedStoreId,
                          sellerId: _selectedSellerId,
                        ),
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Aplicar Filtros'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _selectedStoreId = null;
                        _selectedSellerId = null;
                      });
                      context.read<ReportsBloc>().add(LoadTodaysReport());
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreDropdown() {
    return BlocBuilder<StoresBloc, StoresState>(
      builder: (context, state) {
        if (state is StoresLoaded) {
          return DropdownButtonFormField<int>(
            value: _selectedStoreId,
            decoration: const InputDecoration(
              labelText: 'Tienda',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Todas las tiendas'),
              ),
              ...state.stores.map(
                (store) => DropdownMenuItem<int>(
                  value: store.id,
                  child: Text(store.name),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStoreId = value;
              });
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Widget _buildSellerDropdown() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        if (state is UsersLoaded) {
          return DropdownButtonFormField<int>(
            value: _selectedSellerId,
            decoration: const InputDecoration(
              labelText: 'Vendedor',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Todos los vendedores'),
              ),
              ...state.users.map(
                (user) => DropdownMenuItem<int>(
                  value: user.id,
                  child: Text(user.fullName),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSellerId = value;
              });
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Widget _buildReportsContent(ReportsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen estadístico
          _buildSummaryCards(state.summary),

          const SizedBox(height: 24),

          // Lista de ventas
          Text(
            'Detalle de Ventas (${state.salesData.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          if (state.salesData.isEmpty)
            _buildEmptyState()
          else
            _buildSalesList(state.salesData),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ReportSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de Ventas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Primera fila de cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Ventas',
                summary.totalSales.toString(),
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Ingresos',
                '\$${summary.totalRevenue.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Segunda fila de cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Ticket Promedio',
                '\$${summary.averageTicket.toStringAsFixed(2)}',
                Icons.receipt_long,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Items Vendidos',
                summary.totalItems.toString(),
                Icons.inventory,
                Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Cards de tops
        _buildTopCard(
          'Producto Más Vendido',
          summary.topSellingProduct,
          Icons.star,
        ),
        const SizedBox(height: 8),
        _buildTopCard('Tienda Top', summary.topPerformingStore, Icons.store),
        const SizedBox(height: 8),
        _buildTopCard('Mejor Vendedor', summary.topSeller, Icons.person),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.amber[700]),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay ventas en el período seleccionado',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSalesList(List<SalesReportData> sales) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: ExpansionTile(
            title: Text(
              'Venta ${sale.purchaseId}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${_dateTimeFormat.format(sale.purchaseDate)} - ${sale.storeName}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${sale.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${sale.itemsCount} items',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Vendedor: ${sale.sellerName}'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Productos:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    ...sale.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(item.productName)),
                            Expanded(
                              child: Text(
                                'x${item.quantity}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '\$${item.unitPrice.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '\$${item.totalPrice.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }
}
