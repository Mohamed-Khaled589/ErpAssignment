import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptGenerationScreen extends StatefulWidget {
  final String? invoiceId;

  const ReceiptGenerationScreen({Key? key, this.invoiceId}) : super(key: key);

  @override
  _ReceiptGenerationScreenState createState() => _ReceiptGenerationScreenState();
}

class _ReceiptGenerationScreenState extends State<ReceiptGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  // Form controllers
  final _invoiceIdController = TextEditingController();

  // Receipt data
  Map<String, dynamic>? _invoiceData;
  bool _isLoadingInvoice = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoiceId != null) {
      _invoiceIdController.text = widget.invoiceId!;
      _fetchInvoiceData();
    }
  }

  Future<void> _fetchInvoiceData() async {
    setState(() {
      _isLoadingInvoice = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('invoices')
          .doc(_invoiceIdController.text)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Invoice not found';
          _isLoadingInvoice = false;
        });
        return;
      }

      setState(() {
        _invoiceData = doc.data();
        _isLoadingInvoice = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error fetching invoice: $e';
        _isLoadingInvoice = false;
      });
    }
  }

  Future<void> _generateReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pdf = pw.Document();

      // Add receipt content
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Date: ${DateFormat('MMM d, y').format(DateTime.now())}',
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),

                // Invoice Details
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Invoice #${_invoiceIdController.text}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Status: ${_invoiceData?['status'] ?? 'N/A'}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Amount Details
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Total Amount'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '\$${(_invoiceData?['totalAmount'] ?? 0).toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Paid Amount'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '\$${(_invoiceData?['paidAmount'] ?? 0).toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Footer
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Preview the PDF
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error generating receipt: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _invoiceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Generate Receipt'),
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor,
            expandedHeight: 160,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Receipt Preview Card
                  if (_invoiceData != null)
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Invoice Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_invoiceData!['status']),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _invoiceData!['status'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            _buildInfoRow(
                              'Total Amount',
                              '\$${(_invoiceData!['totalAmount'] ?? 0).toStringAsFixed(2)}',
                              Icons.attach_money,
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow(
                              'Paid Amount',
                              '\$${(_invoiceData!['paidAmount'] ?? 0).toStringAsFixed(2)}',
                              Icons.payment,
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow(
                              'Due Date',
                              DateFormat('MMM d, y').format(
                                (_invoiceData!['dueDate'] as Timestamp).toDate(),
                              ),
                              Icons.calendar_today,
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 24),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _invoiceIdController,
                          decoration: _buildInputDecoration(
                            'Invoice ID',
                            Icons.receipt_long,
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter an invoice ID';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _fetchInvoiceData();
                            }
                          },
                        ),
                        SizedBox(height: 24),
                        if (_error != null)
                          Container(
                            padding: EdgeInsets.all(12),
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
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _generateReceipt,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Generate Receipt',
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
                ],
              ),
            ),
          ),
        ],
      ),
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
} 