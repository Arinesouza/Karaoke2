import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeService {
  YoutubePlayerController loadVideo(String url) {
    final id = YoutubePlayer.convertUrlToId(url)!;

    return YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }
}
