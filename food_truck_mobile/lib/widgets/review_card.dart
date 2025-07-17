import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'star_rating.dart';
import 'package:intl/intl.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final bool isOwner;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const ReviewCard({
    super.key,
    required this.review,
    this.isOwner = false,
    this.onDeleted,
    this.onUpdated,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isMarkedHelpful = false;
  int _helpfulCount = 0;
  bool _isLoading = false;
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _helpfulCount = widget.review.helpfulCount;
    _isMarkedHelpful = widget.review.hasUserVotedHelpful;
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _markAsHelpful() async {
    if (_isMarkedHelpful) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.markReviewHelpful(widget.review.id);
      setState(() {
        _isMarkedHelpful = true;
        _helpfulCount++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as helpful: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.deleteReview(widget.review.id);
      widget.onDeleted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete review: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToReview() async {
    final response = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Review'),
        content: TextField(
          controller: _responseController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write your response...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_responseController.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (response == null || response.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.respondToReview(widget.review.id, response);
      widget.onUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send response: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
      _responseController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isMyReview = authProvider.user?.id == widget.review.userId;
    final canRespond = widget.isOwner && widget.review.response == null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.review.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StarRating(
                            rating: widget.review.rating.toDouble(),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(widget.review.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isMyReview && !_isLoading)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteReview();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Comment
            Text(widget.review.comment),
            
            // Photos
            if (widget.review.photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.review.photos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.review.photos[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Owner Response
            if (widget.review.response != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Response from ${widget.review.response!.respondedBy}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.review.response!.text),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(widget.review.response!.respondedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            
            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                // Helpful button
                if (!isMyReview)
                  TextButton.icon(
                    onPressed: _isLoading ? null : _markAsHelpful,
                    icon: Icon(
                      _isMarkedHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 16,
                    ),
                    label: Text('Helpful ($_helpfulCount)'),
                    style: TextButton.styleFrom(
                      foregroundColor: _isMarkedHelpful ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                const Spacer(),
                // Respond button for owners
                if (canRespond)
                  TextButton.icon(
                    onPressed: _isLoading ? null : _respondToReview,
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Respond'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 