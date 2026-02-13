import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/theme/app_icons.dart';
import '../models/social_media_task.dart';
import '../controllers/social_media_controller.dart';

class CreateSocialMediaTaskScreen extends ConsumerStatefulWidget {
  const CreateSocialMediaTaskScreen({super.key});

  @override
  ConsumerState<CreateSocialMediaTaskScreen> createState() =>
      _CreateSocialMediaTaskScreenState();
}

class _CreateSocialMediaTaskScreenState
    extends ConsumerState<CreateSocialMediaTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();
  final _captionController = TextEditingController();
  final _hashtagsController = TextEditingController();

  ContentType _contentType = ContentType.photo;
  String _contentStyle = 'realistic';
  int _videoDuration = 15;
  bool _autoGenerateCaption = true;
  PublishPlatform _platform = PublishPlatform.instagram;
  String _schedule = '0 9 * * *'; // Daily at 9 AM

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _captionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          title: 'Basic Info',
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Task Name',
                              hint: 'e.g., Daily Instagram Post',
                              validator: (v) => v?.isEmpty ?? true
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildScheduleField(),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Content Generation',
                          children: [
                            _buildContentTypeSelector(),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _promptController,
                              label: 'Content Prompt',
                              hint: 'Describe what to generate...',
                              maxLines: 3,
                              validator: (v) => v?.isEmpty ?? true
                                  ? 'Prompt is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildStyleSelector(),
                            if (_contentType == ContentType.video) ...[
                              const SizedBox(height: 16),
                              _buildDurationSlider(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Caption & Hashtags',
                          children: [
                            _buildAutoGenerateCaptionSwitch(),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _captionController,
                              label: 'Caption (optional)',
                              hint: 'Custom caption or leave empty for AI',
                              maxLines: 4,
                              enabled: !_autoGenerateCaption,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _hashtagsController,
                              label: 'Hashtags',
                              hint: 'fitness,motivation,lifestyle',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Publishing',
                          children: [
                            _buildPlatformSelector(),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildCreateButton(),
                      ],
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(AppIcons.arrowBack, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Icon(AppIcons.add, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'New Social Media Task',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.systemBlue),
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildContentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content Type',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: ContentType.values.map((type) {
            final isSelected = _contentType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: isSelected
                      ? AppColors.systemBlue.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => setState(() => _contentType = type),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            type.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStyleSelector() {
    final styles = [
      'realistic',
      'artistic',
      'cinematic',
      'cartoon',
      'anime',
      'vintage'
    ];

    return DropdownButtonFormField<String>(
      value: _contentStyle,
      dropdownColor: Colors.grey.shade900,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Style',
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.systemBlue),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: styles.map((style) {
        return DropdownMenuItem(
          value: style,
          child: Text(style.capitalize()),
        );
      }).toList(),
      onChanged: (value) => setState(() => _contentStyle = value!),
    );
  }

  Widget _buildDurationSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video Duration: $_videoDuration seconds',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Slider(
          value: _videoDuration.toDouble(),
          min: 5,
          max: 90,
          divisions: 17,
          activeColor: AppColors.systemBlue,
          inactiveColor: Colors.white30,
          onChanged: (value) => setState(() => _videoDuration = value.toInt()),
        ),
      ],
    );
  }

  Widget _buildAutoGenerateCaptionSwitch() {
    return SwitchListTile(
      value: _autoGenerateCaption,
      onChanged: (value) => setState(() => _autoGenerateCaption = value),
      title: const Text(
        'Auto-generate caption with AI',
        style: TextStyle(color: Colors.white),
      ),
      activeColor: AppColors.systemBlue,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPlatformSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platform',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: PublishPlatform.values.map((platform) {
            final isSelected = _platform == platform;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(platform.icon),
                  const SizedBox(width: 4),
                  Text(platform.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _platform = platform);
              },
              selectedColor: AppColors.systemBlue.withOpacity(0.3),
              backgroundColor: Colors.white.withOpacity(0.1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleField() {
    return _buildTextField(
      controller: TextEditingController(text: _schedule),
      label: 'Schedule (Cron)',
      hint: '0 9 * * * (Daily at 9 AM)',
      validator: (v) =>
          v?.isEmpty ?? true ? 'Schedule is required' : null,
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _createTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.systemBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Create Task',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _createTask() {
    if (!_formKey.currentState!.validate()) return;

    final hashtags = _hashtagsController.text
        .split(',')
        .map((h) => h.trim())
        .where((h) => h.isNotEmpty)
        .toList();

    final task = SocialMediaTask(
      name: _nameController.text,
      schedule: _schedule,
      contentType: _contentType,
      contentPrompt: _promptController.text,
      contentStyle: _contentStyle,
      videoDuration: _contentType == ContentType.video ? _videoDuration : null,
      caption: _captionController.text,
      hashtags: hashtags,
      autoGenerateCaption: _autoGenerateCaption,
      platform: _platform,
    );

    ref.read(socialMediaControllerProvider.notifier).addTask(task);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Social media task created!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
