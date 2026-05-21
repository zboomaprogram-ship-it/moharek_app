class Invoice {
  final String id;
  final String projectId;
  final String invoiceNumber;
  final double amount;
  final String currency;
  final String status;
  final DateTime? dueDate;
  final String? paymentLink;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.projectId,
    required this.invoiceNumber,
    required this.amount,
    required this.currency,
    required this.status,
    this.dueDate,
    this.paymentLink,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      projectId: json['project_id'],
      invoiceNumber: json['invoice_number'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'SAR',
      status: json['status'] ?? 'unpaid',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      paymentLink: json['payment_link'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
