import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioBookDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final String bookId;

  static const routeName = '/audioBookDetails';

  const AudioBookDetailsScreen(
      {super.key, required this.book, required this.bookId});

  @override
  _AudioBookDetailsScreenState createState() => _AudioBookDetailsScreenState();
}

class _AudioBookDetailsScreenState extends State<AudioBookDetailsScreen> {
  bool isLiked = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  double playbackSpeed = 1.0;
  bool isSeekBarBeingDragged = false;
  Duration totalDuration = const Duration();
  Duration currentPosition = const Duration();

  List<double> speedOptions = [0.25, 0.5, 1.0, 1.25, 1.5, 1.75, 2.0];
  double selectedSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
    _prepareAudio();

    _audioPlayer.positionStream.listen((position) {
      if (!isSeekBarBeingDragged) {
        setState(() {
          currentPosition = position;
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      setState(() {
        totalDuration = duration ?? const Duration();
      });
    });

    _audioPlayer.playingStream.listen((isPlayingStatus) {
      setState(() {
        isPlaying = isPlayingStatus;
      });
    });
  }

  Future<void> _loadLikeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.email);

      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        List<dynamic> booksliked = userDoc.data()!['booksliked'] ?? [];
        setState(() {
          isLiked = booksliked.contains(widget.bookId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'An error occurred while loading like status: ${e.toString()}')),
      );
    }
  }

  Future<void> _prepareAudio() async {
    final audioUrl = widget.book['audio_url'];
    String? filePath = await _getLocalAudioFilePath(audioUrl);
    if (filePath != null) {
      _audioPlayer.setFilePath(filePath);
    } else {
      _audioPlayer.setUrl(audioUrl);
    }
  }

  Future<String?> _getLocalAudioFilePath(String audioUrl) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = audioUrl.split('/').last;
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    if (await file.exists()) {
      return filePath;
    } else {
      return null;
    }
  }

  Future<void> _togglePlayPause() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }

    setState(() {
      isPlaying = !isPlaying;
    });
  }

  Future<void> _toggleLikeStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.email);

      final userDoc = await userDocRef.get();

      List<dynamic> booksliked =
          userDoc.exists && userDoc.data()!['booksliked'] != null
              ? List.from(userDoc.data()!['booksliked'])
              : [];

      if (isLiked) {
        booksliked.remove(widget.bookId);
      } else {
        booksliked.add(widget.bookId);
      }

      await userDocRef.update({'booksliked': booksliked});

      setState(() {
        isLiked = !isLiked;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }
  }

  void _changeSpeed(double speed) {
    setState(() {
      selectedSpeed = speed;
      _audioPlayer.setSpeed(speed);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.book['title'] ?? 'AudioBook Details',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        iconTheme:
            IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'book-${widget.book['id']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        widget.book['cover'] ??
                            'https://media.istockphoto.com/id/1396814518/vector/image-coming-soon-no-photo-no-thumbnail-image-available-vector-illustration.jpg?s=612x612&w=0&k=20&c=hnh2OZgQGhf0b46-J2z7aHbIWwq8HNlSDaNp2wn_iko=',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.book['title'] ?? 'Unknown Title',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: _toggleLikeStatus,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.book['author'] ?? 'Unknown Author',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.book['genre'] ?? 'Unknown Genre'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.book['description'] ?? 'No description available.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Duration: ${widget.book['duration'] ?? 'Unknown'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: currentPosition.inSeconds.toDouble(),
                  min: 0.0,
                  max: totalDuration.inSeconds.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      isSeekBarBeingDragged = true;
                      currentPosition = Duration(seconds: value.toInt());
                    });
                    _audioPlayer.seek(currentPosition);
                  },
                  onChangeEnd: (_) {
                    setState(() {
                      isSeekBarBeingDragged = false;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentPosition.toString().split('.').first,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      totalDuration.toString().split('.').first,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.replay_5,
                        size: 30,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () {
                        final newPosition =
                            currentPosition - const Duration(seconds: 5);
                        _audioPlayer.seek(newPosition > Duration.zero
                            ? newPosition
                            : Duration.zero);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 60,
                        color: Colors.blueAccent,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.forward_5,
                        size: 30,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () {
                        final newPosition =
                            currentPosition + const Duration(seconds: 5);
                        _audioPlayer.seek(newPosition < totalDuration
                            ? newPosition
                            : totalDuration);
                      },
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<double>(
                      value: selectedSpeed,
                      items: speedOptions
                          .map((speed) => DropdownMenuItem<double>(
                                value: speed,
                                child: Text('${speed}x'),
                              ))
                          .toList(),
                      onChanged: (speed) {
                        if (speed != null) {
                          _changeSpeed(speed);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
