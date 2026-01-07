import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoService {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;

  // Initialize Video Player for local or network MP4 videos
  Future<VideoPlayerController?> initializeVideoPlayer(String videoUrl) async {
    try {
      if (videoUrl.startsWith('http')) {
        _videoController = VideoPlayerController.network(videoUrl);
      } else {
        _videoController = VideoPlayerController.asset(videoUrl);
      }

      await _videoController!.initialize();
      return _videoController;
    } catch (e) {
      print('Error initializing video player: $e');
      return null;
    }
  }

  // Initialize YouTube Player
  YoutubePlayerController? initializeYoutubePlayer(String youtubeUrl) {
    try {
      final videoId = YoutubePlayer.convertUrlToId(youtubeUrl);
      
      if (videoId == null) {
        print('Invalid YouTube URL');
        return null;
      }

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          loop: false,
          isLive: false,
          forceHD: false,
          showLiveFullscreenButton: true,
        ),
      );

      return _youtubeController;
    } catch (e) {
      print('Error initializing YouTube player: $e');
      return null;
    }
  }

  // Check if URL is YouTube
  bool isYoutubeUrl(String url) {
    return url.contains('youtube.com') || 
           url.contains('youtu.be') ||
           url.contains('youtube');
  }

  // Check if URL is video file
  bool isVideoFile(String url) {
    return url.endsWith('.mp4') ||
           url.endsWith('.mkv') ||
           url.endsWith('.avi') ||
           url.endsWith('.mov');
  }

  // Get video type
  VideoType getVideoType(String url) {
    if (isYoutubeUrl(url)) {
      return VideoType.youtube;
    } else if (isVideoFile(url)) {
      return VideoType.file;
    } else {
      return VideoType.unknown;
    }
  }

  // Play video
  void play() {
    _videoController?.play();
  }

  // Pause video
  void pause() {
    _videoController?.pause();
  }

  // Seek to position
  void seekTo(Duration position) {
    _videoController?.seekTo(position);
  }

  // Get current position
  Duration? getCurrentPosition() {
    return _videoController?.value.position;
  }

  // Get video duration
  Duration? getDuration() {
    return _videoController?.value.duration;
  }

  // Check if playing
  bool isPlaying() {
    return _videoController?.value.isPlaying ?? false;
  }

  // Set volume
  void setVolume(double volume) {
    _videoController?.setVolume(volume);
  }

  // Set playback speed
  void setPlaybackSpeed(double speed) {
    _videoController?.setPlaybackSpeed(speed);
  }

  // Dispose controllers
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.dispose();
  }

  // Get video info
  Map<String, dynamic> getVideoInfo() {
    if (_videoController != null) {
      final value = _videoController!.value;
      return {
        'duration': value.duration.inSeconds,
        'position': value.position.inSeconds,
        'isPlaying': value.isPlaying,
        'volume': value.volume,
        'aspectRatio': value.aspectRatio,
        'size': {
          'width': value.size.width,
          'height': value.size.height,
        },
      };
    }
    return {};
  }
}

enum VideoType {
  youtube,
  file,
  unknown,
}