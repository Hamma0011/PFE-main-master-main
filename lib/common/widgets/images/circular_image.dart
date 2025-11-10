import 'package:caferesto/common/widgets/shimmer/shimmer_effect.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CircularImage extends StatelessWidget {
  const CircularImage({
    super.key,
    this.fit = BoxFit.cover,
    required this.image,
    this.isNetworkImage = false,
    this.overlayColor,
    this.backgroundColor,
    this.width = 70,
    this.height = 70,
    this.padding = 2,
    this.isActive = true,
  });

  final BoxFit fit;
  final String image;
  final bool isNetworkImage;
  final Color? overlayColor;
  final Color? backgroundColor;
  final double width, height, padding;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: isNetworkImage
              ? CachedNetworkImage(
                  width: width,
                  height: height,
                  fit: fit,
                  imageUrl: image,
                  progressIndicatorBuilder:
                      (context, url, downloadProgress) => TShimmerEffect(
                          width: width, height: height, radius: 100),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                )
              : Image.asset(
                  image,
                  fit: fit,
                  width: width,
                  height: height,
                )),
    );
  }
}
