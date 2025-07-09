import 'dart:io';
import 'package:flutter/cupertino.dart';
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
      // Download to temp file
      final file =
          await DefaultCacheManager().getSingleFile(widget.wallpaper.url);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Great picture!');
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
        message: const Text('Choose where to set the wallpaper:'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Home Screen'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _setWallpaper(file, WallpaperManagerPlus.homeScreen);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Lock Screen'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _setWallpaper(file, WallpaperManagerPlus.lockScreen);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Both'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _setWallpaper(file, WallpaperManagerPlus.bothScreens);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _setWallpaper(File file, int wallpaperType) async {
    try {
      await wallpaperMgr.setWallpaper(
        file,
        wallpaperType,
      );
      await _showMessage('Wallpaper set successfully!');
    } catch (e) {
      await _showMessage('Failed to set wallpaper');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Wallpaper Detail'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                widget.wallpaper.url,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(CupertinoIcons.xmark),
                ),
              ),
            ),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CupertinoActivityIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CupertinoButton(
                      onPressed: _isProcessing ? null : _downloadImage,
                      child: const Text('Download'),
                    ),
                    CupertinoButton(
                      onPressed: _isProcessing ? null : _shareImage,
                      child: const Text('Share'),
                    ),
                    CupertinoButton(
                      onPressed: _isProcessing ? null : _setAsWallpaper,
                      child: const Text('Set as wallpaper'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
