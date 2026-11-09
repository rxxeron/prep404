import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/community_link.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Screen displaying official Prep404 social networks and community channels
/// dynamically synchronized with the Supabase database.
class CommunityLinksScreen extends StatefulWidget {
  const CommunityLinksScreen({super.key});

  @override
  State<CommunityLinksScreen> createState() => _CommunityLinksScreenState();
}

class _CommunityLinksScreenState extends State<CommunityLinksScreen> {
  static const String _cacheKey = 'community_links_cache';

  List<CommunityLink> _links = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialLinks();
    _fetchLiveLinks();
  }

  void _loadInitialLinks() {
    // 1. Try reading from local cache for instant UI rendering
    final raw = CacheService().read<String>(_cacheKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final parsed = decoded
            .map((e) => CommunityLink.fromJson(e as Map<String, dynamic>))
            .where((link) => link.isActive)
            .toList();
        if (parsed.isNotEmpty) {
          _links = parsed;
        }
      } catch (_) {}
    }

    // 2. Fall back to defaults if cache was empty
    if (_links.isEmpty) {
      _links = CommunityLink.defaultLinks;
    }
  }

  Future<void> _fetchLiveLinks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await SupabaseService().fetchCommunityLinks();
      if (rows.isNotEmpty) {
        final parsed = rows
            .map((r) => CommunityLink.fromJson(r))
            .where((link) => link.isActive)
            .toList();

        if (parsed.isNotEmpty) {
          // Persist to local cache
          CacheService().write(
            _cacheKey,
            jsonEncode(parsed.map((e) => e.toJson()).toList()),
          );

          if (mounted) {
            setState(() {
              _links = parsed;
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _errorMessage = 'Could not refresh latest community channels.';
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openLink(CommunityLink link) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) {
      _showErrorSnackBar('Invalid link: ${link.url}');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showErrorSnackBar('Could not launch ${link.title}');
      }
    } catch (_) {
      if (mounted) {
        _showErrorSnackBar('Could not open external browser for ${link.title}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'twitter':
      case 'x':
        return const Color(0xFF0F1419);
      case 'youtube':
        return const Color(0xFFFF0000);
      default:
        return const Color(0xFFFF7A36);
    }
  }

  IconData _getPlatformIcon(String platform, String iconName) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.groups_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'linkedin':
        return Icons.business_center_rounded;
      case 'twitter':
      case 'x':
        return Icons.tag_rounded;
      case 'youtube':
        return Icons.play_arrow_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Prep404 Community',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: const [
          ThemeToggleIconButton(),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLiveLinks,
        color: colors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A36), Color(0xFF542747)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A36).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.forum_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Connect with Prep404',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Join thousands of admission aspirants across Bangladesh. Stay updated with circular deadlines, solve challenging questions together, and learn from top scorers.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Official Channels',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (_isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  else
                    Text(
                      '${_links.length} Connected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(fontSize: 12, color: colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Dynamic List of Links
              ..._links.map((link) {
                final brandColor = _getPlatformColor(link.platform);
                final iconData = _getPlatformIcon(link.platform, link.iconName);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                    boxShadow: colors.cardShadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openLink(link),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: brandColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                iconData,
                                color: brandColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    link.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  if (link.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      link.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
