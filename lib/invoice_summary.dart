import 'package:documentmanager/AddInvoiceScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InvoiceSummaryReportScreen extends StatefulWidget {
  @override
  _InvoiceSummaryReportScreenState createState() =>
      _InvoiceSummaryReportScreenState();
}

class _InvoiceSummaryReportScreenState extends State<InvoiceSummaryReportScreen> {
  DateTimeRange? selectedDateRange;
  String selectedStatus = 'All';
  String selectedClient = 'All';
  List<String> statusOptions = ['All', 'Paid', 'Unpaid', 'Overdue'];
  List<String> clientOptions = ['All'];
  bool isLoadingClients = true;
  bool isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchClientIds();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Color(0xFF00897B); // Teal 600
      case 'unpaid':
        return Color(0xFFFB8C00); // Orange 600
      case 'overdue':
        return Color(0xFFE53935); // Red 600
      default:
        return Color(0xFF78909C); // Blue Grey 400
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'unpaid':
        return Icons.pending;
      case 'overdue':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Future<void> _fetchClientIds() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('invoices').get();
      final clients = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final clientId = data['clientId'] ?? '';
        if (clientId.isNotEmpty) {
          clients.add(clientId);
        }
      }
      setState(() {
        clientOptions.addAll(clients.toList());
        isLoadingClients = false;
      });
    } catch (e) {
      print("Error fetching client IDs: $e");
      setState(() {
        isLoadingClients = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Invoice Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    isFilterExpanded = !isFilterExpanded;
                  });
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: isFilterExpanded ? null : 0,
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_alt, 
                            color: Theme.of(context).primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: statusOptions.map((status) {
                        final isSelected = selectedStatus == status;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (status != 'All')
                                Icon(
                                  _getStatusIcon(status),
                                  size: 16,
                                  color: isSelected ? Colors.white : _getStatusColor(status),
                                ),
                              SizedBox(width: 4),
                              Text(status),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: status != 'All' 
                              ? _getStatusColor(status) 
                              : Theme.of(context).primaryColor,
                          onSelected: (bool selected) {
                            setState(() {
                              selectedStatus = selected ? status : 'All';
                            });
                          },
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.grey[100],
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    if (isLoadingClients)
                      Center(child: CircularProgressIndicator())
                    else
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedClient,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down),
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            items: clientOptions.map((client) {
                              return DropdownMenuItem<String>(
                                value: client,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_circle,
                                      color: Theme.of(context).primaryColor,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(client),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => selectedClient = val!),
                          ),
                        ),
                      ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Theme.of(context).primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => selectedDateRange = picked);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.date_range, 
                                color: Theme.of(context).primaryColor),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedDateRange == null
                                    ? 'Select Date Range'
                                    : '${DateFormat('MMM d').format(selectedDateRange!.start)} - ${DateFormat('MMM d').format(selectedDateRange!.end)}',
                                style: TextStyle(
                                  color: selectedDateRange == null 
                                      ? Colors.grey[600] 
                                      : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('invoices').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                );

              final invoices = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? '';
                final clientId = data['clientId'] ?? '';
                final dueDate = (data['dueDate'] as Timestamp).toDate();

                bool matchesStatus = selectedStatus == 'All' || status == selectedStatus;
                bool matchesClient = selectedClient == 'All' || clientId == selectedClient;
                bool matchesDate = selectedDateRange == null ||
                    (dueDate.isAfter(selectedDateRange!.start) &&
                        dueDate.isBefore(selectedDateRange!.end));

                return matchesStatus && matchesClient && matchesDate;
              }).toList();

              if (invoices.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No invoices found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (selectedStatus != 'All' || 
                            selectedClient != 'All' || 
                            selectedDateRange != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton.icon(
                              icon: Icon(Icons.filter_list_off),
                              label: Text('Clear Filters'),
                              onPressed: () {
                                setState(() {
                                  selectedStatus = 'All';
                                  selectedClient = 'All';
                                  selectedDateRange = null;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = invoices[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final total = (data['totalAmount'] ?? 0).toDouble();
                    final paid = (data['paidAmount'] ?? 0).toDouble();
                    final dueDate = (data['dueDate'] as Timestamp).toDate();
                    final clientId = data['clientId'] ?? 'Unknown';
                    final status = data['status'] ?? 'Unknown';
                    final progress = total > 0 ? (paid / total) : 0.0;

                    return Container(
                      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(status).withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(status),
                                      color: _getStatusColor(status),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Invoice #${doc.id}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        size: 20, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(
                                      clientId,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Spacer(),
                                    Icon(Icons.calendar_today,
                                        size: 20, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM d, y').format(dueDate),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Payment Progress',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${(progress * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Stack(
                                      children: [
                                        Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildAmountColumn(
                                      'Total',
                                      total,
                                      _getStatusColor(status),
                                    ),
                                    _buildAmountColumn(
                                      'Paid',
                                      paid,
                                      _getStatusColor(status),
                                    ),
                                    _buildAmountColumn(
                                      'Remaining',
                                      total - paid,
                                      _getStatusColor(status),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: invoices.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isFilterExpanded = !isFilterExpanded;
          });
        },
        child: Icon(
          isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
          color: Colors.white,
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
