import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/message_service.dart';

enum MessageLoadingState { idle, loading, success, error }

class MessageProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();

  // State management
  MessageLoadingState _state = MessageLoadingState.idle;
  String? _errorMessage;
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _conversationMessages = {};
  String? _currentConversationId;
  bool _isTyping = false;
  String? _typingUserId;

  // Loading states for different operations
  MessageLoadingState _sendingState = MessageLoadingState.idle;
  bool _isLoadingMessages = false;

  // Getters
  MessageLoadingState get state => _state;
  MessageLoadingState get sendingState => _sendingState;
  String? get errorMessage => _errorMessage;
  List<Conversation> get conversations => _conversations;
  String? get currentConversationId => _currentConversationId;
  bool get isTyping => _isTyping;
  String? get typingUserId => _typingUserId;
  bool get isLoading => _state == MessageLoadingState.loading;
  bool get isSending => _sendingState == MessageLoadingState.loading;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get hasError => _state == MessageLoadingState.error;

  List<Message> getCurrentMessages() {
    if (_currentConversationId == null) return [];
    return _conversationMessages[_currentConversationId!] ?? [];
  }

  Conversation? getCurrentConversation() {
    if (_currentConversationId == null) return null;
    return _conversations.firstWhere(
      (conv) => conv.id == _currentConversationId,
      orElse: () => conversations.first,
    );
  }

  /// Load conversations for a user
  Future<void> loadConversations(int userId) async {
    _setState(MessageLoadingState.loading);
    _clearError();

    try {
      final result = await _messageService.getConversations(userId: userId);

      if (result['success'] == true) {
        _conversations = result['conversations'] ?? [];
        _setState(MessageLoadingState.success);
      } else {
        _setError(result['message'] ?? 'Erreur lors du chargement des conversations');
      }
    } catch (e) {
      _setError('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Load messages for a conversation
  Future<bool> loadMessages(String conversationId) async {
    _isLoadingMessages = true;
    notifyListeners();

    try {
      final result = await _messageService.getMessages(conversationId: conversationId);

      if (result['success'] == true) {
        _conversationMessages[conversationId] = result['messages'] ?? [];
        _currentConversationId = conversationId;
        _isLoadingMessages = false;
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Erreur lors du chargement des messages');
        _isLoadingMessages = false;
        return false;
      }
    } catch (e) {
      _setError('Erreur inattendue: ${e.toString()}');
      _isLoadingMessages = false;
      return false;
    }
  }

  /// Send a text message
  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? receiverId,
  }) async {
    _setSendingState(MessageLoadingState.loading);

    try {
      final result = await _messageService.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        receiverId: receiverId,
      );

      if (result['success'] == true) {
        final newMessage = result['message'] as Message;
        _addMessageToConversation(conversationId, newMessage);
        _updateConversationLastMessage(conversationId, newMessage);
        _setSendingState(MessageLoadingState.success);
        return true;
      } else {
        _setSendingError(result['message'] ?? 'Erreur lors de l\'envoi du message');
        return false;
      }
    } catch (e) {
      _setSendingError('Erreur inattendue: ${e.toString()}');
      return false;
    }
  }

  /// Send a file message
  Future<bool> sendFileMessage({
    required String conversationId,
    required String senderId,
    required String filePath,
    required String fileName,
    MessageType type = MessageType.file,
    String? receiverId,
    String? caption,
  }) async {
    _setSendingState(MessageLoadingState.loading);

    try {
      final result = await _messageService.sendFileMessage(
        conversationId: conversationId,
        senderId: senderId,
        filePath: filePath,
        fileName: fileName,
        type: type,
        receiverId: receiverId,
        caption: caption,
      );

      if (result['success'] == true) {
        final newMessage = result['message'] as Message;
        _addMessageToConversation(conversationId, newMessage);
        _updateConversationLastMessage(conversationId, newMessage);
        _setSendingState(MessageLoadingState.success);
        return true;
      } else {
        _setSendingError(result['message'] ?? 'Erreur lors de l\'envoi du fichier');
        return false;
      }
    } catch (e) {
      _setSendingError('Erreur inattendue: ${e.toString()}');
      return false;
    }
  }

  /// Create a new conversation
  Future<bool> createConversation({
    required String title,
    required List<String> participantIds,
    bool isGroup = false,
  }) async {
    _setState(MessageLoadingState.loading);

    try {
      final result = await _messageService.createConversation(
        title: title,
        participantIds: participantIds,
        isGroup: isGroup,
      );

      if (result['success'] == true) {
        final newConversation = result['conversation'] as Conversation;
        _conversations.insert(0, newConversation);
        _setState(MessageLoadingState.success);
        return true;
      } else {
        _setError(result['message'] ?? 'Erreur lors de la création de la conversation');
        return false;
      }
    } catch (e) {
      _setError('Erreur inattendue: ${e.toString()}');
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      final result = await _messageService.markAsRead(
        conversationId: conversationId,
        userId: userId,
      );

      if (result['success'] == true) {
        // Update local conversation unread count
        final conversationIndex = _conversations.indexWhere((conv) => conv.id == conversationId);
        if (conversationIndex != -1) {
          _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(unreadCount: 0);

          // Update messages status to read
          final messages = _conversationMessages[conversationId];
          if (messages != null) {
            for (int i = 0; i < messages.length; i++) {
              if (messages[i].senderId != userId && !messages[i].isRead) {
                messages[i] = messages[i].copyWith(
                  status: MessageStatus.read,
                  readAt: DateTime.now(),
                );
              }
            }
          }

          notifyListeners();
        }
      }
    } catch (e) {
      // Silently handle read receipt errors
    }
  }

  /// Search messages
  Future<List<Message>> searchMessages({
    required String query,
    String? conversationId,
    int? userId,
  }) async {
    try {
      final result = await _messageService.searchMessages(
        query: query,
        conversationId: conversationId,
        userId: userId,
      );

      if (result['success'] == true) {
        return result['messages'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Send WhatsApp notification
  Future<bool> sendWhatsAppNotification({
    required String phoneNumber,
    required String message,
    String? mediaUrl,
  }) async {
    try {
      final result = await _messageService.sendWhatsAppNotification(
        phoneNumber: phoneNumber,
        message: message,
        mediaUrl: mediaUrl,
      );

      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Test WhatsApp integration
  Future<Map<String, dynamic>> testWhatsApp() async {
    try {
      return await _messageService.testWhatsApp();
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors du test WhatsApp: ${e.toString()}',
      };
    }
  }

  /// Set typing indicator
  void setTyping(String conversationId, String userId, bool isTyping) {
    _isTyping = isTyping;
    _typingUserId = isTyping ? userId : null;
    notifyListeners();
  }

  /// Add a message to a conversation (for real-time updates)
  void addMessage(String conversationId, Message message) {
    _addMessageToConversation(conversationId, message);
    _updateConversationLastMessage(conversationId, message);
  }

  /// Update message status (for delivery receipts)
  void updateMessageStatus(String conversationId, String messageId, MessageStatus status) {
    final messages = _conversationMessages[conversationId];
    if (messages != null) {
      final messageIndex = messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        messages[messageIndex] = messages[messageIndex].copyWith(
          status: status,
          readAt: status == MessageStatus.read ? DateTime.now() : null,
        );
        notifyListeners();
      }
    }
  }

  /// Private helper methods
  void _setState(MessageLoadingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setSendingState(MessageLoadingState newState) {
    _sendingState = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = MessageLoadingState.error;
    notifyListeners();
  }

  void _setSendingError(String error) {
    _errorMessage = error;
    _sendingState = MessageLoadingState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _addMessageToConversation(String conversationId, Message message) {
    if (_conversationMessages[conversationId] == null) {
      _conversationMessages[conversationId] = [];
    }
    _conversationMessages[conversationId]!.add(message);
    notifyListeners();
  }

  void _updateConversationLastMessage(String conversationId, Message message) {
    final conversationIndex = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
        lastMessage: message,
        lastMessageId: message.id,
        updatedAt: DateTime.now(),
      );

      // Move conversation to top
      final updatedConversation = _conversations.removeAt(conversationIndex);
      _conversations.insert(0, updatedConversation);

      notifyListeners();
    }
  }

  /// Reset states
  void resetState() {
    _state = MessageLoadingState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void resetSendingState() {
    _sendingState = MessageLoadingState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void clearCurrentConversation() {
    _currentConversationId = null;
    notifyListeners();
  }

  /// Get unread count for all conversations
  int get totalUnreadCount {
    return _conversations.fold(0, (sum, conversation) => sum + conversation.unreadCount);
  }

  /// Get conversation by ID
  Conversation? getConversationById(String conversationId) {
    try {
      return _conversations.firstWhere((conv) => conv.id == conversationId);
    } catch (e) {
      return null;
    }
  }
}