import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_assets.dart';
import '../models/letter.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class WritePage extends StatefulWidget {
  const WritePage({super.key});

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  DateTime? _unlockAt;
  bool _isPublic = false;
  bool _busy = false;
  Timer? _draftSaveTimer;

  @override
  void initState() {
    super.initState();
    final draft = context.read<LocalStorageService>().getDraft();
    if (draft != null && !draft.isEmpty) {
      _titleCtrl.text = draft.title;
      _contentCtrl.text = draft.content;
      _unlockAt = draft.unlockAt;
      _isPublic = draft.isPublic;
    }
    _titleCtrl.addListener(_scheduleDraftSave);
    _contentCtrl.addListener(_scheduleDraftSave);
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _scheduleDraftSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 600), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final draft = LetterDraft(
      title: _titleCtrl.text,
      content: _contentCtrl.text,
      unlockAt: _unlockAt,
      isPublic: _isPublic,
      savedAt: DateTime.now(),
    );
    if (draft.isEmpty) {
      await context.read<LocalStorageService>().clearDraft();
    } else {
      await context.read<LocalStorageService>().saveDraft(draft);
    }
  }

  Future<void> _pickUnlockAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _unlockAt ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(minutes: 1)),
      lastDate: DateTime(now.year + 50),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _unlockAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _unlockAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
    _scheduleDraftSave();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_unlockAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an unlock date.')),
      );
      return;
    }
    if (!_unlockAt!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlock date must be in the future.')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final letter = Letter(
        id: '',
        authorId: user.uid,
        authorName: user.displayName,
        authorPhotoUrl: user.photoUrl,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        createdAt: DateTime.now(),
        unlockAt: _unlockAt!,
        isPublic: _isPublic,
      );
      final fs = context.read<FirestoreService>();
      final storage = context.read<LocalStorageService>();
      await fs.createLetter(letter);
      await storage.clearDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Letter sealed.')));
      _titleCtrl.clear();
      _contentCtrl.clear();
      setState(() {
        _unlockAt = null;
        _isPublic = false;
      });
      context.go('/vault');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write to Future Me'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final compactHeight = constraints.maxHeight < 680;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 760 : 520),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 24 : 16,
                    compactHeight ? 6 : 8,
                    wide ? 24 : 16,
                    compactHeight ? 8 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WritingHero(height: compactHeight ? 112 : 136),
                      SizedBox(height: compactHeight ? 8 : 10),
                      Expanded(
                        child: _LetterPaper(
                          titleCtrl: _titleCtrl,
                          contentCtrl: _contentCtrl,
                          compact: compactHeight,
                        ),
                      ),
                      SizedBox(height: compactHeight ? 8 : 10),
                      _SealPanel(
                        unlockAt: _unlockAt,
                        isPublic: _isPublic,
                        busy: _busy,
                        compact: compactHeight,
                        onPickUnlockAt: _pickUnlockAt,
                        onPublicChanged: (v) {
                          setState(() => _isPublic = v);
                          _scheduleDraftSave();
                        },
                        onSubmit: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WritingHero extends StatelessWidget {
  final double height;

  const _WritingHero({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.writeLetterDesk,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.surface.withValues(alpha: 0.1),
                    scheme.surface.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    AppAssets.navWrite,
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Dear future me,',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Keep today somewhere time can find it.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterPaper extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController contentCtrl;
  final bool compact;

  const _LetterPaper({
    required this.titleCtrl,
    required this.contentCtrl,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        compact ? 12 : 14,
        14,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                AppAssets.sakuraSealedLetter,
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A page for future-you',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Start with what today feels like.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          TextFormField(
            key: const Key('title-field'),
            controller: titleCtrl,
            textInputAction: TextInputAction.next,
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
            decoration: _letterDecoration(
              context,
              label: 'Opening line',
              hint: 'Dear future me...',
            ),
            maxLength: 80,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
          ),
          SizedBox(height: compact ? 2 : 4),
          Expanded(
            child: TextFormField(
              key: const Key('content-field'),
              controller: contentCtrl,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              textAlignVertical: TextAlignVertical.top,
              expands: true,
              maxLines: null,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.48),
              decoration: _letterDecoration(
                context,
                label: 'The letter',
                hint: 'Tell future-you what matters about this moment.',
                alignLabelWithHint: true,
              ),
              maxLength: 2000,
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Write at least a few words.'
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _letterDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    bool alignLabelWithHint = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final baseBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    );
  }
}

class _SealPanel extends StatelessWidget {
  final DateTime? unlockAt;
  final bool isPublic;
  final bool busy;
  final bool compact;
  final VoidCallback onPickUnlockAt;
  final ValueChanged<bool> onPublicChanged;
  final VoidCallback onSubmit;

  const _SealPanel({
    required this.unlockAt,
    required this.isPublic,
    required this.busy,
    required this.compact,
    required this.onPickUnlockAt,
    required this.onPublicChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                AppAssets.navVault,
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fold and seal', style: theme.textTheme.titleSmall),
                    if (!compact) ...[
                      const SizedBox(height: 1),
                      Text(
                        'The next chapter begins when this opens again.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          _UnlockDateTile(
            unlockAt: unlockAt,
            compact: compact,
            onTap: onPickUnlockAt,
          ),
          SizedBox(height: compact ? 8 : 10),
          Row(
            children: [
              Expanded(
                child: _PublicChoice(
                  isPublic: isPublic,
                  compact: compact,
                  onChanged: onPublicChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: compact ? 50 : 54,
                  child: FilledButton.icon(
                    key: const Key('submit-button'),
                    onPressed: busy ? null : onSubmit,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Image.asset(
                            AppAssets.navVault,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                    label: Text(
                      busy ? 'Sealing...' : 'Seal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _UnlockDateTile extends StatelessWidget {
  final DateTime? unlockAt;
  final bool compact;
  final VoidCallback onTap;

  const _UnlockDateTile({
    required this.unlockAt,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateText = unlockAt == null
        ? 'Choose when it returns'
        : DateFormat.yMMMd().add_jm().format(unlockAt!);

    return Material(
      color: scheme.tertiaryContainer.withValues(alpha: 0.52),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: const Key('unlock-tile'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            compact ? 8 : 10,
            10,
            compact ? 8 : 10,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                decoration: BoxDecoration(
                  color: scheme.tertiary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: scheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateText, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      unlockAt == null
                          ? 'A sealed letter needs a day to come home.'
                          : 'Future-you will meet this note then.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unlockAt == null ? 'Pick' : 'Change',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.tertiary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicChoice extends StatelessWidget {
  final bool isPublic;
  final bool compact;
  final ValueChanged<bool> onChanged;

  const _PublicChoice({
    required this.isPublic,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      height: compact ? 50 : 54,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.navWall,
            width: compact ? 26 : 28,
            height: compact ? 26 : 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPublic ? 'Public wall' : 'Private',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Switch(
            key: const Key('public-switch'),
            value: isPublic,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
