// filepath: lib/features/market/widgets/mizan_image_gallery.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MizanImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final String listingId;
  final bool isAdminMode;
  final VoidCallback? onUpdate;

  const MizanImageGallery({
    super.key,
    required this.imageUrls,
    required this.listingId,
    this.isAdminMode = false,
    this.onUpdate,
  });

  Future<void> _deleteImage(int index, BuildContext context) async {
    final updatedList = List<String>.from(imageUrls)..removeAt(index);
    try {
      await Supabase.instance.client
          .from('market_listings')
          .update({'image_urls': updatedList})
          .eq('id', listingId);
      if (onUpdate != null) onUpdate!();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error deleting image")));
      }
    }
  }

  void _openFullScreen(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScreenViewer(images: imageUrls, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildAdaptiveGrid(context),
      ),
    );
  }

  Widget _buildAdaptiveGrid(BuildContext context) {
    int count = imageUrls.length;
    if (count == 1) return _imageItem(imageUrls[0], 0, context);

    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _imageItem(imageUrls[0], 0, context)),
          const SizedBox(width: 4),
          Expanded(child: _imageItem(imageUrls[1], 1, context)),
        ],
      );
    }

    if (count == 3) {
      return Row(
        children: [
          Expanded(flex: 2, child: _imageItem(imageUrls[0], 0, context)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _imageItem(imageUrls[1], 1, context)),
                const SizedBox(height: 4),
                Expanded(child: _imageItem(imageUrls[2], 2, context)),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _imageItem(imageUrls[0], 0, context)),
              const SizedBox(width: 4),
              Expanded(child: _imageItem(imageUrls[1], 1, context)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _imageItem(imageUrls[2], 2, context)),
              const SizedBox(width: 4),
              Expanded(child: _imageItem(imageUrls[3], 3, context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageItem(String url, int index, BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => _openFullScreen(context, index),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        if (isAdminMode)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _deleteImage(index, context),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class FullScreenViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) => InteractiveViewer(
              child: Image.network(widget.images[i], fit: BoxFit.contain),
            ),
          ),
          if (_currentIndex > 0)
            Positioned(
              left: 10,
              top: MediaQuery.of(context).size.height / 2 - 25,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
          if (_currentIndex < widget.images.length - 1)
            Positioned(
              right: 10,
              top: MediaQuery.of(context).size.height / 2 - 25,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 10 : 8,
                  height: _currentIndex == index ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
