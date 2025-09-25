import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';

enum OrderLoadingState { idle, loading, success, error }

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  // State management
  OrderLoadingState _state = OrderLoadingState.idle;
  String? _errorMessage;
  List<Order> _userOrders = [];
  Order? _currentOrder;
  Map<String, dynamic>? _paymentMethods;

  // Payment state
  OrderLoadingState _paymentState = OrderLoadingState.idle;
  String? _paymentReference;
  String? _paymentUrl;
  String? _paymentError;

  // Getters
  OrderLoadingState get state => _state;
  OrderLoadingState get paymentState => _paymentState;
  String? get errorMessage => _errorMessage;
  String? get paymentError => _paymentError;
  List<Order> get userOrders => _userOrders;
  Order? get currentOrder => _currentOrder;
  Map<String, dynamic>? get paymentMethods => _paymentMethods;
  String? get paymentReference => _paymentReference;
  String? get paymentUrl => _paymentUrl;

  bool get isLoading => _state == OrderLoadingState.loading;
  bool get isPaymentLoading => _paymentState == OrderLoadingState.loading;
  bool get hasError => _state == OrderLoadingState.error;
  bool get hasPaymentError => _paymentState == OrderLoadingState.error;

  /// Create a new order
  Future<bool> createOrder({
    required int formationId,
    required String customerName,
    required String customerPhone,
    PaymentMethod? paymentMethod,
    Map<String, dynamic>? additionalData,
  }) async {
    _setState(OrderLoadingState.loading);
    _clearError();

    try {
      final result = await _orderService.createOrder(
        formationId: formationId,
        customerName: customerName,
        customerPhone: customerPhone,
        paymentMethod: paymentMethod,
        additionalData: additionalData,
      );

      if (result['success'] == true) {
        _currentOrder = result['order'];
        _setState(OrderLoadingState.success);

        return true;
      } else {
        _setError(result['message'] ?? 'Erreur lors de la création de la commande');
        return false;
      }
    } catch (e) {
      _setError('Erreur inattendue: ${e.toString()}');
      return false;
    }
  }

  /// Load user orders
  Future<void> loadUserOrders({
    required int userId,
    int page = 1,
    int limit = 10,
    OrderStatus? status,
  }) async {
    _setState(OrderLoadingState.loading);
    _clearError();

    try {
      final result = await _orderService.getUserOrders(
        userId: userId,
        page: page,
        limit: limit,
        status: status,
      );

      if (result['success'] == true) {
        _userOrders = result['orders'] ?? [];
        _setState(OrderLoadingState.success);
      } else {
        _userOrders = [];
        _setError(result['message'] ?? 'Erreur lors du chargement des commandes');
      }
    } catch (e) {
      _userOrders = [];
      _setError('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Refresh user orders
  Future<void> refreshUserOrders(int userId) async {
    await loadUserOrders(userId: userId);
  }

  /// Load order details
  Future<bool> loadOrderDetails(int orderId) async {
    _setState(OrderLoadingState.loading);
    _clearError();

    try {
      final result = await _orderService.getOrderDetails(orderId);

      if (result['success'] == true) {
        _currentOrder = result['order'];
        _setState(OrderLoadingState.success);
        return true;
      } else {
        _setError(result['message'] ?? 'Commande non trouvée');
        return false;
      }
    } catch (e) {
      _setError('Erreur inattendue: ${e.toString()}');
      return false;
    }
  }

  /// Process payment
  Future<bool> processPayment({
    required int orderId,
    required PaymentMethod paymentMethod,
    required String phoneNumber,
    Map<String, dynamic>? paymentData,
  }) async {
    _setPaymentState(OrderLoadingState.loading);
    _clearPaymentError();

    try {
      final result = await _orderService.processPayment(
        orderId: orderId,
        paymentMethod: paymentMethod,
        phoneNumber: phoneNumber,
        paymentData: paymentData,
      );

      if (result['success'] == true) {
        _paymentReference = result['payment_reference'];
        _paymentUrl = result['payment_url'];
        if (result['order'] != null) {
          _currentOrder = result['order'];
        }
        _setPaymentState(OrderLoadingState.success);
        return true;
      } else {
        _setPaymentError(result['message'] ?? 'Erreur lors du traitement du paiement');
        return false;
      }
    } catch (e) {
      _setPaymentError('Erreur inattendue: ${e.toString()}');
      return false;
    }
  }

  /// Confirm payment
  Future<bool> confirmPayment({
    required int orderId,
    required String paymentReference,
    Map<String, dynamic>? confirmationData,
  }) async {
    _setPaymentState(OrderLoadingState.loading);
    _clearPaymentError();

    try {
      final result = await _orderService.confirmPayment(
        orderId: orderId,
        paymentReference: paymentReference,
        confirmationData: confirmationData,
      );

      if (result['success'] == true) {
        _currentOrder = result['order'];
        _setPaymentState(OrderLoadingState.success);

        // Update the order in the user orders list
        if (_currentOrder != null) {
          _updateOrderInList(_currentOrder!);
        }

        return true;
      } else {
        _setPaymentError(result['message'] ?? 'Erreur lors de la confirmation du paiement');
        return false;
      }
    } catch (e) {
      _setPaymentError('Erreur inattendue: ${e.toString()}');
      return false;
    }
  }

  /// Cancel order
  Future<bool> cancelOrder(int orderId, {String? reason}) async {
    _setState(OrderLoadingState.loading);
    _clearError();

    try {
      final result = await _orderService.cancelOrder(orderId, reason: reason);

      if (result['success'] == true) {
        _currentOrder = result['order'];

        // Update the order in the user orders list
        if (_currentOrder != null) {
          _updateOrderInList(_currentOrder!);
        }

        _setState(OrderLoadingState.success);
        return true;
      } else {
        _setError(result['message'] ?? 'Erreur lors de l\'annulation de la commande');
        return false;
      }
    } catch (e) {
      _setError('Erreur inattendue: ${e.toString()}');
      return false;
    }
  }

  /// Check payment status
  Future<bool> checkPaymentStatus({
    required int orderId,
    required String paymentReference,
  }) async {
    try {
      final result = await _orderService.checkPaymentStatus(
        orderId: orderId,
        paymentReference: paymentReference,
      );

      if (result['success'] == true) {
        if (result['order'] != null) {
          _currentOrder = result['order'];
          _updateOrderInList(_currentOrder!);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Load payment methods
  Future<void> loadPaymentMethods() async {
    try {
      final result = await _orderService.getPaymentMethods();
      if (result['success'] == true) {
        _paymentMethods = result;
        notifyListeners();
      }
    } catch (e) {
      // Silently fail for now
    }
  }

  /// Helper methods
  void _setState(OrderLoadingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setPaymentState(OrderLoadingState newState) {
    _paymentState = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = OrderLoadingState.error;
    notifyListeners();
  }

  void _setPaymentError(String error) {
    _paymentError = error;
    _paymentState = OrderLoadingState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _clearPaymentError() {
    _paymentError = null;
  }

  void _updateOrderInList(Order updatedOrder) {
    final index = _userOrders.indexWhere((order) => order.id == updatedOrder.id);
    if (index != -1) {
      _userOrders[index] = updatedOrder;
      notifyListeners();
    }
  }

  /// Reset states
  void resetState() {
    _state = OrderLoadingState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void resetPaymentState() {
    _paymentState = OrderLoadingState.idle;
    _paymentError = null;
    _paymentReference = null;
    _paymentUrl = null;
    notifyListeners();
  }

  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  /// Filter orders by status
  List<Order> getOrdersByStatus(OrderStatus status) {
    return _userOrders.where((order) => order.status == status).toList();
  }

  /// Get pending orders count
  int get pendingOrdersCount {
    return _userOrders.where((order) => order.isPending).length;
  }

  /// Get paid orders count
  int get paidOrdersCount {
    return _userOrders.where((order) => order.isPaid).length;
  }

  /// Get total amount for paid orders
  double get totalPaidAmount {
    return _userOrders
        .where((order) => order.isPaid)
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }
}