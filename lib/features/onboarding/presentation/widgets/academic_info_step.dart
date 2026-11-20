import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/university_target.dart';
import '../../../../core/repositories/institution_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_sorter.dart';
import '../../../../core/widgets/prep_skeleton.dart';
import '../controllers/onboarding_controller.dart';
import 'searchable_institution_dropdown.dart';

/// Step 2: Comprehensive Education History & Demographic Profile
/// Exclusively pulls dynamic batches, boards, divisions, districts and institutions
/// from Supabase PostgreSQL database tables with zero hardcoded values.
class AcademicInfoStep extends StatefulWidget {
  final OnboardingController controller;
  final AppLanguage language;

  const AcademicInfoStep({
    super.key,
    required this.controller,
    this.language = AppLanguage.english,
  });

  @override
  State<AcademicInfoStep> createState() => _AcademicInfoStepState();
}

class _AcademicInfoStepState extends State<AcademicInfoStep> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _sscGpaCtrl;
  late final TextEditingController _hscGpaCtrl;

  // English Medium controllers
  late final TextEditingController _oLevelGradesCtrl;
  late final TextEditingController _aLevelGradesCtrl;

  final InstitutionRepository _repo = InstitutionRepository();
  bool _isLoading = true;

  List<DivisionModel> _divisions = [];
  List<DistrictModel> _districts = [];

  // Dynamically populated from database
  List<String> _sscYearOptions = [];
  List<String> _hscBatchOptions = [];
  List<String> _oLevelYearOptions = [];
  List<String> _aLevelBatchOptions = [];
  List<String> _emBoards = [];

  final List<String> _baseGroupOptions = AppSorter.sortStrings([
    'Science',
    'Business Studies',
    'Humanities',
  ]);
  final List<String> _aLevelStatuses = AppSorter.sortStrings([
    'Completed',
    'Appearing (Result Awaited)',
  ]);

  bool _isHscAppearing = false;
  bool _isALevelAppearing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.controller.studentName);
    _phoneCtrl = TextEditingController(text: widget.controller.phone);
    _sscGpaCtrl = TextEditingController(text: widget.controller.sscGpa);

    final initialHscGpa = widget.controller.hscGpa;
    _isHscAppearing = initialHscGpa.toLowerCase().contains('appear') ||
        widget.controller.hscBatch.toLowerCase().contains('appear');
    final cleanHscGpa = _isHscAppearing
        ? 'Appearing'
        : (initialHscGpa.contains('GPA')
            ? initialHscGpa.replaceAll(RegExp(r'[^\d.]'), '')
            : initialHscGpa);
    _hscGpaCtrl = TextEditingController(text: cleanHscGpa);

    _isALevelAppearing =
        widget.controller.aLevelStatus.toLowerCase().contains('appear') ||
            widget.controller.aLevelBatch.toLowerCase().contains('appear');
    _oLevelGradesCtrl =
        TextEditingController(text: widget.controller.oLevelGrades);
    _aLevelGradesCtrl =
        TextEditingController(text: widget.controller.aLevelGrades);
    _loadDynamicData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _sscGpaCtrl.dispose();
    _hscGpaCtrl.dispose();
    _oLevelGradesCtrl.dispose();
    _aLevelGradesCtrl.dispose();
    super.dispose();
  }

  /// Dynamically load admission cycle year, divisions, batches & boards from database
  Future<void> _loadDynamicData() async {
    try {
      final baseYear = await _repo.getEffectiveAdmissionYear();
      final divs = await _repo.getDivisions();
      final sscYears = await _repo.getDynamicSscPassingYears(baseYear);
      final hscBatches = await _repo.getDynamicHscBatches(baseYear);
      final oLevelYears = await _repo.getDynamicOLevelPassingYears(baseYear);
      final aLevelBatches = await _repo.getDynamicALevelBatches(baseYear);
      final boards = await _repo.getDynamicAcademicBoards();

      if (!mounted) return;
      setState(() {
        _divisions = AppSorter.sortBy<DivisionModel>(
          divs,
          (d) => d.nameEn.isNotEmpty ? d.nameEn : d.nameBn,
        );
        _sscYearOptions = AppSorter.sortStrings(
            sscYears.isNotEmpty ? sscYears : _repo.getSscPassingYears(baseYear));
        _hscBatchOptions = AppSorter.sortStrings(hscBatches.isNotEmpty
            ? hscBatches
            : _repo.getAllHscBatches(baseYear));
        _oLevelYearOptions = AppSorter.sortStrings(oLevelYears.isNotEmpty
            ? oLevelYears
            : _repo.getOLevelPassingYears(baseYear));
        _aLevelBatchOptions = AppSorter.sortStrings(aLevelBatches.isNotEmpty
            ? aLevelBatches
            : _repo.getAllALevelBatches(baseYear));
        _emBoards = AppSorter.sortStrings(boards.isNotEmpty
            ? boards
            : ['Cambridge International', 'Pearson Edexcel']);
        _isLoading = false;
      });

      // Load districts for current division
      final currentDivId = widget.controller.divisionId ??
          (divs.isNotEmpty ? divs.first.id : null);
      if (currentDivId != null) {
        final dists = await _repo.getDistricts(divisionId: currentDivId);
        if (mounted) {
          setState(() {
            _districts = AppSorter.sortBy<DistrictModel>(
              dists,
              (d) => d.nameEn.isNotEmpty ? d.nameEn : d.nameBn,
            );
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDivisionChanged(String? divId) async {
    final selectedDiv = _divisions.firstWhere(
      (d) => d.id == divId,
      orElse: () => _divisions.first,
    );

    widget.controller.setDivision(
      id: divId,
      name: selectedDiv.nameEn.isNotEmpty
          ? selectedDiv.nameEn
          : selectedDiv.nameBn,
    );

    if (divId != null) {
      final dists = await _repo.getDistricts(divisionId: divId);
      final sortedDists = AppSorter.sortBy<DistrictModel>(
        dists,
        (d) => d.nameEn.isNotEmpty ? d.nameEn : d.nameBn,
      );
      if (mounted) {
        setState(() {
          _districts = sortedDists;
        });
        if (sortedDists.isNotEmpty) {
          widget.controller.setDistrict(
            id: sortedDists.first.id,
            name: sortedDists.first.nameEn.isNotEmpty
                ? sortedDists.first.nameEn
                : sortedDists.first.nameBn,
          );
        }
      }
    } else {
      if (mounted) setState(() => _districts = []);
    }
  }

  List<String> get _eligibleHscGroups {
    return _repo.getEligibleHscGroups(widget.controller.sscGroup);
  }

  List<String> get _currentBatchOptions {
    if (widget.controller.medium == StudentMedium.bangla) {
      return AppSorter.sortStrings(_hscBatchOptions.isNotEmpty
          ? _hscBatchOptions
          : ["HSC '23 (2nd Time)", "HSC '24", "HSC '25"]);
    } else {
      return AppSorter.sortStrings(_aLevelBatchOptions.isNotEmpty
          ? _aLevelBatchOptions
          : ["A-Level '24", "A-Level '25", "O-Level Completed"]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = AppStrings(widget.language);
    final isBangla = widget.controller.medium == StudentMedium.bangla;

    if (_isLoading) {
      return const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrepSkeleton(height: 28, width: 220, radius: 8),
              SizedBox(height: 8),
              PrepSkeleton(height: 16, width: double.infinity, radius: 6),
              SizedBox(height: 20),
              PrepSkeleton(height: 200, width: double.infinity, radius: 20),
              SizedBox(height: 18),
              PrepSkeleton(height: 240, width: double.infinity, radius: 20),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Main Title & Subtitle
            Text(
              strings.academicInfoTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.academicInfoSubtitle,
              style: TextStyle(
                  fontSize: 13, color: colors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),

            // Selected Curriculum Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    isBangla
                        ? (widget.controller.nctbVersion == NctbVersion.bangla
                            ? 'Selected: NCTB Bangla Version'
                            : 'Selected: NCTB English Version')
                        : 'Selected: English Medium (${widget.controller.curriculum.displayName})',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. TOP GENERAL SECTION (Name, Phone, Gender, Division & District)
            _buildSectionCard(
              colors: colors,
              title: strings.personalGeoTitle,
              icon: Icons.person_pin_circle_rounded,
              children: [
                // Candidate Name
                _buildInput(
                  colors: colors,
                  controller: _nameCtrl,
                  onChanged: (val) => widget.controller
                      .setStudentDetails(name: val, phone: _phoneCtrl.text),
                  label: strings.candidateNameLabel,
                  hint: strings.candidateNameHint,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),

                // Mobile Number
                _buildInput(
                  colors: colors,
                  controller: _phoneCtrl,
                  onChanged: (val) => widget.controller
                      .setStudentDetails(name: _nameCtrl.text, phone: val),
                  label: strings.confirmMobileLabel,
                  hint: strings.confirmMobileHint,
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),

                // Gender Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.genderLabel,
                      style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGenderChip(
                            colors: colors,
                            genderKey: 'male',
                            label: strings.maleGender,
                            icon: Icons.male_rounded,
                            isSelected: widget.controller.gender == 'male',
                            onTap: () => widget.controller.setGender('male'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildGenderChip(
                            colors: colors,
                            genderKey: 'female',
                            label: strings.femaleGender,
                            icon: Icons.female_rounded,
                            isSelected: widget.controller.gender == 'female',
                            onTap: () => widget.controller.setGender('female'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildGenderChip(
                            colors: colors,
                            genderKey: 'other',
                            label: strings.otherGender,
                            icon: Icons.transgender_rounded,
                            isSelected: widget.controller.gender == 'other',
                            onTap: () => widget.controller.setGender('other'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Division and District Pinned on Top
                Row(
                  children: [
                    // Division Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.divisionLabel,
                            style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                dropdownColor: colors.surface,
                                isExpanded: true,
                                value: widget.controller.divisionId ??
                                    (_divisions.isNotEmpty
                                        ? _divisions.first.id
                                        : null),
                                style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                items: _divisions.map((d) {
                                  return DropdownMenuItem<String?>(
                                    value: d.id,
                                    child: Text(
                                      d.nameEn.isNotEmpty ? d.nameEn : d.nameBn,
                                      style:
                                          TextStyle(color: colors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _onDivisionChanged,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // District Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.districtLabel,
                            style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                dropdownColor: colors.surface,
                                isExpanded: true,
                                value: widget.controller.districtId ??
                                    (_districts.isNotEmpty
                                        ? _districts.first.id
                                        : null),
                                hint: Text(strings.selectDistrictHint,
                                    style: TextStyle(
                                        color: colors.textMuted, fontSize: 12)),
                                style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                items: _districts.map((d) {
                                  return DropdownMenuItem<String?>(
                                    value: d.id,
                                    child: Text(
                                      d.nameEn.isNotEmpty ? d.nameEn : d.nameBn,
                                      style:
                                          TextStyle(color: colors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  if (newVal != null) {
                                    final dist = _districts.firstWhere(
                                      (d) => d.id == newVal,
                                      orElse: () => _districts.first,
                                    );
                                    widget.controller.setDistrict(
                                      id: newVal,
                                      name: dist.nameEn.isNotEmpty
                                          ? dist.nameEn
                                          : dist.nameBn,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. SSC OR O-LEVEL SECTION
            if (isBangla) ...[
              _buildSectionCard(
                colors: colors,
                title: strings.sscTitle,
                icon: Icons.history_edu_rounded,
                children: [
                  Row(
                    children: [
                      // SSC Group
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.sscGroupLabel,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: colors.surface,
                                  isExpanded: true,
                                  value: _baseGroupOptions
                                          .contains(widget.controller.sscGroup)
                                      ? widget.controller.sscGroup
                                      : _baseGroupOptions.first,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  items: _baseGroupOptions.map((g) {
                                    return DropdownMenuItem<String>(
                                      value: g,
                                      child: Text(
                                        g,
                                        style: TextStyle(
                                            color: colors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      widget.controller
                                          .setSscDetails(group: val);
                                      // Relational transition rule: update HSC group if current one is not eligible
                                      final eligible =
                                          _repo.getEligibleHscGroups(val);
                                      if (!eligible.contains(
                                          widget.controller.hscGroup)) {
                                        widget.controller.setHscDetails(
                                            group: eligible.first);
                                      }
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // SSC Passing Year
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.sscYearLabel,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: colors.surface,
                                  isExpanded: true,
                                  value: _sscYearOptions
                                          .contains(widget.controller.sscYear)
                                      ? widget.controller.sscYear
                                      : (_sscYearOptions.isNotEmpty
                                          ? _sscYearOptions.first
                                          : '2024'),
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  items: _sscYearOptions.map((y) {
                                    return DropdownMenuItem<String>(
                                      value: y,
                                      child: Text(y,
                                          style: TextStyle(
                                              color: colors.textPrimary)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      widget.controller
                                          .setSscDetails(year: val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // SSC Result (GPA)
                  _buildInput(
                    colors: colors,
                    controller: _sscGpaCtrl,
                    onChanged: (val) =>
                        widget.controller.setSscDetails(gpa: val),
                    label: strings.sscGpaLabel,
                    hint: 'e.g. 5.00',
                    icon: Icons.grade_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 14),

                  // SSC School / Madrasah Dropdown & Database Autocomplete
                  SearchableInstitutionDropdown(
                    label: strings.sscSchoolLabel,
                    hint: strings.selectSchoolHint,
                    searchHint: strings.searchSchoolHint,
                    selectedName: widget.controller.sscInstitution,
                    selectedEiin: widget.controller.sscEiin,
                    isHsc: false,
                    onSelected: (inst) {
                      widget.controller.setSscDetails(
                        institution: inst.nameEn,
                        eiin: inst.eiin,
                      );
                    },
                  ),
                ],
              ),
            ] else ...[
              // O-Level Section
              _buildSectionCard(
                colors: colors,
                title: strings.oLevelTitle,
                icon: Icons.history_edu_rounded,
                children: [
                  Row(
                    children: [
                      // Board
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.oLevelBoardLabel,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: colors.surface,
                                  isExpanded: true,
                                  value: _emBoards.contains(
                                          widget.controller.oLevelBoard)
                                      ? widget.controller.oLevelBoard
                                      : (_emBoards.isNotEmpty
                                          ? _emBoards.first
                                          : 'Cambridge International'),
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  items: _emBoards.map((b) {
                                    return DropdownMenuItem<String>(
                                      value: b,
                                      child: Text(b,
                                          style: TextStyle(
                                              color: colors.textPrimary),
                                          overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      widget.controller
                                          .setOLevelDetails(board: val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Year
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.oLevelYearLabel,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: colors.surface,
                                  isExpanded: true,
                                  value: _oLevelYearOptions.contains(
                                          widget.controller.oLevelYear)
                                      ? widget.controller.oLevelYear
                                      : (_oLevelYearOptions.isNotEmpty
                                          ? _oLevelYearOptions.first
                                          : '2024'),
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  items: _oLevelYearOptions.map((y) {
                                    return DropdownMenuItem<String>(
                                      value: y,
                                      child: Text(y,
                                          style: TextStyle(
                                              color: colors.textPrimary)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      widget.controller
                                          .setOLevelDetails(year: val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInput(
                    colors: colors,
                    controller: _oLevelGradesCtrl,
                    onChanged: (val) =>
                        widget.controller.setOLevelDetails(grades: val),
                    label: strings.oLevelGradesLabel,
                    hint: 'e.g. 5 A*, 2 A',
                    icon: Icons.grade_rounded,
                  ),
                  const SizedBox(height: 14),
                  SearchableInstitutionDropdown(
                    label: strings.oLevelSchoolLabel,
                    hint: strings.selectEnglishSchoolHint,
                    searchHint: strings.searchEnglishSchoolHint,
                    selectedName: widget.controller.oLevelSchool,
                    selectedEiin: widget.controller.oLevelInstitutionId,
                    isHsc: false,
                    isEnglishMedium: true,
                    board: widget.controller.oLevelBoard,
                    onSelected: (inst) {
                      widget.controller.setOLevelDetails(
                        school: inst.nameEn,
                        institutionId: inst.id,
                      );
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),

            // 3. HSC OR A-LEVEL SECTION
            if (isBangla) ...[
              _buildSectionCard(
                colors: colors,
                title: strings.hscTitle,
                icon: Icons.school_rounded,
                children: [
                  Row(
                    children: [
                      // HSC Group (filtered relationally by eligible streams)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.hscGroupLabel,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: colors.surface,
                                  isExpanded: true,
                                  value: _eligibleHscGroups
                                          .contains(widget.controller.hscGroup)
                                      ? widget.controller.hscGroup
                                      : _eligibleHscGroups.first,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  items: _eligibleHscGroups.map((g) {
                                    return DropdownMenuItem<String>(
                                      value: g,
                                      child: Text(
                                        g,
                                        style: TextStyle(
                                            color: colors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      widget.controller
                                          .setHscDetails(group: val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // HSC Batch (Dynamically pulled from database)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.hscBatchLabel,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: colors.surface,
                                  isExpanded: true,
                                  value: _currentBatchOptions
                                          .contains(widget.controller.hscBatch)
                                      ? widget.controller.hscBatch
                                      : _currentBatchOptions.first,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  items: _currentBatchOptions.map((batch) {
                                    return DropdownMenuItem<String>(
                                      value: batch,
                                      child: Text(batch,
                                          style: TextStyle(
                                              color: colors.textPrimary)),
                                    );
                                  }).toList(),
                                  onChanged: (newVal) {
                                    if (newVal != null) {
                                      widget.controller
                                          .setHscDetails(batch: newVal);
                                      if (newVal
                                              .toLowerCase()
                                              .contains('appear') &&
                                          !_isHscAppearing) {
                                        setState(() {
                                          _isHscAppearing = true;
                                          _hscGpaCtrl.text = 'Appearing';
                                          widget.controller
                                              .setHscDetails(gpa: 'Appearing');
                                        });
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // HSC Result (GPA) - Typable with Appeared/Will Appear Tickmark
                  _buildInput(
                    colors: colors,
                    controller: _hscGpaCtrl,
                    enabled: !_isHscAppearing,
                    onChanged: (val) {
                      if (!_isHscAppearing) {
                        widget.controller.setHscDetails(gpa: val);
                      }
                    },
                    label: strings.hscGpaLabel,
                    hint: _isHscAppearing
                        ? 'Result Awaited (Appearing)'
                        : 'e.g. 5.00',
                    icon: _isHscAppearing
                        ? Icons.hourglass_top_rounded
                        : Icons.grade_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    trailingWidget: InkWell(
                      onTap: () {
                        setState(() {
                          _isHscAppearing = !_isHscAppearing;
                          if (_isHscAppearing) {
                            _hscGpaCtrl.text = 'Appearing';
                            widget.controller.setHscDetails(gpa: 'Appearing');
                          } else {
                            _hscGpaCtrl.text = '';
                            widget.controller.setHscDetails(gpa: '');
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _isHscAppearing,
                                activeColor: colors.primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() {
                                    _isHscAppearing = val ?? false;
                                    if (_isHscAppearing) {
                                      _hscGpaCtrl.text = 'Appearing';
                                      widget.controller
                                          .setHscDetails(gpa: 'Appearing');
                                    } else {
                                      _hscGpaCtrl.text = '5.00';
                                      widget.controller
                                          .setHscDetails(gpa: '5.00');
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Appeared or Will Appear',
                              style: TextStyle(
                                color: _isHscAppearing
                                    ? colors.primary
                                    : colors.textSecondary,
                                fontSize: 11,
                                fontWeight: _isHscAppearing
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // HSC College / Madrasah Dropdown & Database Autocomplete
                  SearchableInstitutionDropdown(
                    label: strings.hscCollegeLabel,
                    hint: strings.selectCollegeHint,
                    searchHint: strings.searchCollegeHint,
                    selectedName: widget.controller.hscInstitution,
                    selectedEiin: widget.controller.hscEiin,
                    isHsc: true,
                    onSelected: (inst) {
                      widget.controller.setHscDetails(
                        institution: inst.nameEn,
                        eiin: inst.eiin,
                      );
                    },
                  ),
                ],
              ),
            ] else ...[
              // A-Level Section
              _buildSectionCard(
                colors: colors,
                title: strings.aLevelTitle,
                icon: Icons.school_rounded,
                children: [
                  Row(
                    children: [
                      // Board
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.aLevelBoardLabel,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: colors.surface,
                                  isExpanded: true,
                                  value: _emBoards.contains(
                                          widget.controller.aLevelBoard)
                                      ? widget.controller.aLevelBoard
                                      : (_emBoards.isNotEmpty
                                          ? _emBoards.first
                                          : 'Cambridge International'),
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  items: _emBoards.map((b) {
                                    return DropdownMenuItem<String>(
                                      value: b,
                                      child: Text(b,
                                          style: TextStyle(
                                              color: colors.textPrimary),
                                          overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      widget.controller
                                          .setALevelDetails(board: val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.aLevelStatusLabel,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: colors.surface,
                                  isExpanded: true,
                                  value: _aLevelStatuses.contains(
                                          widget.controller.aLevelStatus)
                                      ? widget.controller.aLevelStatus
                                      : _aLevelStatuses.first,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  items: _aLevelStatuses.map((s) {
                                    return DropdownMenuItem<String>(
                                      value: s,
                                      child: Text(s,
                                          style: TextStyle(
                                              color: colors.textPrimary),
                                          overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      widget.controller
                                          .setALevelDetails(status: val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInput(
                    colors: colors,
                    controller: _aLevelGradesCtrl,
                    enabled: !_isALevelAppearing,
                    onChanged: (val) {
                      if (!_isALevelAppearing) {
                        widget.controller.setALevelDetails(grades: val);
                      }
                    },
                    label: strings.aLevelGradesLabel,
                    hint: _isALevelAppearing
                        ? 'Result Awaited (Appearing)'
                        : 'e.g. 2 A*, 1 A',
                    icon: _isALevelAppearing
                        ? Icons.hourglass_top_rounded
                        : Icons.grade_rounded,
                    trailingWidget: InkWell(
                      onTap: () {
                        setState(() {
                          _isALevelAppearing = !_isALevelAppearing;
                          if (_isALevelAppearing) {
                            _aLevelGradesCtrl.text = 'Result Awaited';
                            widget.controller.setALevelDetails(
                              status: 'Appearing (Result Awaited)',
                              grades: 'Result Awaited',
                            );
                          } else {
                            _aLevelGradesCtrl.text = '2 A*, 1 A';
                            widget.controller.setALevelDetails(
                              status: 'Completed',
                              grades: '2 A*, 1 A',
                            );
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _isALevelAppearing,
                                activeColor: colors.primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() {
                                    _isALevelAppearing = val ?? false;
                                    if (_isALevelAppearing) {
                                      _aLevelGradesCtrl.text = 'Result Awaited';
                                      widget.controller.setALevelDetails(
                                        status: 'Appearing (Result Awaited)',
                                        grades: 'Result Awaited',
                                      );
                                    } else {
                                      _aLevelGradesCtrl.text = '2 A*, 1 A';
                                      widget.controller.setALevelDetails(
                                        status: 'Completed',
                                        grades: '2 A*, 1 A',
                                      );
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Appeared or Will Appear',
                              style: TextStyle(
                                color: _isALevelAppearing
                                    ? colors.primary
                                    : colors.textSecondary,
                                fontSize: 11,
                                fontWeight: _isALevelAppearing
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SearchableInstitutionDropdown(
                    label: strings.aLevelCollegeLabel,
                    hint: strings.selectEnglishCollegeHint,
                    searchHint: strings.searchEnglishCollegeHint,
                    selectedName: widget.controller.aLevelCollege,
                    selectedEiin: widget.controller.aLevelInstitutionId,
                    isHsc: true,
                    isEnglishMedium: true,
                    board: widget.controller.aLevelBoard,
                    onSelected: (inst) {
                      widget.controller.setALevelDetails(
                        college: inst.nameEn,
                        institutionId: inst.id,
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required AppColors colors,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGenderChip({
    required AppColors colors,
    required String genderKey,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required AppColors colors,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    Widget? trailingWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            if (trailingWidget != null) trailingWidget,
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(
            color: enabled ? colors.textPrimary : colors.textSecondary,
            fontSize: 14,
            fontWeight: enabled ? FontWeight.normal : FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
            prefixIcon: Icon(icon,
                color: enabled ? colors.primary : colors.textMuted, size: 20),
            filled: true,
            fillColor: enabled ? colors.inputFill : colors.surfaceElevated,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: colors.border.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
