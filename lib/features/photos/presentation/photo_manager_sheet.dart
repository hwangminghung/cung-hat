import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../profile/application/profile_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../application/photo_providers.dart';

const _maxSlots = 6;

/// Default gallery pick used in production. Overridden in widget tests via the
/// [PhotoManagerSheet.pickBytes] seam so tests never touch a real gallery.
Future<Uint8List?> _defaultPick() async {
  final x = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1080,
    imageQuality: 85,
  );
  if (x == null) return null;
  return x.readAsBytes();
}

/// Bottom sheet to manage the current user's profile photos (max [_maxSlots]).
///
/// Consent-gated: reads the `photos` consent via [myConsentsProvider]. If it is
/// not granted, the grid is replaced by a short notice + a CTA that links to
/// `/settings`. When granted, it renders [_maxSlots] square slots — each either
/// a photo thumbnail or a "+" add tile.
///
/// [pickBytes] is injectable for deterministic widget tests; it defaults to a
/// real gallery pick.
class PhotoManagerSheet extends ConsumerStatefulWidget {
  const PhotoManagerSheet({super.key, Future<Uint8List?> Function()? pickBytes})
    : pickBytes = pickBytes ?? _defaultPick;

  final Future<Uint8List?> Function() pickBytes;

  @override
  ConsumerState<PhotoManagerSheet> createState() => _PhotoManagerSheetState();
}

class _PhotoManagerSheetState extends ConsumerState<PhotoManagerSheet> {
  /// The slot index with an in-flight upload/remove, or null when idle. While
  /// non-null every add/remove affordance is disabled to avoid a lost-update
  /// race on the photo-path list.
  int? _busySlot;

  String? get _currentUserId =>
      ref.read(supabaseClientProvider).auth.currentUser?.id;

  Future<void> _refresh(String userId) async {
    ref.invalidate(myProfileProvider);
    ref.invalidate(signedUrlsProvider(userId));
  }

  Future<void> _add(int slot) async {
    if (_busySlot != null) return;
    final userId = _currentUserId;
    if (userId == null) return;
    setState(() => _busySlot = slot);
    try {
      final bytes = await widget.pickBytes();
      if (bytes == null) return; // user cancelled the picker
      await ref
          .read(photoRepositoryProvider)
          .uploadPhoto(
            bytes,
            slot: slot,
            current: ref.read(myPhotoPathsProvider),
          );
      await _refresh(userId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải được ảnh. Thử lại nhé.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busySlot = null);
    }
  }

  Future<void> _remove(int slot, String path) async {
    if (_busySlot != null) return;
    final userId = _currentUserId;
    if (userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá ảnh này?'),
        content: const Text('Ảnh sẽ bị gỡ khỏi hồ sơ của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busySlot = slot);
    try {
      await ref
          .read(photoRepositoryProvider)
          .removePhoto(path, current: ref.read(myPhotoPathsProvider));
      await _refresh(userId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không xoá được ảnh. Thử lại nhé.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busySlot = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final consents = ref.watch(myConsentsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        // Scrollable: at _maxSlots=6 the 2-row grid of square slots is taller
        // than a fixed-height Column tolerates on short viewports. The sheet is
        // presented via showModalBottomSheet(isScrollControlled: true) in
        // home_shell.dart, so growing/scrolling here is the intended behavior
        // rather than a workaround.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Ảnh hồ sơ', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Thêm tối đa $_maxSlots ảnh để hồ sơ nổi bật hơn.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              consents.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const _ConsentGate(),
                data: (map) => (map['photos'] == true)
                    ? _buildGrid()
                    : const _ConsentGate(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final userId = _currentUserId;
    final urlsAsync = userId == null
        ? const AsyncValue<List<String>>.data(<String>[])
        : ref.watch(signedUrlsProvider(userId));
    final urls = urlsAsync.value ?? const <String>[];
    final paths = ref.watch(myPhotoPathsProvider);
    // 2-row x 3-col grid (was a single Row of 3, which would overflow at
    // _maxSlots=6). GridView over a Row keeps each slot's own widget/keys/
    // busy-logic untouched — only the container layout changes.
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < _maxSlots; i++)
          _PhotoSlot(
            key: Key('photo_slot_$i'),
            // Slots fill left-to-right, top-to-bottom from the existing photo
            // list. `paths` and `urls` are two independently-fetched lists
            // zipped by index: `signedUrlsProvider` returns URLs positionally
            // aligned to `photoPaths` (same order, server-signed by the
            // `sign-photo` edge function over the same `photo_paths` array),
            // so index `i` is a valid join key. A shorter `urls` list degrades
            // to the grey placeholder by design.
            path: i < paths.length ? paths[i] : null,
            url: i < urls.length ? urls[i] : null,
            busy: _busySlot == i,
            disabled: _busySlot != null && _busySlot != i,
            onAdd: () => _add(i),
            onRemove: (path) => _remove(i, path),
          ),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    super.key,
    required this.path,
    required this.url,
    required this.busy,
    required this.disabled,
    required this.onAdd,
    required this.onRemove,
  });

  final String? path;
  final String? url;
  final bool busy;
  final bool disabled;
  final VoidCallback onAdd;
  final void Function(String path) onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = path != null;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto && url != null)
                Image.network(url!, fit: BoxFit.cover)
              else if (hasPhoto)
                const ColoredBox(color: AppColors.surfaceMuted)
              else
                const Center(
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    color: AppColors.textHint,
                  ),
                ),
              // Tap layer: add on empty, remove on filled. Disabled while any
              // slot has an in-flight op.
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: (busy || disabled)
                      ? null
                      : (hasPhoto ? () => onRemove(path!) : onAdd),
                ),
              ),
              if (hasPhoto && !busy)
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ),
                ),
              if (busy)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the `photos` consent is not granted: a short notice + a CTA that
/// takes the user to Settings to flip the toggle.
class _ConsentGate extends StatelessWidget {
  const _ConsentGate();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.primaryDark),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bật đồng ý dùng ảnh để thêm ảnh vào hồ sơ.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const Key('photos_consent_cta'),
            onPressed: () => context.push('/settings'),
            child: const Text('Bật trong Cài đặt'),
          ),
        ],
      ),
    );
  }
}
