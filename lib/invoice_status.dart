import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceStatusTrackingScreen extends StatefulWidget {
  @override
  _InvoiceStatusTrackingScreenState createState() =>
      _InvoiceStatusTrackingScreenState();
}

class _InvoiceStatusTrackingScreenState
    extends State<InvoiceStatusTrackingScreen> {
  String filterInvoiceId = '';

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Color(0xFF00897B); // Teal 600
      case 'pending':
        return Color(0xFFFB8C00); // Orange 600
      case 'overdue':
        return Color(0xFFE53935); // Red 600
      default:
        return Color(0xFF78909C); // Blue Grey 400
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoice Status Tracking',
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search Invoice ID',
                  hintText: 'Enter invoice number...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: filterInvoiceId.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              filterInvoiceId = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    filterInvoiceId = val.trim();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('invoices')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error loading invoices',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 48, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text('No invoices found',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final allInvoices = snapshot.data!.docs;
                  final invoices = filterInvoiceId.isEmpty
                      ? allInvoices
                      : allInvoices
                          .where((doc) => doc.id
                              .toLowerCase()
                              .contains(filterInvoiceId.toLowerCase()))
                          .toList();

                  if (invoices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 48, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text('No matching invoices found',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final doc = invoices[index];
                      final data = doc.data()! as Map<String, dynamic>;

                      final totalAmount = (data['totalAmount'] ?? 0).toDouble();
                      final paidAmount = (data['paidAmount'] ?? 0).toDouble();
                      final remainingAmount = totalAmount - paidAmount;
                      final status = data['status'] ?? 'Unknown Status';

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Invoice #${doc.id}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildAmountInfo('Total', totalAmount,
                                      Colors.blue.shade900),
                                  _buildAmountInfo(
                                      'Paid', paidAmount, Colors.green.shade700),
                                  _buildAmountInfo('Remaining', remainingAmount,
                                      Colors.red.shade700),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
