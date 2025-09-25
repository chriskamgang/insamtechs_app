enum OrderStatus {
  pending,
  processing,
  paid,
  failed,
  cancelled,
  refunded
}

enum PaymentMethod {
  mobileMoneyMTN,
  mobileMoneyOrange,
  bankTransfer,
  cashOnDelivery,
  creditCard
}

class Order {
  final int id;
  final int? userId;
  final int? formationId;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final double amount;
  final double taxAmount;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod? paymentMethod;
  final String? paymentReference;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final Formation? formation;
  final Map<String, dynamic>? paymentDetails;

  Order({
    required this.id,
    this.userId,
    this.formationId,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.paymentReference,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.formation,
    this.paymentDetails,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      userId: json['user_id'],
      formationId: json['formation_id'],
      orderNumber: json['numero_commande'] ?? json['order_number'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      amount: double.tryParse(json['montant']?.toString() ?? json['amount']?.toString() ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['montant_total']?.toString() ?? json['total_amount']?.toString() ?? '0') ?? 0.0,
      status: _parseOrderStatus(json['etat_commande'] ?? json['status']),
      paymentMethod: _parsePaymentMethod(json['payment_method']),
      paymentReference: json['payment_reference'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
      formation: json['formation'] != null ? Formation.fromJson(json['formation']) : null,
      paymentDetails: json['payment_details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'formation_id': formationId,
      'numero_commande': orderNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'montant': amount,
      'tax_amount': taxAmount,
      'montant_total': totalAmount,
      'etat_commande': _orderStatusToString(status),
      'payment_method': paymentMethod != null ? _paymentMethodToString(paymentMethod!) : null,
      'payment_reference': paymentReference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'formation': formation?.toJson(),
      'payment_details': paymentDetails,
    };
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'paid':
        return OrderStatus.paid;
      case 'failed':
        return OrderStatus.failed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }

  static PaymentMethod? _parsePaymentMethod(String? method) {
    switch (method?.toLowerCase()) {
      case 'mobile_money_mtn':
      case 'mtn':
        return PaymentMethod.mobileMoneyMTN;
      case 'mobile_money_orange':
      case 'orange':
        return PaymentMethod.mobileMoneyOrange;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'cash_on_delivery':
        return PaymentMethod.cashOnDelivery;
      case 'credit_card':
        return PaymentMethod.creditCard;
      default:
        return null;
    }
  }

  static String _orderStatusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.paid:
        return 'paid';
      case OrderStatus.failed:
        return 'failed';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.refunded:
        return 'refunded';
    }
  }

  static String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mobileMoneyMTN:
        return 'mobile_money_mtn';
      case PaymentMethod.mobileMoneyOrange:
        return 'mobile_money_orange';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.cashOnDelivery:
        return 'cash_on_delivery';
      case PaymentMethod.creditCard:
        return 'credit_card';
    }
  }

  // Helper getters
  bool get isPending => status == OrderStatus.pending;
  bool get isProcessing => status == OrderStatus.processing;
  bool get isPaid => status == OrderStatus.paid;
  bool get isFailed => status == OrderStatus.failed;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isRefunded => status == OrderStatus.refunded;

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.processing:
        return 'En cours de traitement';
      case OrderStatus.paid:
        return 'Payé';
      case OrderStatus.failed:
        return 'Échoué';
      case OrderStatus.cancelled:
        return 'Annulé';
      case OrderStatus.refunded:
        return 'Remboursé';
    }
  }

  String get paymentMethodText {
    switch (paymentMethod) {
      case PaymentMethod.mobileMoneyMTN:
        return 'MTN Mobile Money';
      case PaymentMethod.mobileMoneyOrange:
        return 'Orange Money';
      case PaymentMethod.bankTransfer:
        return 'Virement bancaire';
      case PaymentMethod.cashOnDelivery:
        return 'Paiement à la livraison';
      case PaymentMethod.creditCard:
        return 'Carte de crédit';
      case null:
        return 'Non spécifié';
    }
  }

  Order copyWith({
    int? id,
    int? userId,
    int? formationId,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    double? amount,
    double? taxAmount,
    double? totalAmount,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentReference,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    Formation? formation,
    Map<String, dynamic>? paymentDetails,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      formationId: formationId ?? this.formationId,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      amount: amount ?? this.amount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      formation: formation ?? this.formation,
      paymentDetails: paymentDetails ?? this.paymentDetails,
    );
  }
}

// Import for Formation model
class Formation {
  final int id;
  final String title;
  final String description;
  final double price;
  final String? imageUrl;

  Formation({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
  });

  factory Formation.fromJson(Map<String, dynamic> json) {
    return Formation(
      id: json['id'] ?? 0,
      title: json['nom'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['prix']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image'] ?? json['img'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'image': imageUrl,
    };
  }
}