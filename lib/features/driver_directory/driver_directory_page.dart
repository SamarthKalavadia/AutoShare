import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/driver_model.dart';
import 'providers/driver_provider.dart';
import '../../shared/utils/avatar_utils.dart';

class DriverDirectoryPage extends ConsumerStatefulWidget {
  const DriverDirectoryPage({super.key});

  @override
  ConsumerState<DriverDirectoryPage> createState() => _DriverDirectoryPageState();
}

class _DriverDirectoryPageState extends ConsumerState<DriverDirectoryPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final blackColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.colorScheme.primary;
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);

    final searchState = ref.watch(driverSearchProvider);
    final filteredAsync = ref.watch(filteredDriversProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: blackColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Directory',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: blackColor,
              ),
            ),
            Text(
              'Trusted local auto drivers.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(driverSearchProvider.notifier).updateQuery(val),
              decoration: InputDecoration(
                hintText: 'Search by name, area or city…',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E8E93)),
                suffixIcon: searchState.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF8E8E93), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(driverSearchProvider.notifier).updateQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEAE5DD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEAE5DD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: blackColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── Filter chips ──────────────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: DriverFilter.values.map((filter) {
                final selected = searchState.filter == filter;
                final label = switch (filter) {
                  DriverFilter.all => 'All',
                  DriverFilter.available => 'Available',
                  DriverFilter.verified => 'Verified',
                };
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? blackColor : mutedText,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(driverSearchProvider.notifier).updateFilter(filter),
                    selectedColor: primaryColor,
                    backgroundColor: Colors.white,
                    checkmarkColor: blackColor,
                    side: BorderSide(
                      color: selected ? primaryColor : const Color(0xFFEAE5DD),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFF6C000)),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: GoogleFonts.inter(color: const Color(0xFF6F6F72))),
              ),
              data: (drivers) {
                if (drivers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car_outlined,
                            size: 64, color: Color(0xFFCCCCCC)),
                        const SizedBox(height: 16),
                        Text(
                          'No drivers found.',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6F6F72),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: drivers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _DriverCard(
                      driver: drivers[index],
                      index: index,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Driver Card ───────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  final int index;

  const _DriverCard({required this.driver, required this.index});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open: $urlString'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const blackColor = Color(0xFF121212);
    const primaryColor = Color(0xFFF6C000);
    const successColor = Color(0xFF2E7D32);
    const mutedText = Color(0xFF6F6F72);
    const borderColor = Color(0xFFEAE5DD);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F121212),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {}, // Future: open detail page
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ──────────────────────────────────────────────
                  _DriverAvatar(driver: driver),
                  const SizedBox(width: 14),
                  // ── Info ────────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + rating row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                driver.name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: blackColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded,
                                size: 14, color: primaryColor),
                            const SizedBox(width: 2),
                            Text(
                              driver.rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: blackColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Area · City
                        Text(
                          '${driver.area} · ${driver.city}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Badges row
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (driver.verified)
                              _Badge(
                                label: 'Verified',
                                icon: Icons.verified_rounded,
                                color: successColor,
                                bgColor: const Color(0xFFEAF5ED),
                              ),
                            _Badge(
                              label: driver.available ? 'Available' : 'Unavailable',
                              icon: driver.available
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: driver.available
                                  ? successColor
                                  : const Color(0xFFD32F2F),
                              bgColor: driver.available
                                  ? const Color(0xFFEAF5ED)
                                  : const Color(0xFFFDECEC),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Phone number
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 13, color: mutedText),
                            const SizedBox(width: 4),
                            Text(
                              '+${driver.phoneNumber}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: mutedText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label: 'Call',
                                icon: Icons.call_rounded,
                                bgColor: blackColor,
                                fgColor: Colors.white,
                                onTap: () => _launchUrl(
                                  context,
                                  'tel:+${driver.phoneNumber}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ActionButton(
                                label: 'WhatsApp',
                                icon: Icons.chat_rounded,
                                bgColor: const Color(0xFF25D366),
                                fgColor: Colors.white,
                                onTap: () => _launchUrl(
                                  context,
                                  'https://wa.me/${driver.phoneNumber}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Driver Avatar ─────────────────────────────────────────────────────────────

class _DriverAvatar extends StatelessWidget {
  final DriverModel driver;
  const _DriverAvatar({required this.driver});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: getAvatarImageProvider(driver.profileImage) != null
            ? Image(
                image: getAvatarImageProvider(driver.profileImage)!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _Initials(name: driver.name),
              )
            : _Initials(name: driver.name),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: const Color(0xFFF8F3E7),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121212),
          ),
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: fgColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
