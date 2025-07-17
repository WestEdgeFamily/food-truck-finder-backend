import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color filledColor;
  final Color unfilledColor;
  final bool isInteractive;
  final Function(int)? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24,
    this.filledColor = Colors.amber,
    this.unfilledColor = Colors.grey,
    this.isInteractive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starNumber = index + 1;
        final filled = rating >= starNumber;
        final halfFilled = rating > index && rating < starNumber;

        return GestureDetector(
          onTap: isInteractive && onRatingChanged != null
              ? () => onRatingChanged!(starNumber)
              : null,
          child: Icon(
            halfFilled ? Icons.star_half : Icons.star,
            size: size,
            color: filled || halfFilled ? filledColor : unfilledColor,
          ),
        );
      }),
    );
  }
}

class StarRatingWithCount extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double starSize;
  final TextStyle? textStyle;

  const StarRatingWithCount({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.starSize = 16,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(
          rating: rating,
          size: starSize,
        ),
        const SizedBox(width: 4),
        Text(
          '${rating.toStringAsFixed(1)} ($reviewCount)',
          style: textStyle ?? Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
} 