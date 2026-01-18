import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../providers/auth_provider.dart';
import '../models/message.dart';
import 'conversation_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _selectedIndex = 2;
  int _selectedTab = 0; // 0 for Chat, 1 for Support
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      await context.read<MessageProvider>().loadConversations(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search dialog
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (messageProvider.hasError) {
            return _buildErrorWidget(messageProvider.errorMessage!, screenWidth);
          }

          return Column(
            children: [
              // Tab Bar
              Container(
                margin: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'Conversations',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Support',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _selectedTab == 0
                    ? _buildConversationsList(messageProvider, screenWidth)
                    : _buildSupportSection(screenWidth),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: () {
                _showNewConversationDialog();
              },
              backgroundColor: const Color(0xFF1E3A8A),
              child: const Icon(Icons.add_comment, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsList(MessageProvider messageProvider, double screenWidth) {
    final conversations = messageProvider.conversations;

    if (conversations.isEmpty) {
      return _buildEmptyConversations();
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationCard(conversation, screenWidth);
        },
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation, double screenWidth) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversationId: conversation.id,
              conversationTitle: conversation.title,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundImage: conversation.avatarUrl != null
                  ? NetworkImage(conversation.avatarUrl!)
                  : null,
              backgroundColor: const Color(0xFF1E3A8A),
              child: conversation.avatarUrl == null
                  ? Text(
                      conversation.title.isNotEmpty
                          ? conversation.title[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            // Conversation Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.title,
                          style: TextStyle(
                            fontSize: screenWidth * 0.042,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.isPinned)
                        const Icon(
                          Icons.push_pin,
                          size: 16,
                          color: Color(0xFF1E3A8A),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage?.content ?? 'Aucun message',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time and Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conversation.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Text(
                      conversation.unreadCount > 99
                          ? '99+'
                          : conversation.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(conversation.updatedAt),
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey[500],
                  ),
                ),
                if (conversation.isMuted)
                  const Icon(
                    Icons.volume_off,
                    size: 16,
                    color: Colors.grey,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Support Actions
          _buildSupportAction(
            icon: Icons.help_outline,
            title: 'Centre d\'aide',
            subtitle: 'Consultez notre FAQ et guides',
            onTap: () {
              // Navigate to help center
            },
          ),
          const SizedBox(height: 16),
          _buildSupportAction(
            icon: Icons.chat,
            title: 'Contacter le support',
            subtitle: 'Discutez avec notre équipe',
            onTap: () {
              _startSupportChat();
            },
          ),
          const SizedBox(height: 16),
          _buildSupportAction(
            icon: Icons.phone,
            title: 'Appeler le support',
            subtitle: 'Appelez-nous directement',
            onTap: () {
              // Make phone call
            },
          ),
          const SizedBox(height: 16),
          _buildSupportAction(
            icon: Icons.feedback,
            title: 'Envoyer des commentaires',
            subtitle: 'Aidez-nous à améliorer l\'app',
            onTap: () {
              // Show feedback form
            },
          ),

          const Spacer(),

          // WhatsApp Test Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _testWhatsApp,
              icon: const Icon(Icons.message),
              label: const Text('Tester WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1E3A8A),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyConversations() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez une nouvelle conversation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage, double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadConversations,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rechercher'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Rechercher des messages...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performSearch(_searchController.text);
              },
              child: const Text('Rechercher'),
            ),
          ],
        );
      },
    );
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        return AlertDialog(
          title: const Text('Nouvelle conversation'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: 'Nom de la conversation',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createConversation(titleController.text);
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    final messages = await context.read<MessageProvider>().searchMessages(
      query: query,
      userId: authProvider.user!.id,
    );

    if (mounted) {
      // Show search results in a new screen or dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Résultats pour "$query"'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: messages.isEmpty
                  ? const Center(child: Text('Aucun résultat trouvé'))
                  : ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return ListTile(
                          title: Text(message.content),
                          subtitle: Text(_formatTime(message.createdAt)),
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to conversation
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _createConversation(String title) async {
    if (title.trim().isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    final success = await context.read<MessageProvider>().createConversation(
      title: title,
      participantIds: [authProvider.user!.id.toString()],
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation créée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _startSupportChat() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    // Create or find support conversation
    final success = await context.read<MessageProvider>().createConversation(
      title: 'Support - ${authProvider.user!.nom} ${authProvider.user!.prenom}',
      participantIds: [authProvider.user!.id.toString(), 'support'],
    );

    if (success && mounted) {
      // Navigate to the support conversation
      final conversations = context.read<MessageProvider>().conversations;
      final supportConv = conversations.firstWhere(
        (conv) => conv.title.startsWith('Support'),
        orElse: () => conversations.first,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            conversationId: supportConv.id,
            conversationTitle: supportConv.title,
          ),
        ),
      );
    }
  }

  Future<void> _testWhatsApp() async {
    final result = await context.read<MessageProvider>().testWhatsApp();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Test terminé'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Hier';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Accueil', 0),
          _buildNavItem(Icons.school, 'Cours', 1),
          _buildNavItem(Icons.menu_book, 'Bibliothèque', 2),
          _buildNavItem(Icons.message, 'Messages', 3),
          _buildNavItem(Icons.person, 'Profil', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    // Determine selected index based on current route
    int currentIndex = 0;
    String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    switch(currentRoute) {
      case '/home':
        currentIndex = 0;
        break;
      case '/courses':
        currentIndex = 1;
        break;
      case '/library':
        currentIndex = 2;
        break;
      case '/messages':
        currentIndex = 3;
        break;
      case '/profile':
        currentIndex = 4;
        break;
    }

    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/courses');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/library');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/messages');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

