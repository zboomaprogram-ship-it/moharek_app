import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/shared/widgets/empty_state.dart';
import 'package:moharek_app/shared/widgets/shimmer_placeholders.dart';
import 'package:moharek_app/shared/utils/file_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'all',
    'brand_asset',
    'strategy',
    'report',
    'contract',
    'design',
    'keyword_research',
  ];

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(filesProvider);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.filesCenter)),
      body: Column(
        children: [
          _buildCategoryFilter(l10n),
          Expanded(
            child: filesAsync.when(
              loading: () => const ShimmerList(itemCount: 6, itemHeight: 80),
              error: (err, _) => Center(child: Text(l10n.errorOccurred(err.toString()))),
              data: (files) {
                final filteredFiles = _selectedCategory == 'all'
                    ? files
                    : files.where((f) => f['file_type'] == _selectedCategory).toList();

                if (filteredFiles.isEmpty) {
                  return EmptyState.files(context);
                }

                return RefreshIndicator(
                  color: AppTheme.primaryGreen,
                  onRefresh: () async {
                    ref.invalidate(filesProvider);
                    HapticService.light();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredFiles.length,
                    itemBuilder: (context, index) {
                      final file = filteredFiles[index];
                      return _buildFileTile(context, file, l10n);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(_getCategoryLabel(cat, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  HapticService.light();
                  setState(() => _selectedCategory = cat);
                }
              },
              backgroundColor: AppTheme.cardColor,
              selectedColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFileTile(BuildContext context, Map<String, dynamic> file, AppLocalizations l10n) {
    final name = file['name'] ?? 'Unnamed File';
    final type = file['file_type'] ?? 'other';
    final url = file['file_url'] as String?;
    final date = DateTime.parse(file['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getCategoryColor(type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIconForType(type), color: _getCategoryColor(type)),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_getCategoryLabel(type, l10n)} • ${date.day}/${date.month}/${date.year}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_rounded, color: AppTheme.primaryGreen),
          onPressed: () => _openFile(context, url, name),
        ),
        onTap: () => _openFile(context, url, name),
      ),
    );
  }

  String _getCategoryLabel(String cat, AppLocalizations l10n) {
    switch (cat) {
      case 'all': return l10n.allTab;
      case 'brand_asset': return 'Brand Assets';
      case 'strategy': return 'Strategy';
      case 'report': return 'Reports';
      case 'contract': return 'Contracts';
      case 'design': return 'Design';
      case 'keyword_research': return 'Keywords';
      default: return cat.toUpperCase();
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'brand_asset': return Icons.palette_outlined;
      case 'strategy': return Icons.auto_graph_outlined;
      case 'report': return Icons.description_outlined;
      case 'contract': return Icons.gavel_outlined;
      case 'design': return Icons.draw_outlined;
      case 'keyword_research': return Icons.key_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Color _getCategoryColor(String type) {
    switch (type) {
      case 'brand_asset': return Colors.purpleAccent;
      case 'strategy': return AppTheme.primaryBlue;
      case 'report': return AppTheme.primaryGreen;
      case 'contract': return Colors.amber;
      case 'design': return Colors.pinkAccent;
      case 'keyword_research': return Colors.tealAccent;
      default: return Colors.grey;
    }
  }

  Future<void> _openFile(BuildContext context, String? url, String title) async {
    if (url == null) return;
    await openFileInApp(context, url, title);
  }
}
