class Invoice {
  String id;
  String clientId;
  double totalAmount;
  double paidAmount;
  String status; // Paid, Unpaid, Overdue
  List<Payment> payments;

  Invoice({
    required this.id,
    required this.clientId,
    required this.totalAmount,
    this.paidAmount = 0,
    this.status = "Unpaid",
    this.payments = const [],
  });
}

class Payment {
  String id;
  String invoiceId;
  double amount;
  String method; // e.g., Cash, Credit
  DateTime date;

  Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.date,
  });
}
