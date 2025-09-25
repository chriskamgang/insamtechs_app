import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';

class WishlistButton extends StatelessWidget {
  final int formationId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showToast;

  const WishlistButton({
    super.key,
    required this.formationId,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.showToast = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<WishlistProvider, AuthProvider>(
      builder: (context, wishlistProvider, authProvider, child) {
        final isInWishlist = wishlistProvider.isInWishlist(formationId);
        final isLoading = wishlistProvider.isLoading;
        final user = authProvider.user;

        return GestureDetector(
          onTap: () async {
            if (user?.id == null) {
              if (showToast) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez vous connecter pour ajouter à votre wishlist'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }

            if (isLoading) return;

            final success = await wishlistProvider.toggleWishlist(
              userId: user!.id!,
              formationId: formationId,
            );

            if (showToast && success) {
              final message = isInWishlist
                  ? 'Retiré de la wishlist'
                  : 'Ajouté à la wishlist';

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: isInWishlist ? Colors.orange : Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } else if (showToast && !success && wishlistProvider.hasError) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(wishlistProvider.errorMessage!),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: isLoading
                ? SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        activeColor ?? const Color(0xFF1E3A8A),
                      ),
                    ),
                  )
                : Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                    size: size,
                    color: isInWishlist
                        ? (activeColor ?? Colors.red)
                        : (inactiveColor ?? Colors.grey[600]),
                  ),
          ),
        );
      },
    );
  }
}