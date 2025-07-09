// lib/screens/home_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wallpaper/api/apiservice.dart';
import 'package:wallpaper/models/wallpaper.dart';
import 'package:wallpaper/screens/image_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _api = ApiService();

  List<Wallpaper> _wallpapers = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final images = await _api.getImages(
          query: _searchQuery.isEmpty
              ? 'yellow+flowers'
              : _searchQuery.replaceAll(' ', '+'));
      setState(() {
        _wallpapers = images;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Cupertino Wallpapers'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: CupertinoSearchTextField(
                placeholder: 'Search wallpapers...',
                onSubmitted: (value) {
                  _searchQuery = value;
                  _loadImages();
                },
              ),
            ),

            // status
            if (_isLoading) ...[
              const Expanded(child: Center(child: CupertinoActivityIndicator()))
            ] else if (_error != null) ...[
              Expanded(child: Center(child: Text('Error: $_error')))
            ] else if (_wallpapers.isEmpty) ...[
              const Expanded(child: Center(child: Text('No images found')))
            ] else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _wallpapers.length,
                  itemBuilder: (context, i) {
                    final item = _wallpapers[i];
                    return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) =>
                                    ImageDetailPage(wallpaper: item),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.network(
                                    item.url,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(
                                      height: 180,
                                      child: Center(
                                          child: Icon(CupertinoIcons.xmark)),
                                    ),
                                  ),
                                ),

                                // Text info
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.photographer,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(item.id,
                                          style: const TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ));
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
