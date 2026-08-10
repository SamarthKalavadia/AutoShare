import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/rating_model.dart';
import '../../../data/repositories/rating_repository.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../providers/ratings_prompt_provider.dart';

class RatingBottomSheet extends ConsumerStatefulWidget {
  final PendingRatingPrompt prompt;

  const RatingBottomSheet({super.key, required this.prompt});

  static void show(BuildContext context, PendingRatingPrompt prompt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: RatingBottomSheet(prompt: prompt),
      ),
    );
  }

  @override
  ConsumerState<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends ConsumerState<RatingBottomSheet> {
  int _selectedRating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool skipped) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final repo = ref.read(ratingRepositoryProvider);
    final ratingModel = RatingModel(
      ratingId: '',
      rideId: widget.prompt.ride.id,
      fromUserId: user.uid,
      toUserId: widget.prompt.toUserId,
      rating: skipped ? 0 : _selectedRating,
      review: skipped ? '' : _reviewController.text.trim(),
      createdAt: DateTime.now(),
    );

    await repo.submitRating(ratingModel);

    // Invalidate the prompt provider so it re-checks
    ref.invalidate(ratingsPromptProvider);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Rate Your Ride',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121212),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How was your trip with ${widget.prompt.toUserName}?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6E6E73),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isSelected = _selectedRating >= starValue;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = starValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 52,
                    color: isSelected ? const Color(0xFFF6C000) : const Color(0xFFE0E0E0),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _reviewController,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add an optional review...',
              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
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
                borderSide: const BorderSide(color: Color(0xFF121212)),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isSubmitting ? null : () => _submit(true),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6E6E73),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: (_isSubmitting || _selectedRating == 0) ? null : () => _submit(false),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF121212),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
