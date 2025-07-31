import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  Future<void> _downloadImage() async {
    final uri = Uri.parse(imageUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: InteractiveViewer(
              child: Hero(
                tag: imageUrl,
                child: Image.network(imageUrl),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: _buildGlassIcon(
              context,
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 8,
            right: 8,
            child: _buildGlassIcon(
              context,
              icon: Icons.download,
              onPressed: _downloadImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIcon(BuildContext context,
      {required IconData icon, required VoidCallback onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Theme.of(context).colorScheme.background.withOpacity(0.2),
          child: IconButton(
            icon: Icon(icon,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
