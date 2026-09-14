import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RideSortBottomSheet extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSortSelected;

  const RideSortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final blackColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final cardBg =
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF18221D) : Colors.white);
    final selectedBg = isDark
        ? const Color(0xFF1F2D26)
        : const Color(0xFFF0F7F4);

    final sortOptions = [
      'Nearest',
      'Lowest Fare',
      'Earliest Departure',
      'Highest Rating',
      'Most Seats Available',
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D3F37) : const Color(0xFFE3EBE6),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort By',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: blackColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: blackColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...sortOptions.map((option) {
            final isSelected = option == currentSort;
            return InkWell(
              onTap: () {
                onSortSelected(option);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                color: isSelected ? selectedBg : cardBg,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? primaryGreen : blackColor,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_rounded, color: primaryGreen),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
