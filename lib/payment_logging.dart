import 'package:documentmanager/AddInvoiceScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class PaymentLoggingScreen extends StatefulWidget {
  @override
  _PaymentLoggingScreenState createState() => _PaymentLoggingScreenState();
}

class _PaymentLoggingScreenState extends State<PaymentLoggingScreen> {
  String? selectedInvoiceId;
  final amountController = TextEditingController();
  String paymentMethod = 'Cash';
  final methods = ['Cash', 'Credit', 'Bank'];

  double totalAmount = 0.0;
  double paidAmount = 0.0;

  Future<void> logPayment() async {
    if (selectedInvoiceId == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an invoice and enter amount")),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    final remainingAmount = totalAmount - paidAmount;

    if (amount == null || amount <= 0 || amount > remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Enter a valid amount up to ${remainingAmount.toStringAsFixed(2)}")),
      );
      return;
    }

    final paymentData = {
      'invoiceId': selectedInvoiceId,
      'amount': amount,
      'method': paymentMethod,
      'date': Timestamp.now(),
    };

    final invoiceRef = FirebaseFirestore.instance
        .collection('invoices')
        .doc(selectedInvoiceId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final invoiceSnapshot = await transaction.get(invoiceRef);

      if (!invoiceSnapshot.exists) throw Exception("Invoice not found");

      final currentPaid = (invoiceSnapshot.get('paidAmount') ?? 0).toDouble();

      transaction.set(
        FirebaseFirestore.instance.collection('payments').doc(),
        paymentData,
      );

      transaction.update(invoiceRef, {
        'paidAmount': currentPaid + amount,
      });
    });

    amountController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment logged successfully")),
    );
  }

  Future<void> fetchInvoiceDetails(String invoiceId) async {
    final invoiceRef =
        FirebaseFirestore.instance.collection('invoices').doc(invoiceId);
    final invoiceSnapshot = await invoiceRef.get();
    if (invoiceSnapshot.exists) {
      setState(() {
        totalAmount = (invoiceSnapshot.get('totalAmount') ?? 0).toDouble();
        paidAmount = (invoiceSnapshot.get('paidAmount') ?? 0).toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Payment Logging'),
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor,
            expandedHeight: 160,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('invoices').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );

                final invoices = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment Summary Card
                      if (selectedInvoiceId != null)
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).primaryColor.withOpacity(0.1),
                                  Colors.white,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                SizedBox(height: 16),
                                _buildInfoRow(
                                  'Total Amount',
                                  '\$${totalAmount.toStringAsFixed(2)}',
                                  Icons.attach_money,
                                ),
                                SizedBox(height: 8),
                                _buildInfoRow(
                                  'Paid Amount',
                                  '\$${paidAmount.toStringAsFixed(2)}',
                                  Icons.payment,
                                ),
                                SizedBox(height: 8),
                                _buildInfoRow(
                                  'Remaining',
                                  '\$${(totalAmount - paidAmount).toStringAsFixed(2)}',
                                  Icons.account_balance_wallet,
                                ),
                                SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: totalAmount > 0 ? paidAmount / totalAmount : 0,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 24),

                      // Payment Form Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              SizedBox(height: 20),
                              // Invoice Dropdown
                              DropdownButtonFormField<String>(
                                decoration: _buildInputDecoration(
                                  'Select Invoice',
                                  Icons.receipt_long,
                                ),
                                value: selectedInvoiceId,
                                items: invoices.map((doc) {
                                  final clientname = doc.id;
                                  return DropdownMenuItem(
                                    value: doc.id,
                                    child: Text('Invoice: $clientname'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedInvoiceId = val;
                                    if (val != null) fetchInvoiceDetails(val);
                                  });
                                },
                              ),
                              SizedBox(height: 16),

                              // Payment Amount TextField
                              TextField(
                                controller: amountController,
                                decoration: _buildInputDecoration(
                                  'Payment Amount',
                                  Icons.attach_money,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: 16),

                              // Payment Method Dropdown
                              DropdownButtonFormField<String>(
                                decoration: _buildInputDecoration(
                                  'Payment Method',
                                  Icons.payment,
                                ),
                                value: paymentMethod,
                                items: methods.map((method) {
                                  return DropdownMenuItem(
                                    value: method,
                                    child: Text(method),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => paymentMethod = val!),
                              ),
                              SizedBox(height: 24),

                              // Log Payment Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: logPayment,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    "Log Payment",
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
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddInvoiceScreen()),
          );
        },
        icon: Icon(Icons.add),
        label: Text('New Invoice'),
        tooltip: 'Add Invoice',
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }
}
