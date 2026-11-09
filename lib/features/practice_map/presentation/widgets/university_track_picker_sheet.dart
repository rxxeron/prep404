import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/university_target.dart';
import '../../../../core/services/admission_plan_service.dart';
import '../../../../core/widgets/university_logo.dart';

class UniversityTrackPickerSheet extends StatelessWidget {
  final AdmissionJourneyData journey;
  final String activeUniversityKey;
  final String activeTrack;
  final ValueChanged<String> onUniversitySelected;
  final ValueChanged<String> onTrackSelected;
  final String Function(String) formatTrackName;

  const UniversityTrackPickerSheet({
    super.key,
    required this.journey,
    required this.activeUniversityKey,
    required this.activeTrack,
    required this.onUniversitySelected,
    required this.onTrackSelected,
    required this.formatTrackName,
  });

  static const colorCardPlum = Color(0xFF2E1329);
  static const colorPlumBorder = Color(0xFF542747);
  static const colorTangerine = Color(0xFFFF7A36);
  static const colorCream = Color(0xFFFFF7ED);

  @override
  Widget build(BuildContext context) {
    final catalog = UniversityCatalog.universities;
    final availableTracks = journey.availableTracks.isNotEmpty
        ? journey.availableTracks
        : const ['engineering', 'business', 'pharmacy', 'architecture'];

    return Container(
      padding: const EdgeInsets.all(22),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colorCardPlum,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colorPlumBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorCream.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Target University',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorCream,
            ),
          ),
          const SizedBox(height: 12),

          // Universities Grid
          SizedBox(
            height: 150,
            child: GridView.builder(
              itemCount: catalog.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, idx) {
                final u = catalog[idx];
                final isSel = u.id == activeUniversityKey;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    onUniversitySelected(u.id);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSel
                          ? colorTangerine.withValues(alpha: 0.25)
                          : const Color(0xFF1B0718),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? colorTangerine : colorPlumBorder,
                        width: isSel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        UniversityLogo(universityKey: u.id, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          u.code,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSel ? colorTangerine : colorCream,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Target Program / Faculty Track',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colorCream,
            ),
          ),
          const SizedBox(height: 10),

          // Track Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTracks.map((track) {
              final isSelected = track == activeTrack;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                  onTrackSelected(track);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorTangerine
                        : const Color(0xFF1B0718),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? colorCream : colorPlumBorder,
                      width: isSelected ? 1.3 : 1.0,
                    ),
                  ),
                  child: Text(
                    formatTrackName(track),
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : colorCream,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
