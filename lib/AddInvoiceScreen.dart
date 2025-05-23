import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddInvoiceScreen extends StatefulWidget {
  @override
  _AddInvoiceScreenState createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  DateTime? _dueDate;

  Future<void> _addInvoice() async {
    if (_formKey.currentState!.validate() && _dueDate != null) {
      final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;

      await FirebaseFirestore.instance.collection('invoices').add({
        'clientId': _clientIdController.text.trim(),
        'totalAmount': totalAmount,
        'paidAmount': 0.0,
        'dueDate': Timestamp.fromDate(_dueDate!),
        'status': 'Unpaid',
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Invoice Added")));
      Navigator.pop(context); // Return to previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _clientIdController,
                decoration: InputDecoration(labelText: 'Client Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter Client ID' : null,
              ),
              TextFormField(
                controller: _totalAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Total Amount'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter amount' : null,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
                child: Text(_dueDate == null
                    ? 'Select Due Date'
                    : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addInvoice,
                child: Text('Add Invoice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
