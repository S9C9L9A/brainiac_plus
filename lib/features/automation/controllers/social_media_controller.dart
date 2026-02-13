import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/social_media_task.dart';
import '../../../core/services/higgsfield_service.dart';
import '../../../core/services/instagram_service.dart';

/// Provider for Higgsfield service
final higgsfieldServiceProvider = Provider<HiggsfieldService?>((ref) {
  // TODO: Get API key from settings/config
  // For now, return null - user needs to configure
  return null;
});

/// Provider for Instagram service
final instagramServiceProvider = Provider<InstagramService?>((ref) {
  // TODO: Get access token and user ID from auth flow
  // For now, return null - user needs to authenticate
  return null;
});

/// Provider for social media automation controller
final socialMediaControllerProvider =
    StateNotifierProvider<SocialMediaController, SocialMediaState>((ref) {
  return SocialMediaController(
    ref.watch(higgsfieldServiceProvider),
    ref.watch(instagramServiceProvider),
  );
});

/// Social Media State
class SocialMediaState {
  final List<SocialMediaTask> tasks;
  final bool isLoading;
  final String? error;
  final SocialMediaTask? currentTask;

  SocialMediaState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.currentTask,
  });

  SocialMediaState copyWith({
    List<SocialMediaTask>? tasks,
    bool? isLoading,
    String? error,
    SocialMediaTask? currentTask,
  }) {
    return SocialMediaState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentTask: currentTask,
    );
  }
}

/// Social Media Automation Controller
class SocialMediaController extends StateNotifier<SocialMediaState> {
  final HiggsfieldService? _higgsfieldService;
  final InstagramService? _instagramService;

  SocialMediaController(
    this._higgsfieldService,
    this._instagramService,
  ) : super(SocialMediaState());

  /// Execute a social media task
  Future<void> executeTask(SocialMediaTask task) async {
    if (_higgsfieldService == null) {
      state = state.copyWith(
        error: 'Higgsfield API not configured. Please add your API key in settings.',
      );
      return;
    }

    if (_instagramService == null) {
      state = state.copyWith(
        error: 'Instagram not connected. Please authenticate first.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentTask: task.copyWith(status: TaskStatus.generating),
    );

    try {
      // Step 1: Generate content with Higgsfield
      final generatedContent = await _generateContent(task);

      // Step 2: Generate caption if needed
      String finalCaption = task.caption;
      if (task.autoGenerateCaption) {
        finalCaption = await _generateCaption(task);
      }
      if (task.hashtags.isNotEmpty) {
        finalCaption += '\n\n${task.hashtags.map((h) => '#$h').join(' ')}';
      }

      // Step 3: Download generated content
      state = state.copyWith(
        currentTask: task.copyWith(status: TaskStatus.uploading),
      );

      final contentFile = await _downloadContent(generatedContent);

      // Step 4: Upload to Instagram
      final mediaId = await _uploadToInstagram(
        task: task,
        file: contentFile,
        caption: finalCaption,
      );

      // Success!
      final completedTask = task.copyWith(
        status: TaskStatus.completed,
        lastRun: DateTime.now(),
      );

      state = state.copyWith(
        isLoading: false,
        currentTask: completedTask,
      );
    } catch (e) {
      final failedTask = task.copyWith(
        status: TaskStatus.failed,
        lastError: e.toString(),
      );

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        currentTask: failedTask,
      );
    }
  }

  /// Generate content with Higgsfield
  Future<GeneratedContent> _generateContent(SocialMediaTask task) async {
    switch (task.contentType) {
      case ContentType.photo:
        return await _higgsfieldService!.generateImage(
          prompt: task.contentPrompt,
          style: task.contentStyle,
          aspectRatio: '1:1', // Instagram square
        );

      case ContentType.video:
        return await _higgsfieldService!.generateVideo(
          prompt: task.contentPrompt,
          duration: task.videoDuration ?? 15,
          style: task.contentStyle,
          aspectRatio: '9:16', // Reels vertical
        );

      case ContentType.carousel:
        // For carousel, generate single image
        // TODO: Generate multiple images
        return await _higgsfieldService!.generateImage(
          prompt: task.contentPrompt,
          style: task.contentStyle,
          aspectRatio: '1:1',
        );
    }
  }

  /// Generate caption with AI
  Future<String> _generateCaption(SocialMediaTask task) async {
    return await _higgsfieldService!.generateCaption(
      contentDescription: task.contentPrompt,
      tone: 'engaging',
      hashtags: task.hashtags,
    );
  }

  /// Download generated content to local file
  Future<File> _downloadContent(GeneratedContent content) async {
    if (content.url == null) {
      throw Exception('Content URL is null');
    }

    final bytes = await _higgsfieldService!.downloadContent(content.url!);
    final tempDir = await getTemporaryDirectory();
    final extension = content.type == 'video' ? 'mp4' : 'jpg';
    final file = File('${tempDir.path}/content_${content.id}.$extension');
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Upload content to Instagram
  Future<String> _uploadToInstagram({
    required SocialMediaTask task,
    required File file,
    required String caption,
  }) async {
    switch (task.contentType) {
      case ContentType.photo:
        return await _instagramService!.uploadPhoto(
          imageFile: file,
          caption: caption,
          location: task.locationId,
        );

      case ContentType.video:
        return await _instagramService!.uploadVideo(
          videoFile: file,
          caption: caption,
          isReel: true,
        );

      case ContentType.carousel:
        // TODO: Handle multiple images
        return await _instagramService!.uploadPhoto(
          imageFile: file,
          caption: caption,
          location: task.locationId,
        );
    }
  }

  /// Add a new task
  void addTask(SocialMediaTask task) {
    state = state.copyWith(
      tasks: [...state.tasks, task],
    );
  }

  /// Update a task
  void updateTask(SocialMediaTask task) {
    final updatedTasks = state.tasks.map((t) {
      return t.id == task.id ? task : t;
    }).toList();

    state = state.copyWith(tasks: updatedTasks);
  }

  /// Delete a task
  void deleteTask(int taskId) {
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != taskId).toList(),
    );
  }

  /// Toggle task enabled status
  void toggleTask(int taskId) {
    final updatedTasks = state.tasks.map((t) {
      return t.id == taskId ? t.copyWith(enabled: !t.enabled) : t;
    }).toList();

    state = state.copyWith(tasks: updatedTasks);
  }
}
