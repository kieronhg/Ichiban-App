import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/discipline_seed_data.dart';
import '../../../domain/entities/admin_user.dart';
import '../../../domain/entities/enums.dart';

// ── Wizard state ───────────────────────────────────────────────────────────

class _WizardState {
  const _WizardState({
    this.page = 0,
    this.isBusy = false,
    this.errorMessage,
    // Step 1 — Owner Account
    this.ownerFirstName = '',
    this.ownerLastName = '',
    this.ownerEmail = '',
    this.ownerPassword = '',
    // Step 2 — Dojo Details
    this.dojoName = '',
    // Step 3 — Disciplines
    this.selectedDisciplineKeys = const {},
  });

  final int page;
  final bool isBusy;
  final String? errorMessage;

  final String ownerFirstName;
  final String ownerLastName;
  final String ownerEmail;
  final String ownerPassword;

  final String dojoName;

  final Set<String> selectedDisciplineKeys;

  _WizardState copyWith({
    int? page,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    String? ownerFirstName,
    String? ownerLastName,
    String? ownerEmail,
    String? ownerPassword,
    String? dojoName,
    Set<String>? selectedDisciplineKeys,
  }) {
    return _WizardState(
      page: page ?? this.page,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      ownerFirstName: ownerFirstName ?? this.ownerFirstName,
      ownerLastName: ownerLastName ?? this.ownerLastName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPassword: ownerPassword ?? this.ownerPassword,
      dojoName: dojoName ?? this.dojoName,
      selectedDisciplineKeys:
          selectedDisciplineKeys ?? this.selectedDisciplineKeys,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class _WizardNotifier extends Notifier<_WizardState> {
  @override
  _WizardState build() => const _WizardState();

  void goTo(int page) => state = state.copyWith(page: page, clearError: true);

  void setOwnerFirstName(String v) =>
      state = state.copyWith(ownerFirstName: v, clearError: true);
  void setOwnerLastName(String v) =>
      state = state.copyWith(ownerLastName: v, clearError: true);
  void setOwnerEmail(String v) =>
      state = state.copyWith(ownerEmail: v, clearError: true);
  void setOwnerPassword(String v) =>
      state = state.copyWith(ownerPassword: v, clearError: true);
  void setDojoName(String v) =>
      state = state.copyWith(dojoName: v, clearError: true);

  void toggleDiscipline(String key) {
    final current = Set<String>.from(state.selectedDisciplineKeys);
    if (current.contains(key)) {
      current.remove(key);
    } else {
      current.add(key);
    }
    state = state.copyWith(selectedDisciplineKeys: current, clearError: true);
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  String? validateStep(int step) {
    if (step == 1) {
      if (state.ownerFirstName.trim().isEmpty) {
        return 'Please enter your first name.';
      }
      if (state.ownerLastName.trim().isEmpty) {
        return 'Please enter your last name.';
      }
      if (state.ownerEmail.trim().isEmpty) {
        return 'Please enter your email address.';
      }
      if (state.ownerPassword.length < 8) {
        return 'Password must be at least 8 characters.';
      }
    }
    if (step == 2) {
      if (state.dojoName.trim().isEmpty) {
        return 'Please enter your dojo name.';
      }
    }
    if (step == 3) {
      if (state.selectedDisciplineKeys.isEmpty) {
        return 'Please select at least one discipline.';
      }
    }
    return null;
  }

  /// Seeds Firestore and marks setup complete. Returns null on success or an
  /// error message on failure.
  Future<String?> completeSetup(WidgetRef ref) async {
    state = state.copyWith(isBusy: true, clearError: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final adminRepo = ref.read(adminUserRepositoryProvider);
      final disciplineRepo = ref.read(disciplineRepositoryProvider);
      final rankRepo = ref.read(rankRepositoryProvider);
      final settingsRepo = ref.read(appSettingsRepositoryProvider);
      final appSetupRepo = ref.read(appSetupRepositoryProvider);

      // 1. Create Firebase Auth account for the owner.
      final uid = await authRepo.createUser(
        email: state.ownerEmail.trim(),
        password: state.ownerPassword,
      );

      // 2. Write adminUsers document.
      final adminUser = AdminUser(
        firebaseUid: uid,
        email: state.ownerEmail.trim(),
        firstName: state.ownerFirstName.trim(),
        lastName: state.ownerLastName.trim(),
        role: AdminRole.owner,
        assignedDisciplineIds: const [],
        isActive: true,
        createdByAdminId: uid, // self-created during setup
        createdAt: DateTime.now(),
      );
      await adminRepo.create(adminUser);

      // 3. Save dojo name to app settings.
      await settingsRepo.set('dojoName', state.dojoName.trim());

      // 4. Seed selected disciplines + their rank ladders.
      final templates = DisciplineSeedData.templates
          .where((t) => state.selectedDisciplineKeys.contains(t.key))
          .toList();

      for (final template in templates) {
        final disciplineId = await disciplineRepo.create(
          template.toDiscipline(id: '', createdByAdminId: uid),
        );
        for (final rankTemplate in template.ranks) {
          await rankRepo.create(
            rankTemplate.toRank(id: '', disciplineId: disciplineId),
          );
        }
      }

      // 5. Mark setup complete in Firestore.
      await appSetupRepo.markComplete(setupCompletedByAdminId: uid);

      state = state.copyWith(isBusy: false);
      return null;
    } catch (e) {
      state = state.copyWith(isBusy: false);
      return e.toString().contains('email-already-in-use')
          ? 'That email address is already registered. '
                'Please use a different email.'
          : 'Setup failed: ${e.toString()}';
    }
  }
}

final _wizardProvider = NotifierProvider<_WizardNotifier, _WizardState>(
  _WizardNotifier.new,
);

// ── Screen ─────────────────────────────────────────────────────────────────

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    ref.read(_wizardProvider.notifier).goTo(page);
  }

  void _next() {
    final notifier = ref.read(_wizardProvider.notifier);
    final page = ref.read(_wizardProvider).page;
    final error = notifier.validateStep(page);
    if (error != null) {
      notifier.setError(error);
      return;
    }
    _animateTo(page + 1);
  }

  Future<void> _finish() async {
    final notifier = ref.read(_wizardProvider.notifier);
    final error = notifier.validateStep(3);
    if (error != null) {
      notifier.setError(error);
      return;
    }
    final result = await notifier.completeSetup(ref);
    if (result != null) {
      notifier.setError(result);
    } else {
      // Router will redirect to login once appSetupStatusProvider emits true.
      if (mounted) context.go(RouteNames.adminLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(_wizardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(currentPage: wizardState.page),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _WelcomePage(),
                  _OwnerAccountPage(),
                  _DojoDetailsPage(),
                  _DisciplineSelectionPage(),
                ],
              ),
            ),
            if (wizardState.errorMessage != null)
              _ErrorBanner(message: wizardState.errorMessage!),
            _WizardNavBar(
              page: wizardState.page,
              isBusy: wizardState.isBusy,
              onBack: wizardState.page > 0
                  ? () => _animateTo(wizardState.page - 1)
                  : null,
              onNext: wizardState.page < 3 ? _next : null,
              onFinish: wizardState.page == 3 ? _finish : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.currentPage});

  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sports_martial_arts,
                color: AppColors.accent,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Ichiban Setup',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StepIndicator(currentPage: currentPage),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentPage});

  final int currentPage;

  static const _labels = ['Welcome', 'Account', 'Dojo', 'Disciplines'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          final isComplete = stepIndex < currentPage;
          return Expanded(
            child: Container(
              height: 2,
              color: isComplete ? AppColors.accent : AppColors.primaryVariant,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isActive = stepIndex == currentPage;
        final isComplete = stepIndex < currentPage;
        return _StepDot(
          index: stepIndex,
          label: _labels[stepIndex],
          isActive: isActive,
          isComplete: isComplete,
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final bg = isComplete
        ? AppColors.accent
        : isActive
        ? AppColors.textOnPrimary
        : AppColors.primaryVariant;
    final fg = isComplete || isActive
        ? AppColors.primary
        : AppColors.textOnPrimary;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: isComplete
              ? const Icon(Icons.check, size: 16, color: AppColors.textOnAccent)
              : Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? AppColors.textOnPrimary
                : AppColors.textOnPrimary.withAlpha(153),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ── Pages ──────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.sports_martial_arts,
              size: 56,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Ichiban',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s get your dojo set up. This wizard will walk you through '
            'creating your owner account, naming your dojo, and choosing '
            'the martial arts disciplines you teach.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _InfoTile(
            icon: Icons.person_outline,
            text: 'Create your owner account',
          ),
          _InfoTile(icon: Icons.home_work_outlined, text: 'Name your dojo'),
          _InfoTile(
            icon: Icons.sports_outlined,
            text: 'Choose your disciplines',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 16),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

// ── Step 1: Owner Account ──────────────────────────────────────────────────

class _OwnerAccountPage extends ConsumerStatefulWidget {
  const _OwnerAccountPage();

  @override
  ConsumerState<_OwnerAccountPage> createState() => _OwnerAccountPageState();
}

class _OwnerAccountPageState extends ConsumerState<_OwnerAccountPage> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(_wizardProvider.notifier);
    final ws = ref.watch(_wizardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Owner Account',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This is the primary account for your dojo. '
            'You\'ll use this to sign in on the admin tablet.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _LabelledField(
                  label: 'First Name',
                  initialValue: ws.ownerFirstName,
                  onChanged: notifier.setOwnerFirstName,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabelledField(
                  label: 'Last Name',
                  initialValue: ws.ownerLastName,
                  onChanged: notifier.setOwnerLastName,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LabelledField(
            label: 'Email Address',
            initialValue: ws.ownerEmail,
            onChanged: notifier.setOwnerEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _LabelledField(
            label: 'Password',
            initialValue: ws.ownerPassword,
            onChanged: notifier.setOwnerPassword,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            helperText: 'Minimum 8 characters',
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Dojo Details ───────────────────────────────────────────────────

class _DojoDetailsPage extends ConsumerWidget {
  const _DojoDetailsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(_wizardProvider.notifier);
    final ws = ref.watch(_wizardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Dojo',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Give your dojo a name. This will appear throughout the app.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          _LabelledField(
            label: 'Dojo Name',
            initialValue: ws.dojoName,
            onChanged: notifier.setDojoName,
            textCapitalization: TextCapitalization.words,
            hintText: 'e.g. Sakura Martial Arts',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withAlpha(77)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can change your dojo name at any time in Settings.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Discipline Selection ───────────────────────────────────────────

class _DisciplineSelectionPage extends ConsumerWidget {
  const _DisciplineSelectionPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(_wizardProvider.notifier);
    final ws = ref.watch(_wizardProvider);
    final templates = DisciplineSeedData.templates;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disciplines',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the martial arts you teach. Each discipline gets a '
            'pre-built rank ladder — you can customise ranks after setup.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ...templates.map(
            (template) => _DisciplineTile(
              template: template,
              isSelected: ws.selectedDisciplineKeys.contains(template.key),
              onTap: () => notifier.toggleDiscipline(template.key),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisciplineTile extends StatelessWidget {
  const _DisciplineTile({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final DisciplineTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  static const _icons = {
    'karate': Icons.sports_martial_arts,
    'judo': Icons.sports_kabaddi,
    'jujitsu': Icons.fitness_center,
    'kickboxing': Icons.sports_mma,
    'mma': Icons.shield_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withAlpha(26)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.surfaceVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _icons[template.key] ?? Icons.sports_outlined,
                  color: isSelected
                      ? AppColors.textOnAccent
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (template.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        template.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${template.ranks.length} ranks pre-loaded',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.accent)
              else
                const Icon(
                  Icons.radio_button_unchecked,
                  color: AppColors.surfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Navigation bar ─────────────────────────────────────────────────────────

class _WizardNavBar extends StatelessWidget {
  const _WizardNavBar({
    required this.page,
    required this.isBusy,
    required this.onBack,
    required this.onNext,
    required this.onFinish,
  });

  final int page;
  final bool isBusy;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final Future<void> Function()? onFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      color: AppColors.surface,
      child: Row(
        children: [
          if (onBack != null)
            OutlinedButton(
              onPressed: isBusy ? null : onBack,
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          if (onNext != null)
            ElevatedButton(
              onPressed: isBusy ? null : onNext,
              child: const Text('Continue'),
            ),
          if (onFinish != null)
            ElevatedButton(
              onPressed: isBusy ? null : onFinish,
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnAccent,
                      ),
                    )
                  : const Text('Finish Setup'),
            ),
        ],
      ),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: AppColors.error.withAlpha(26),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared field widget ────────────────────────────────────────────────────

class _LabelledField extends StatelessWidget {
  const _LabelledField({
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.helperText,
    this.hintText,
  });

  final String label;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? helperText;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            helperText: helperText,
          ),
        ),
      ],
    );
  }
}
