import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';

class SendAnnouncementScreen extends ConsumerStatefulWidget {
  const SendAnnouncementScreen({super.key});

  @override
  ConsumerState<SendAnnouncementScreen> createState() =>
      _SendAnnouncementScreenState();
}

class _SendAnnouncementScreenState
    extends ConsumerState<SendAnnouncementScreen> {
  int _step = 0;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  AnnouncementAudience _audience = AnnouncementAudience.all;
  String? _selectedDisciplineId;
  AnnouncementChannel _channel = AnnouncementChannel.push;

  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  bool get _step0Valid =>
      _titleCtrl.text.trim().isNotEmpty && _bodyCtrl.text.trim().isNotEmpty;

  bool get _step1Valid =>
      _audience == AnnouncementAudience.all || _selectedDisciplineId != null;

  void _next() {
    if (_step < 3) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(sendAnnouncementUseCaseProvider)
          .call(
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            channel: _channel,
            audience: _audience,
            disciplineId: _selectedDisciplineId,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Announcement'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: AppColors.primaryVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: switch (_step) {
            0 => _StepCompose(titleCtrl: _titleCtrl, bodyCtrl: _bodyCtrl),
            1 => _StepAudience(
              audience: _audience,
              selectedDisciplineId: _selectedDisciplineId,
              onAudienceChanged: (v) => setState(() {
                _audience = v;
                if (v == AnnouncementAudience.all) _selectedDisciplineId = null;
              }),
              onDisciplineChanged: (v) =>
                  setState(() => _selectedDisciplineId = v),
            ),
            2 => _StepChannel(
              channel: _channel,
              onChanged: (v) => setState(() => _channel = v),
            ),
            _ => _StepConfirm(
              title: _titleCtrl.text.trim(),
              body: _bodyCtrl.text.trim(),
              audience: _audience,
              disciplineId: _selectedDisciplineId,
              channel: _channel,
              sending: _sending,
              error: _error,
            ),
          },
        ),
      ),
      bottomNavigationBar: _NavBar(
        step: _step,
        canAdvance: _step == 0
            ? _step0Valid
            : _step == 1
            ? _step1Valid
            : true,
        sending: _sending,
        onBack: _back,
        onNext: _step < 3 ? _next : _send,
      ),
    );
  }
}

// ── Step 0 — Compose ───────────────────────────────────────────────────────

class _StepCompose extends StatelessWidget {
  const _StepCompose({required this.titleCtrl, required this.bodyCtrl});

  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(context, '1 of 4', 'Compose your message'),
          const SizedBox(height: 24),
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Dojo closed this Saturday',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: bodyCtrl,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'What would you like to tell your members?',
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}

// ── Step 1 — Audience ──────────────────────────────────────────────────────

class _StepAudience extends ConsumerWidget {
  const _StepAudience({
    required this.audience,
    required this.selectedDisciplineId,
    required this.onAudienceChanged,
    required this.onDisciplineChanged,
  });

  final AnnouncementAudience audience;
  final String? selectedDisciplineId;
  final ValueChanged<AnnouncementAudience> onAudienceChanged;
  final ValueChanged<String?> onDisciplineChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplines = ref.watch(disciplineListProvider).asData?.value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(context, '2 of 4', 'Choose your audience'),
          const SizedBox(height: 24),
          RadioGroup<AnnouncementAudience>(
            groupValue: audience,
            onChanged: (v) => onAudienceChanged(v!),
            child: Column(
              children: [
                RadioListTile<AnnouncementAudience>(
                  title: const Text('All members'),
                  subtitle: const Text('Send to everyone'),
                  value: AnnouncementAudience.all,
                ),
                RadioListTile<AnnouncementAudience>(
                  title: const Text('Specific discipline'),
                  subtitle: const Text('Send to members of one discipline'),
                  value: AnnouncementAudience.discipline,
                ),
              ],
            ),
          ),
          if (audience == AnnouncementAudience.discipline) ...[
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Select discipline'),
              child: DropdownButton<String>(
                value: selectedDisciplineId,
                hint: const Text('Choose a discipline'),
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: disciplines
                    .map(
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                    )
                    .toList(),
                onChanged: onDisciplineChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step 2 — Channel ───────────────────────────────────────────────────────

class _StepChannel extends StatelessWidget {
  const _StepChannel({required this.channel, required this.onChanged});

  final AnnouncementChannel channel;
  final ValueChanged<AnnouncementChannel> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(context, '3 of 4', 'Choose delivery channel'),
          const SizedBox(height: 24),
          RadioGroup<AnnouncementChannel>(
            groupValue: channel,
            onChanged: (v) => onChanged(v!),
            child: Column(
              children: [
                RadioListTile<AnnouncementChannel>(
                  title: const Text('Push notification only'),
                  subtitle: const Text('In-app notification'),
                  value: AnnouncementChannel.push,
                ),
                RadioListTile<AnnouncementChannel>(
                  title: const Text('Email only'),
                  subtitle: const Text('Requires Blaze plan'),
                  value: AnnouncementChannel.email,
                ),
                RadioListTile<AnnouncementChannel>(
                  title: const Text('Push + Email'),
                  subtitle: const Text(
                    'Push for all; email requires Blaze plan',
                  ),
                  value: AnnouncementChannel.both,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3 — Confirm ───────────────────────────────────────────────────────

class _StepConfirm extends StatelessWidget {
  const _StepConfirm({
    required this.title,
    required this.body,
    required this.audience,
    required this.disciplineId,
    required this.channel,
    required this.sending,
    required this.error,
  });

  final String title;
  final String body;
  final AnnouncementAudience audience;
  final String? disciplineId;
  final AnnouncementChannel channel;
  final bool sending;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(context, '4 of 4', 'Review and send'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ConfirmRow('Title', title),
                  const SizedBox(height: 8),
                  _ConfirmRow('Message', body),
                  const Divider(height: 24),
                  _ConfirmRow(
                    'Audience',
                    audience == AnnouncementAudience.all
                        ? 'All members'
                        : 'Discipline: ${disciplineId ?? '—'}',
                  ),
                  _ConfirmRow('Channel', channel.name),
                ],
              ),
            ),
          ),
          if (sending) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withAlpha(77)),
              ),
              child: Text(
                error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

// ── Step header ────────────────────────────────────────────────────────────

Widget _stepHeader(BuildContext context, String step, String heading) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'STEP $step',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 4),
      Text(heading, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

// ── Bottom nav bar ─────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.step,
    required this.canAdvance,
    required this.sending,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool canAdvance;
  final bool sending;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            if (step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: sending ? null : onBack,
                  child: const Text('Back'),
                ),
              ),
            if (step > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (canAdvance && !sending) ? onNext : null,
                child: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnAccent,
                        ),
                      )
                    : Text(step < 3 ? 'Next' : 'Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
