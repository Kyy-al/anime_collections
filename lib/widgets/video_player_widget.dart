import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/video_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = false,
    this.showControls = true,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  final VideoService _videoService = VideoService();
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  VideoType? _videoType;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoType = _videoService.getVideoType(widget.videoUrl);

    if (_videoType == VideoType.youtube) {
      _youtubeController = _videoService.initializeYoutubePlayer(widget.videoUrl);
      if (_youtubeController != null) {
        setState(() => _isInitialized = true);
      }
    } else if (_videoType == VideoType.file) {
      _videoController = await _videoService.initializeVideoPlayer(widget.videoUrl);
      if (_videoController != null) {
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = _videoController!.value.isPlaying;
            });
          }
        });
        
        if (widget.autoPlay) {
          _videoController!.play();
        }
        
        setState(() => _isInitialized = true);
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_videoType == VideoType.youtube && _youtubeController != null) {
      return _buildYoutubePlayer();
    } else if (_videoType == VideoType.file && _videoController != null) {
      return _buildVideoPlayer();
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildYoutubePlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.deepPurpleAccent,
        progressColors: const ProgressBarColors(
          playedColor: Colors.deepPurpleAccent,
          handleColor: Colors.deepPurpleAccent,
        ),
        bottomActions: widget.showControls
            ? [
                const SizedBox(width: 14),
                CurrentPosition(),
                const SizedBox(width: 8),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
                const PlaybackSpeedButton(),
                FullScreenButton(),
              ]
            : [],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            
            if (widget.showControls) _buildControls(),
            
            // Play/Pause overlay
            if (!_isPlaying)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            // Progress bar
            VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.deepPurpleAccent,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(height: 8),
            
            // Controls
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlayPause,
                ),
                
                // Current time
                Text(
                  _formatDuration(_videoController!.value.position),
                  style: const TextStyle(color: Colors.white),
                ),
                
                const Spacer(),
                
                // Duration
                Text(
                  _formatDuration(_videoController!.value.duration),
                  style: const TextStyle(color: Colors.white),
                ),
                
                // Volume
                IconButton(
                  icon: Icon(
                    _videoController!.value.volume > 0
                        ? Icons.volume_up
                        : Icons.volume_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController!.setVolume(
                        _videoController!.value.volume > 0 ? 0 : 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Video tidak dapat dimuat',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }
}