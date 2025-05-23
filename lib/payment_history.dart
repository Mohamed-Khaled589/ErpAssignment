import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentHistoryLogScreen extends StatefulWidget {
  @override
  _PaymentFilterScreenState createState() => _PaymentFilterScreenState();
}

class _PaymentFilterScreenState extends State<PaymentHistoryLogScreen> {
  final _invoiceIdController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> _filteredPayments = [];
  bool _loading = false;
  String? _error;

  final List<String> _paymentMethods = ['Cash', 'Credit', 'Bank'];

  Color _getMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'credit':
        return Colors.blue;
      case 'bank':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _searchPayments() async {
    final invoiceId = _invoiceIdController.text.trim();
    if (invoiceId.isEmpty) {
      setState(() => _error = "Please enter an invoice ID");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _filteredPayments = [];
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('payments')
          .where('invoiceId', isEqualTo: invoiceId);

      if (_selectedMethod != null && _selectedMethod!.isNotEmpty) {
        query = query.where('method', isEqualTo: _selectedMethod);
      }

      if (_amountController.text.isNotEmpty) {
        final amount = double.tryParse(_amountController.text);
        if (amount != null) {
          query = query.where('amount', isEqualTo: amount);
        }
      }

      if (_startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
      }
      if (_endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
      }

      final snapshot = await query.get();
      final payments = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        _filteredPayments = payments;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error fetching payments: $e";
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _invoiceIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _invoiceIdController,
                      decoration: InputDecoration(
                        labelText: 'Invoice ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMethod,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: [null, ..._paymentMethods].map((method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Row(
                            children: [
                              if (method != null) ...[
                                Container(
                                  width: 12,
                                  height: 12,
                                  margin: EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _getMethodColor(method),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(method),
                              ] else
                                Text('Any Method'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedMethod = val),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickStartDate,
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 20, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Text(
                                    _startDate == null
                                        ? 'Start Date'
                                        : DateFormat('MMM d, y').format(_startDate!),
                                    style: TextStyle(
                                      color: _startDate == null
                                          ? Colors.grey[600]
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _pickEndDate,
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 20, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Text(
                                    _endDate == null
                                        ? 'End Date'
                                        : DateFormat('MMM d, y').format(_endDate!),
                                    style: TextStyle(
                                      color: _endDate == null
                                          ? Colors.grey[600]
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _searchPayments,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Search Payments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              if (_loading)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              if (_error != null)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_loading && _filteredPayments.isEmpty && _error == null)
                Center(
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
                        'No payments found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try adjusting your search filters',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              if (_filteredPayments.isNotEmpty) ...[
                Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _filteredPayments.length,
                  itemBuilder: (context, index) {
                    final payment = _filteredPayments[index];
                    final date = (payment['date'] as Timestamp).toDate();
                    final formattedDate = DateFormat.yMMMd().add_jm().format(date);
                    final method = payment['method'] as String;
                    final amount = payment['amount'] as num;

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Payment #${payment['id'] ?? index + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getMethodColor(method),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    method,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Amount',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '\$${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
