import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For shadows and BoxDecoration
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:wallpaper/models/wallpaper.dart';

class ImageDetailPage extends StatefulWidget {
  final Wallpaper wallpaper;
  const ImageDetailPage({super.key, required this.wallpaper});

  @override
  State<ImageDetailPage> createState() => _ImageDetailPageState();
}

class _ImageDetailPageState extends State<ImageDetailPage> {
  bool _isProcessing = false;
  final wallpaperMgr = WallpaperManagerPlus();

  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
    } else if (Platform.isIOS) {
      await Permission.photos.request();
    }
  }

  Future<void> _showMessage(String msg) async {
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Notice'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadImage() async {
    setState(() => _isProcessing = true);
    await _ensurePermissions();
    try {
      final success = await GallerySaver.saveImage(
        widget.wallpaper.url,
        albumName: 'Wallpapers',
      );
      await _showMessage(
          success == true ? 'Downloaded to Gallery' : 'Save failed');
    } catch (e) {
      await _showMessage('Download failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareImage() async {
    setState(() => _isProcessing = true);
    try {
      final file =
          await DefaultCacheManager().getSingleFile(widget.wallpaper.url);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out this wallpaper!');
    } catch (e) {
      await _showMessage('Share failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _setAsWallpaper() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await _ensurePermissions();
    try {
      final file =
          await DefaultCacheManager().getSingleFile(widget.wallpaper.url);
      if (await file.exists()) {
        _showWallpaperOptions(file);
      } else {
        await _showMessage('File does not exist.');
      }
    } catch (e) {
      await _showMessage('Failed to set wallpaper: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showWallpaperOptions(File file) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Set Wallpaper'),
        message: const Text('Choose where to set the wallpaper'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _setWallpaper(file, WallpaperManagerPlus.homeScreen);
            },
            child: const Text('Home Screen'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _setWallpaper(file, WallpaperManagerPlus.lockScreen);
            },
            child: const Text('Lock Screen'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _setWallpaper(file, WallpaperManagerPlus.bothScreens);
            },
            child: const Text('Both'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _setWallpaper(File file, int wallpaperType) async {
    try {
      await wallpaperMgr.setWallpaper(file, wallpaperType);
      await _showMessage('Wallpaper set successfully!');
    } catch (e) {
      await _showMessage('Failed to set wallpaper: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Wallpaper Detail'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image Card
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.wallpaper.url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(CupertinoIcons.xmark),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: CupertinoIcons.cloud_download,
                    label: 'Download',
                    onPressed: _isProcessing ? null : _downloadImage,
                  ),
                  _buildActionButton(
                    icon: CupertinoIcons.share,
                    label: 'Share',
                    onPressed: _isProcessing ? null : _shareImage,
                  ),
                  _buildActionButton(
                    icon: CupertinoIcons.photo_on_rectangle,
                    label: 'Set',
                    onPressed: _isProcessing ? null : _setAsWallpaper,
                  ),
                ],
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 24),
                const CupertinoActivityIndicator(radius: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      borderRadius: BorderRadius.circular(12),
      color: CupertinoColors.systemGrey5,
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: CupertinoColors.activeBlue),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: CupertinoColors.activeBlue)),
        ],
      ),
    );
  }
}
