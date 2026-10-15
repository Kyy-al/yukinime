import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/anime_models.dart';
import '../../providers/anime_providers.dart';
import '../../widgets/error_view.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> arguments;

  const VideoPlayerScreen({super.key, required this.arguments});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  Timer? _hideControlsTimer;
  Timer? _progressSaveTimer;
  Timer? _autoplayTimer;

  bool _isInitializing = false;
  String? _errorMessage;
  bool _showControls = true;
  bool _isLocked = false;
  bool _isFullscreen = false;
  bool _hasTriggeredAutoplay = false;
  int _autoplayCountdown = AppConstants.autoplayCountdown;

  String? _selectedReso;
  String? _currentStreamUrl;

  late String _chapterUrlId;
  late String _animeUrl;
  late String _animeTitle;
  late String _cover;
  late String _chapterTitle;
  late int _episodeNumber;
  late int _startPositionSeconds;
  List<Map<String, dynamic>> _allChapters = [];

  @override
  void initState() {
    super.initState();
    _extractArgs();
    WakelockPlus.enable();
  }

  void _extractArgs() {
    _chapterUrlId = widget.arguments['chapterUrlId'] ?? '';
    _animeUrl = widget.arguments['animeUrl'] ?? '';
    _animeTitle = widget.arguments['animeTitle'] ?? '';
    _cover = widget.arguments['cover'] ?? '';
    _chapterTitle = widget.arguments['chapterTitle'] ?? '';
    _episodeNumber = widget.arguments['episodeNumber'] ?? 1;
    _startPositionSeconds = widget.arguments['startPositionSeconds'] ?? 0;
    _allChapters = List<Map<String, dynamic>>.from(
      widget.arguments['allChapters'] ?? [],
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    _autoplayTimer?.cancel();
    _videoController?.removeListener(_onPlayerUpdate);
    _videoController?.dispose();
    WakelockPlus.disable();
    _restoreSystemUI();
    super.dispose();
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  Future<void> _initPlayer(String videoUrl) async {
    if (_currentStreamUrl == videoUrl && _videoController != null) return;

    _currentStreamUrl = videoUrl;

    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    final oldController = _videoController;
    _videoController = null;
    if (oldController != null) {
      oldController.removeListener(_onPlayerUpdate);
      await oldController.dispose();
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _videoController = controller;
      _isInitializing = false;
      controller.addListener(_onPlayerUpdate);

      if (_startPositionSeconds > 0) {
        await controller.seekTo(Duration(seconds: _startPositionSeconds));
      }

      await controller.play();
      _startControlsTimer();
      _startProgressTimer();

      if (mounted) {
        setState(() {});
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Gagal memutar video ($err). Silakan pilih resolusi lain.';
      });
    }
  }

  void _onPlayerUpdate() {
    if (!mounted || _videoController == null) return;

    final val = _videoController!.value;
    if (val.isInitialized && val.duration.inSeconds > 0) {
      final pos = val.position.inSeconds;
      final dur = val.duration.inSeconds;

      // Completion check (> 92%)
      if (pos / dur >= AppConstants.completionThreshold &&
          !_hasTriggeredAutoplay) {
        _hasTriggeredAutoplay = true;
        _startAutoplayNextCountdown();
      }
    }
    if (mounted && _showControls) {
      setState(() {});
    }
  }

  void _startControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(
      const Duration(seconds: AppConstants.controlsHideDelay),
      () {
        if (mounted && (_videoController != null && _videoController!.value.isPlaying)) {
          setState(() {
            _showControls = false;
          });
        }
      },
    );
  }

  void _startProgressTimer() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(
      const Duration(seconds: AppConstants.progressSaveInterval),
      (_) {
        if (mounted) _saveProgress();
      },
    );
  }

  void _saveProgress() {
    if (!mounted || _videoController == null) return;
    final val = _videoController!.value;
    if (!val.isInitialized) return;

    final pos = val.position.inSeconds;
    final dur = val.duration.inSeconds;

    if (pos > 0) {
      ref.read(watchHistoryProvider.notifier).saveProgress(
            animeUrl: _animeUrl,
            animeTitle: _animeTitle,
            cover: _cover,
            chapterUrl: _chapterUrlId,
            chapterTitle: _chapterTitle,
            episodeNumber: _episodeNumber,
            positionSeconds: pos,
            totalSeconds: dur,
          );
    }
  }

  void _startAutoplayNextCountdown() {
    final settings = ref.read(settingsProvider);
    if (!settings.autoplayNext) return;

    final nextCh = _getNextChapter();
    if (nextCh == null) return;

    setState(() {
      _autoplayCountdown = AppConstants.autoplayCountdown;
    });

    _autoplayTimer?.cancel();
    _autoplayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_autoplayCountdown <= 1) {
        timer.cancel();
        _playNextEpisode();
      } else {
        setState(() {
          _autoplayCountdown--;
        });
      }
    });
  }

  Map<String, dynamic>? _getNextChapter() {
    if (_allChapters.isEmpty) return null;
    final currentIndex = _allChapters.indexWhere((c) => c['url'] == _chapterUrlId);
    if (currentIndex != -1 && currentIndex + 1 < _allChapters.length) {
      return _allChapters[currentIndex + 1];
    }
    return null;
  }

  void _playNextEpisode() {
    final nextCh = _getNextChapter();
    if (nextCh == null) return;

    _autoplayTimer?.cancel();
    _hasTriggeredAutoplay = false;

    setState(() {
      _chapterUrlId = nextCh['url'];
      _chapterTitle = nextCh['title'];
      _episodeNumber = nextCh['episodeNumber'];
      _startPositionSeconds = 0;
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;
      _currentStreamUrl = null;
      _errorMessage = null;
      _isInitializing = false;
    });
  }

  void _seekRelative(int seconds) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final current = _videoController!.value.position;
      final target = current + Duration(seconds: seconds);
      _videoController!.seekTo(target);
      _startControlsTimer();
    }
  }

  String _formatDuration(Duration duration) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = duration.inHours;
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final streamAsync = ref.watch(
      videoStreamProvider(
        StreamRequest(chapterUrlId: _chapterUrlId, reso: _selectedReso),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: streamAsync.when(
        data: (videoStream) {
          final defaultQuality = ref.watch(settingsProvider).defaultQuality;
          final source = videoStream.getByResolution(_selectedReso ?? '') ??
              videoStream.getByResolution(defaultQuality) ??
              videoStream.bestQuality ??
              (videoStream.sources.isNotEmpty ? videoStream.sources.first : null);

          if (source == null || source.link.isEmpty) {
            return ErrorView(
              message: 'Tidak ada link video yang dapat diputar.',
              onRetry: () => ref.refresh(
                videoStreamProvider(
                  StreamRequest(chapterUrlId: _chapterUrlId, reso: _selectedReso),
                ),
              ),
            );
          }

          // Trigger video initialization safely after frame
          if (_currentStreamUrl != source.link && !_isInitializing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _initPlayer(source.link);
              }
            });
          }

          return GestureDetector(
            onTap: () {
              if (_isLocked) {
                setState(() {
                  _showControls = !_showControls;
                });
                return;
              }
              setState(() {
                _showControls = !_showControls;
              });
              if (_showControls) {
                _startControlsTimer();
              }
            },
            onDoubleTapDown: (details) {
              if (_isLocked || _videoController == null) return;
              final screenWidth = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < screenWidth / 2) {
                _seekRelative(-AppConstants.seekDuration);
              } else {
                _seekRelative(AppConstants.seekDuration);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video Player Area
                Center(
                  child: _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _initPlayer(source.link);
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : (_videoController != null && _videoController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            )
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppColors.primary),
                                SizedBox(height: 16),
                                Text(
                                  'Memuat pemutar video...',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            )),
                ),

                // Lock Button (always visible when locked)
                if (_isLocked && _showControls)
                  Positioned(
                    left: 20,
                    top: 40,
                    child: IconButton(
                      icon: const Icon(
                        Icons.lock_rounded,
                        color: AppColors.accent,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isLocked = false;
                        });
                      },
                    ),
                  ),

                // Controls Overlay
                if (_showControls && !_isLocked)
                  _buildControlsOverlay(videoStream, source),

                // Next Episode Autoplay Countdown Overlay
                if (_hasTriggeredAutoplay && _getNextChapter() != null)
                  _buildAutoplayOverlay(),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Memuat stream anime...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(
            videoStreamProvider(
              StreamRequest(chapterUrlId: _chapterUrlId, reso: _selectedReso),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(
      VideoStream videoStream, StreamSource currentSource) {
    final isInitialized =
        _videoController != null && _videoController!.value.isInitialized;
    final isPlaying = isInitialized && _videoController!.value.isPlaying;
    final isBuffering = isInitialized && _videoController!.value.isBuffering;

    final position = isInitialized
        ? _videoController!.value.position
        : Duration.zero;
    final duration = isInitialized
        ? _videoController!.value.duration
        : Duration.zero;

    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () {
                      _saveProgress();
                      context.pop();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _animeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _chapterTitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.accent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lock Controls Button
                  IconButton(
                    icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
                    tooltip: 'Kunci Layar',
                    onPressed: () {
                      setState(() {
                        _isLocked = true;
                      });
                    },
                  ),

                  // Resolution selector badge
                  GestureDetector(
                    onTap: () => _showResolutionDialog(videoStream),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedReso ??
                                (currentSource.reso.isNotEmpty
                                    ? currentSource.reso
                                    : 'Auto'),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Center Actions: Seek -5s, Play/Pause, Seek +5s
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 42,
                  icon: const Icon(Icons.replay_5_rounded, color: Colors.white),
                  onPressed: () => _seekRelative(-AppConstants.seekDuration),
                ),
                const SizedBox(width: 32),
                if (isBuffering || _isInitializing)
                  const SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 36,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          _videoController?.pause();
                        } else {
                          _videoController?.play();
                          _startControlsTimer();
                        }
                        setState(() {});
                      },
                    ),
                  ),
                const SizedBox(width: 32),
                IconButton(
                  iconSize: 42,
                  icon: const Icon(Icons.forward_5_rounded, color: Colors.white),
                  onPressed: () => _seekRelative(AppConstants.seekDuration),
                ),
              ],
            ),

            const Spacer(),

            // Bottom Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      trackHeight: 3,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppColors.primary,
                    ),
                    child: Slider(
                      value: position.inMilliseconds
                          .toDouble()
                          .clamp(0.0, duration.inMilliseconds.toDouble()),
                      max: duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0,
                      onChanged: (val) {
                        _videoController?.seekTo(
                          Duration(milliseconds: val.toInt()),
                        );
                        _startControlsTimer();
                      },
                    ),
                  ),

                  Row(
                    children: [
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (_getNextChapter() != null)
                        TextButton.icon(
                          onPressed: _playNextEpisode,
                          icon: const Icon(Icons.skip_next_rounded, size: 20),
                          label: const Text('Episode Berikutnya'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          _isFullscreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _toggleFullscreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoplayOverlay() {
    final nextCh = _getNextChapter();
    if (nextCh == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Episode Berikutnya: ${nextCh['title']}',
              style: AppTypography.titleSmall.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Memutar otomatis dalam $_autoplayCountdown detik...',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _autoplayTimer?.cancel();
                      _hasTriggeredAutoplay = false;
                    });
                  },
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _playNextEpisode,
                  child: const Text('Putar Sekarang'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResolutionDialog(VideoStream videoStream) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Resolusi Video',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...videoStream.availableResolutions.map((reso) {
                final isSelected = (_selectedReso ?? '720p') == reso;
                return ListTile(
                  title: Text(reso, style: AppTypography.bodyMedium),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.surfaceElevated,
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedReso == reso) return;
                    setState(() {
                      _selectedReso = reso;
                      _videoController?.pause();
                      _videoController?.dispose();
                      _videoController = null;
                      _currentStreamUrl = null;
                      _isInitializing = false;
                      _errorMessage = null;
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
