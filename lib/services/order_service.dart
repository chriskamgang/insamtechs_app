import 'package:dio/dio.dart';
import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  /// Create a new order
  Future<Map<String, dynamic>> createOrder({
    required int formationId,
    required String customerName,
    required String customerPhone,
    PaymentMethod? paymentMethod,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Récupérer les détails de la formation pour le prix
      final formationResponse = await _apiService.get('/formations/$formationId');
      if (formationResponse.statusCode != 200) {
        return {
          'success': false,
          'message': 'Formation non trouvée',
        };
      }

      final formation = formationResponse.data['data'] ?? formationResponse.data;
      final prix = double.parse(formation['prix'].toString());

      final response = await _apiService.post('/orders', data: {
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'items': [
          {
            'formation_id': formationId,
            'prix': prix,
            'quantite': 1,
          }
        ],
        'payment_method': paymentMethod != null
            ? _paymentMethodToString(paymentMethod)
            : null,
        ...?additionalData,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'order': Order.fromJson(response.data['commande'] ?? response.data),
          'message': response.data['message'] ?? 'Commande créée avec succès',
          'whatsapp_sent': response.data['whatsapp_sent'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la création de la commande',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  /// Get user orders
  Future<Map<String, dynamic>> getUserOrders({
    required int userId,
    int page = 1,
    int limit = 10,
    OrderStatus? status,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        'user_id': userId,
        if (status != null) 'etat_commande': _orderStatusToString(status),
      };

      final response = await _apiService.get(
        '/orders',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersData = response.data['commandes'] ?? response.data['data'] ?? [];
        final List<Order> orders = ordersData.map((orderJson) => Order.fromJson(orderJson)).toList();

        return {
          'success': true,
          'orders': orders,
          'pagination': response.data['pagination'],
          'total': response.data['total'] ?? orders.length,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors du chargement des commandes',
          'orders': <Order>[],
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
        'orders': <Order>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
        'orders': <Order>[],
      };
    }
  }

  /// Get order details
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final response = await _apiService.get('/orders/$orderId');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'order': Order.fromJson(response.data['order'] ?? response.data),
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Commande non trouvée',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  /// Process payment
  Future<Map<String, dynamic>> processPayment({
    required int orderId,
    required PaymentMethod paymentMethod,
    required String phoneNumber,
    Map<String, dynamic>? paymentData,
  }) async {
    try {
      final response = await _apiService.post('/orders/$orderId/payment', data: {
        'payment_method': _paymentMethodToString(paymentMethod),
        'phone_number': phoneNumber,
        ...?paymentData,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'payment_reference': response.data['payment_reference'],
          'payment_url': response.data['payment_url'],
          'message': response.data['message'] ?? 'Paiement initié avec succès',
          'order': response.data['order'] != null ? Order.fromJson(response.data['order']) : null,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors du traitement du paiement',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  /// Confirm payment
  Future<Map<String, dynamic>> confirmPayment({
    required int orderId,
    required String paymentReference,
    Map<String, dynamic>? confirmationData,
  }) async {
    try {
      final response = await _apiService.post('/orders/payment-confirmation', data: {
        'order_id': orderId,
        'payment_reference': paymentReference,
        ...?confirmationData,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'order': Order.fromJson(response.data['order'] ?? response.data),
          'message': response.data['message'] ?? 'Paiement confirmé avec succès',
          'enrollment_status': response.data['enrollment_status'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la confirmation du paiement',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  /// Cancel order
  Future<Map<String, dynamic>> cancelOrder(int orderId, {String? reason}) async {
    try {
      final response = await _apiService.post('/orders/$orderId/cancel', data: {
        if (reason != null) 'reason': reason,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'order': Order.fromJson(response.data['order'] ?? response.data),
          'message': response.data['message'] ?? 'Commande annulée avec succès',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de l\'annulation de la commande',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  /// Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus({
    required int orderId,
    required String paymentReference,
  }) async {
    try {
      final response = await _apiService.get('/orders/$orderId/payment-status',
        queryParameters: {'payment_reference': paymentReference}
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'payment_status': response.data['payment_status'],
          'order': response.data['order'] != null ? Order.fromJson(response.data['order']) : null,
          'transaction_details': response.data['transaction_details'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la vérification du statut',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  /// Get payment methods
  Future<Map<String, dynamic>> getPaymentMethods() async {
    try {
      final response = await _apiService.get('/payment-methods');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'payment_methods': response.data['payment_methods'] ?? response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors du chargement des méthodes de paiement',
          'payment_methods': [],
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
        'payment_methods': [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
        'payment_methods': [],
      };
    }
  }

  /// Helper methods
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Délai de connexion dépassé';
      case DioExceptionType.sendTimeout:
        return 'Délai d\'envoi dépassé';
      case DioExceptionType.receiveTimeout:
        return 'Délai de réception dépassé';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.response?.data?['error'];

        if (statusCode == 400) {
          return message ?? 'Données invalides';
        } else if (statusCode == 401) {
          return 'Session expirée. Veuillez vous reconnecter';
        } else if (statusCode == 403) {
          return 'Accès non autorisé';
        } else if (statusCode == 404) {
          return 'Ressource non trouvée';
        } else if (statusCode == 422) {
          return message ?? 'Données de validation incorrectes';
        } else if (statusCode == 500) {
          return 'Erreur du serveur. Veuillez réessayer plus tard';
        } else {
          return message ?? 'Erreur de connexion au serveur';
        }
      case DioExceptionType.cancel:
        return 'Requête annulée';
      case DioExceptionType.connectionError:
        return 'Erreur de connexion. Vérifiez votre connexion internet';
      default:
        return 'Erreur de réseau inattendue';
    }
  }

  String _paymentMethodToString(PaymentMethod method) {
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

  String _orderStatusToString(OrderStatus status) {
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
}