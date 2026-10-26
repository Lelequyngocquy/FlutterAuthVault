class VaultItemEntity {
  final String id;
  final String title;
  final String category;
  final String secretSnippet;
  final String securityLevel;
  final DateTime lastAccessed;
  const VaultItemEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.secretSnippet,
    required this.securityLevel,
    required this.lastAccessed,
  });
}
