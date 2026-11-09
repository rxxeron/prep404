import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/repositories/institution_repository.dart';
import '../../../../core/theme/app_theme.dart';

/// Searchable Dropdown Modal for selecting Schools, Colleges and Madrasahs
class SearchableInstitutionDropdown extends StatefulWidget {
  final String label;
  final String hint;
  final String? searchHint;
  final String selectedName;
  final String selectedEiin;
  final bool isHsc; // true = College + Madrasah, false = School + Madrasah
  final bool isEnglishMedium;
  final String? board;
  final ValueChanged<InstitutionModel> onSelected;

  const SearchableInstitutionDropdown({
    super.key,
    required this.label,
    required this.hint,
    this.searchHint,
    required this.selectedName,
    required this.selectedEiin,
    required this.isHsc,
    this.isEnglishMedium = false,
    this.board,
    required this.onSelected,
  });

  @override
  State<SearchableInstitutionDropdown> createState() => _SearchableInstitutionDropdownState();
}

class _SearchableInstitutionDropdownState extends State<SearchableInstitutionDropdown> {
  void _openSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InstitutionSearchSheet(
        label: widget.label,
        searchHint: widget.searchHint,
        isHsc: widget.isHsc,
        isEnglishMedium: widget.isEnglishMedium,
        board: widget.board,
        onSelected: (inst) {
          Navigator.pop(ctx);
          widget.onSelected(inst);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSelected = widget.selectedName.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _openSearchModal,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? colors.primaryLight.withValues(alpha: 0.3) : colors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colors.primary : colors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.search_rounded,
                  color: isSelected ? colors.primary : colors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: isSelected
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.isEnglishMedium) ...[
                              if (widget.board != null && widget.board!.isNotEmpty)
                                Text(
                                  widget.board!,
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ] else if (widget.selectedEiin.isNotEmpty) ...[
                              Text(
                                'EIIN: ${widget.selectedEiin}',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Text(
                          widget.hint,
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_drop_down_rounded, color: colors.textSecondary, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InstitutionSearchSheet extends StatefulWidget {
  final String label;
  final String? searchHint;
  final bool isHsc;
  final bool isEnglishMedium;
  final String? board;
  final ValueChanged<InstitutionModel> onSelected;

  const _InstitutionSearchSheet({
    required this.label,
    this.searchHint,
    required this.isHsc,
    this.isEnglishMedium = false,
    this.board,
    required this.onSelected,
  });

  @override
  State<_InstitutionSearchSheet> createState() => _InstitutionSearchSheetState();
}

class _InstitutionSearchSheetState extends State<_InstitutionSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final InstitutionRepository _repo = InstitutionRepository();
  List<InstitutionModel> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _results = [];
    _loadInitialInstitutions();
  }

  Future<void> _loadInitialInstitutions() async {
    try {
      if (widget.isEnglishMedium) {
        final list = await _repo.searchEnglishMediumInstitutions(
          '',
          isCollege: widget.isHsc,
          board: widget.board,
          limit: 250,
        );
        if (mounted && _searchCtrl.text.trim().isEmpty) {
          setState(() {
            _results = list.map((e) => e.toInstitutionModel()).toList();
            _isLoading = false;
          });
        }
      } else {
        final list = await _repo.searchInstitutions('', isHsc: widget.isHsc, limit: 100);
        if (mounted && _searchCtrl.text.trim().isEmpty) {
          setState(() {
            _results = list;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _loadInitialInstitutions();
      return;
    }

    // English medium schools might have 2-letter queries (e.g. "IS", "AI", "CGS")
    final minLength = widget.isEnglishMedium ? 2 : 3;
    final hasEnoughChars = trimmed.length >= minLength || query.contains(' ');
    if (!hasEnoughChars) {
      return;
    }

    setState(() => _isLoading = true);
    // Debounce to allow student to finish typing
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (widget.isEnglishMedium) {
        final res = await _repo.searchEnglishMediumInstitutions(
          trimmed,
          isCollege: widget.isHsc,
          board: widget.board,
          limit: 100,
        );
        if (mounted) {
          setState(() {
            _results = res.map((e) => e.toInstitutionModel()).toList();
            _isLoading = false;
          });
        }
      } else {
        final res = await _repo.searchInstitutions(trimmed, isHsc: widget.isHsc, limit: 100);
        if (mounted) {
          setState(() {
            _results = res;
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75 + keyboardHeight,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Column(
            children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field (Starts from 1st word/character)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onQueryChanged,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.searchHint ?? (widget.isHsc
                    ? 'Search college, madrasah name or EIIN...'
                    : 'Search school, madrasah name or EIIN...'),
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: colors.primary, size: 20),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onQueryChanged('');
                            },
                          )
                        : null),
                filled: true,
                fillColor: colors.inputFill,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Results List
          Expanded(
            child: _results.isEmpty && !_isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined, size: 40, color: colors.textMuted),
                          const SizedBox(height: 10),
                          Text(
                            'No institution found',
                            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching by English name or 6-digit EIIN code',
                            style: TextStyle(color: colors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              final query = _searchCtrl.text.trim();
                              if (query.isNotEmpty) {
                                widget.onSelected(
                                  InstitutionModel(
                                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                    eiin: '000000',
                                    nameEn: query.toUpperCase(),
                                    isCollege: widget.isHsc,
                                    isSchool: !widget.isHsc,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: Text('Use "${_searchCtrl.text}"'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: colors.borderSubtle),
                    itemBuilder: (context, index) {
                      final inst = _results[index];
                      final categoryBadge = widget.isEnglishMedium
                          ? (inst.isCollege ? 'College' : 'School')
                          : (inst.isMadrasa
                              ? 'Madrasah'
                              : (widget.isHsc ? 'College' : 'School'));

                      String badgeText = inst.eiin;
                      if (widget.isEnglishMedium) {
                        final bLower = (inst.board ?? inst.eiin).toLowerCase();
                        if (bLower.contains('cambridge') && bLower.contains('edexcel')) {
                          badgeText = 'Dual';
                        } else if (bLower.contains('cambridge')) {
                          badgeText = 'Cambridge';
                        } else if (bLower.contains('edexcel')) {
                          badgeText = 'Edexcel';
                        } else if (bLower.contains('ib')) {
                          badgeText = 'IB';
                        } else {
                          badgeText = 'Intl';
                        }
                      }

                      // Collapse double spaces from legacy BANBEIS records
                      final cleanNameEn = inst.nameEn.replaceAll(RegExp(r'\s+'), ' ').trim();

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          cleanNameEn,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: inst.district != null
                            ? Text(
                                '${inst.district!} • $categoryBadge',
                                style: TextStyle(fontSize: 11, color: colors.textSecondary),
                              )
                            : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            categoryBadge,
                            style: TextStyle(fontSize: 10, color: colors.textSecondary),
                          ),
                        ),
                        onTap: () => widget.onSelected(inst),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  ),
);
}
}
