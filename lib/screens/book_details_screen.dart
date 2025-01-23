import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final String bookId;

  static const routeName = '/book-details';

  const BookDetailsScreen({
    super.key,
    required this.book,
    required this.bookId,
    required Map bookData,
    required onLikeStatusChanged,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (userDoc.exists && userDoc.data()?['booksliked'] != null) {
        List<dynamic> booksliked = userDoc.data()?['booksliked'] ?? [];
        setState(() {
          isLiked = booksliked.contains(widget.bookId);
        });
      }
    } catch (e) {}
  }

  Future<void> _toggleLikeStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.email);
      final userDoc = await userDocRef.get();

      List<dynamic> booksliked = [];
      if (userDoc.exists && userDoc.data()?['booksliked'] != null) {
        booksliked = List.from(userDoc.data()?['booksliked']);
      }

      if (isLiked) {
        booksliked.remove(widget.bookId);
      } else {
        booksliked.add(widget.bookId);
      }

      await userDocRef.set({'booksliked': booksliked}, SetOptions(merge: true));

      setState(() {
        isLiked = !isLiked;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred while updating like status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.book['title'] ?? 'Book Details',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
                  tag: 'book-${widget.bookId}',
                  child: Container(
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(widget.book['cover'] ??
                            'https://media.istockphoto.com/id/1396814518/vector/image-coming-soon-no-photo-no-thumbnail-image-available-vector-illustration.jpg?s=612x612&w=0&k=20&c=hnh2OZgQGhf0b46-J2z7aHbIWwq8HNlSDaNp2wn_iko='),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.book['title'] ?? 'Unknown Title',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 30,
                            ),
                            onPressed: _toggleLikeStatus,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.book['genre'] ?? 'Unknown Genre',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.book['description']?.replaceAll(r'\n', '\n') ??
                            'No description available.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            widget.book['available'] == true
                                ? 'Status: Available'
                                : 'Status: Not Available',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: widget.book['available'] == true
                                  ? Colors.green
                                  : Colors.redAccent,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(widget.book['available'] == true
                                        ? 'Book Available'
                                        : 'Book Unavailable'),
                                    content: Text(
                                      widget.book['available'] == true
                                          ? 'The book is currently available in the library.'
                                          : 'The book is not available right now. Please wait for a few days or contact the library for further details.',
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Icon(
                              Icons.help_outline,
                              color: widget.book['available'] == true
                                  ? Colors.green
                                  : Colors.redAccent,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
