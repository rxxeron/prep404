/// Model representing an official Prep404 community or social channel
class CommunityLink {
  final String id;
  final String platform;
  final String title;
  final String description;
  final String url;
  final String iconName;
  final int sortOrder;
  final bool isActive;

  const CommunityLink({
    required this.id,
    required this.platform,
    required this.title,
    required this.description,
    required this.url,
    required this.iconName,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory CommunityLink.fromJson(Map<String, dynamic> json) {
    return CommunityLink(
      id: json['id']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'other',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      iconName: json['icon_name']?.toString() ?? json['platform']?.toString() ?? 'other',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'title': title,
      'description': description,
      'url': url,
      'icon_name': iconName,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  static List<CommunityLink> get defaultLinks => const [
        CommunityLink(
          id: 'default-fb',
          platform: 'facebook',
          title: 'Facebook Community Group',
          description:
              'Join 40,000+ admission aspirants for live discussions, study groups, and peer problem solving.',
          url: 'https://facebook.com/groups/prep404',
          iconName: 'facebook',
          sortOrder: 1,
        ),
        CommunityLink(
          id: 'default-ig',
          platform: 'instagram',
          title: 'Instagram',
          description:
              'Daily exam tips, campus life updates, formula reels, and motivational stories.',
          url: 'https://instagram.com/prep404',
          iconName: 'instagram',
          sortOrder: 2,
        ),
        CommunityLink(
          id: 'default-in',
          platform: 'linkedin',
          title: 'LinkedIn Official',
          description:
              'Follow EdTech insights, university admission trends, career roadmaps, and announcements.',
          url: 'https://linkedin.com/company/prep404',
          iconName: 'linkedin',
          sortOrder: 3,
        ),
        CommunityLink(
          id: 'default-tw',
          platform: 'twitter',
          title: 'X (formerly Twitter)',
          description:
              'Breaking admission circulars, exam schedule updates, and live announcements.',
          url: 'https://x.com/prep404',
          iconName: 'twitter',
          sortOrder: 4,
        ),
        CommunityLink(
          id: 'default-yt',
          platform: 'youtube',
          title: 'YouTube Channel',
          description:
              'Video explanations, past year question breakdowns, KaTeX math walkthroughs, and mock test tips.',
          url: 'https://youtube.com/@prep404',
          iconName: 'youtube',
          sortOrder: 5,
        ),
      ];
}
