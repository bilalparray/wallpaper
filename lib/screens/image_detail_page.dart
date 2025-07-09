import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For Material/SnackBar
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
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
      builder: (context) => CupertinoAlertDialog(
        title: Text('Notice'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
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
      final success = await GallerySaver.saveImage(widget.wallpaper.url);
      _showMessage(success == true ? 'Downloaded to Gallery' : 'Save failed');
    } catch (e) {
      _showMessage('Download failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareImage() async {
    setState(() => _isProcessing = true);
    try {
      final tmpDir = await Directory.systemTemp.createTemp();
      final params = ShareParams(
          text: 'Great picture', files: [XFile('${tmpDir.path}/share.jpg')]);
      await SharePlus.instance.share(params);
    } catch (e) {
      _showMessage('Share failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _setAsWallpaper() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await _ensurePermissions();
    try {
      // Get the file from the cache manager
      final file =
          await DefaultCacheManager().getSingleFile(widget.wallpaper.url);

      // Check if the file exists
      if (await file.exists()) {
        // Set the wallpaper using the file path
        final result = await wallpaperMgr.setWallpaper(
          file, // This should be a String path
          WallpaperManagerPlus.homeScreen,
        );
        await _showMessage(result ?? 'Wallpaper set successfully!');
      } else {
        await _showMessage('File does not exist.');
      }
    } catch (e) {
      await _showMessage('Failed to set wallpaper: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: CupertinoPageScaffold(
        navigationBar:
            CupertinoNavigationBar(middle: const Text('Wallpaper Detail')),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Image.network(
                  widget.wallpaper.url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(CupertinoIcons.xmark)),
                ),
              ),
              if (_isProcessing)
                const Padding(
                    padding: EdgeInsets.all(12),
                    child: CupertinoActivityIndicator()),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
      ),
    );
  }
}
