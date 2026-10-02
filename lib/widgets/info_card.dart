import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String trailing;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onMapTap; // 💡 新增：點擊地圖圖示的動作

  const InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.trailing,
    this.margin,
    this.onTap,
    this.onMapTap,
  });

  // 💡 核心自動修復功能：將卡片的 Google Drive 連結轉為直連
  String _convertDriveUrl(String url) {
    if (url.contains('drive.google.com')) {
      if (url.contains('/file/d/')) {
        final parts = url.split('/file/d/');
        if (parts.length > 1) {
          final id = parts[1].split('/')[0];
          return 'https://drive.google.com/uc?export=view&id=$id';
        }
      } else if (url.contains('id=')) {
        final parts = url.split('id=');
        if (parts.length > 1) {
          final id = parts[1].split('&')[0];
          return 'https://drive.google.com/uc?export=view&id=$id';
        }
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    // 💡 轉換為修復後的網址
    final String fixedImageUrl = _convertDriveUrl(imageUrl);

    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.network(
                    fixedImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                      );
                    },
                  ),
                ),
                // 💡 在圖片右上角加入地圖按鈕
                if (onMapTap != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onMapTap,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        radius: 18,
                        child: const Icon(Icons.map, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textTitle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(trailing, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppColors.textBody, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}