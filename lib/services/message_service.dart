import 'package:dio/dio.dart';
import '../models/message.dart';
import 'api_service.dart';

class MessageService {
  final ApiService _apiService = ApiService();

  /// Get all conversations for a user
  Future<Map<String, dynamic>> getConversations({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/conversations',
        queryParameters: {
          'user_id': userId,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> conversationsData = response.data['conversations'] ?? response.data['data'] ?? [];
        final List<Conversation> conversations = conversationsData
            .map((conversationJson) => Conversation.fromJson(conversationJson))
            .toList();

        return {
          'success': true,
          'conversations': conversations,
          'pagination': response.data['pagination'],
          'total': response.data['total'] ?? conversations.length,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors du chargement des conversations',
          'conversations': <Conversation>[],
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
        'conversations': <Conversation>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
        'conversations': <Conversation>[],
      };
    }
  }

  /// Get messages in a conversation
  Future<Map<String, dynamic>> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.get(
        '/conversations/$conversationId/messages',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesData = response.data['messages'] ?? response.data['data'] ?? [];
        final List<Message> messages = messagesData
            .map((messageJson) => Message.fromJson(messageJson))
            .toList();

        return {
          'success': true,
          'messages': messages,
          'pagination': response.data['pagination'],
          'total': response.data['total'] ?? messages.length,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors du chargement des messages',
          'messages': <Message>[],
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
        'messages': <Message>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
        'messages': <Message>[],
      };
    }
  }

  /// Send a text message
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? receiverId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiService.post('/messages', data: {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'type': _messageTypeToString(type),
        'metadata': metadata,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': Message.fromJson(response.data['message'] ?? response.data),
          'response_message': response.data['message_text'] ?? 'Message envoyé avec succès',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de l\'envoi du message',
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

  /// Send a file message
  Future<Map<String, dynamic>> sendFileMessage({
    required String conversationId,
    required String senderId,
    required String filePath,
    required String fileName,
    MessageType type = MessageType.file,
    String? receiverId,
    String? caption,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'type': _messageTypeToString(type),
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (caption != null) 'content': caption,
      });

      final response = await _apiService.post('/messages/file', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': Message.fromJson(response.data['message'] ?? response.data),
          'response_message': response.data['message_text'] ?? 'Fichier envoyé avec succès',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de l\'envoi du fichier',
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

  /// Create a new conversation
  Future<Map<String, dynamic>> createConversation({
    required String title,
    required List<String> participantIds,
    bool isGroup = false,
  }) async {
    try {
      final response = await _apiService.post('/conversations', data: {
        'title': title,
        'participant_ids': participantIds,
        'is_group': isGroup,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'conversation': Conversation.fromJson(response.data['conversation'] ?? response.data),
          'message': response.data['message'] ?? 'Conversation créée avec succès',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la création de la conversation',
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

  /// Mark messages as read
  Future<Map<String, dynamic>> markAsRead({
    required String conversationId,
    required String userId,
    String? messageId,
  }) async {
    try {
      final response = await _apiService.post('/messages/mark-read', data: {
        'conversation_id': conversationId,
        'user_id': userId,
        if (messageId != null) 'message_id': messageId,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Messages marqués comme lus',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors du marquage comme lu',
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

  /// Search messages
  Future<Map<String, dynamic>> searchMessages({
    required String query,
    String? conversationId,
    int? userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get('/messages/search', queryParameters: {
        'q': query,
        if (conversationId != null) 'conversation_id': conversationId,
        if (userId != null) 'user_id': userId,
        'page': page,
        'limit': limit,
      });

      if (response.statusCode == 200) {
        final List<dynamic> messagesData = response.data['messages'] ?? response.data['data'] ?? [];
        final List<Message> messages = messagesData
            .map((messageJson) => Message.fromJson(messageJson))
            .toList();

        return {
          'success': true,
          'messages': messages,
          'pagination': response.data['pagination'],
          'total': response.data['total'] ?? messages.length,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la recherche',
          'messages': <Message>[],
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
        'messages': <Message>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
        'messages': <Message>[],
      };
    }
  }

  /// Send WhatsApp notification
  Future<Map<String, dynamic>> sendWhatsAppNotification({
    required String phoneNumber,
    required String message,
    String? mediaUrl,
  }) async {
    try {
      final response = await _apiService.post('/whatsapp/send', data: {
        'phone': phoneNumber,
        'message': message,
        if (mediaUrl != null) 'media_url': mediaUrl,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Message WhatsApp envoyé avec succès',
          'whatsapp_response': response.data['whatsapp_response'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de l\'envoi WhatsApp',
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

  /// Test WhatsApp integration
  Future<Map<String, dynamic>> testWhatsApp() async {
    try {
      final response = await _apiService.post('/whatsapp/test');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Test WhatsApp réussi',
          'test_result': response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors du test WhatsApp',
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
          return 'Conversation ou message non trouvé';
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

  String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
      case MessageType.voice:
        return 'voice';
    }
  }
}