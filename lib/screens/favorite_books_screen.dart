import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'audio_book_details_screen.dart';
import 'book_details_screen.dart';

class FavoriteBooksScreen extends StatefulWidget {
  static const routeName = '/favorite-books';

  const FavoriteBooksScreen({super.key});

  @override
  _FavoriteBooksScreenState createState() => _FavoriteBooksScreenState();
}

class _FavoriteBooksScreenState extends State<FavoriteBooksScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedType = 'All';
  Set<String> _favoriteBooks = {};

  @override
  void initState() {
    super.initState();
    _loadFavoriteBooks();
  }

  Future<void> _loadFavoriteBooks() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .get();

        if (userDoc.exists) {
          final likedBooks =
              List<String>.from(userDoc.data()?['booksliked'] ?? []);

          setState(() {
            _favoriteBooks = likedBooks.toSet();
          });
        }
      } catch (e) {
        print('Error fetching liked books: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [Colors.black, Colors.grey.shade900]
                      : [
                          Colors.pinkAccent.shade700,
                          Colors.pinkAccent.shade400
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: 35,
              left: 15,
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeroSection(context, isDarkMode),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(context, isDarkMode),
                    const SizedBox(height: 16),
                    _buildTypeFilter(isDarkMode),
                    const SizedBox(height: 16),
                    _buildFilterChips(isDarkMode),
                    const SizedBox(height: 16),
                    Expanded(child: _buildBooksGrid(context, isDarkMode)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDarkMode) {
    return Hero(
      tag: 'card_Favorite Books',
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.black, Colors.grey.shade900]
                  : [Colors.pinkAccent.shade700, Colors.pinkAccent.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Stack(
            children: [
              const Positioned(
                bottom: 30,
                left: 15,
                child: Text(
                  'Favorite Books',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.5,
                  child: Icon(
                    Icons.favorite,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBooksGrid(BuildContext context, bool isDarkMode) {
    final screenWidth = MediaQuery.of(context).size.width;
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance.collectionGroup('audiobooks').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> audiobooksSnapshot) {
        if (audiobooksSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (audiobooksSnapshot.hasError) {
          return Center(
            child: Text('Error: ${audiobooksSnapshot.error}',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          );
        } else {
          return StreamBuilder(
            stream: FirebaseFirestore.instance.collection('books').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> booksSnapshot) {
              if (booksSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (booksSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${booksSnapshot.error}',
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black)),
                );
              } else {
                final audiobooks = audiobooksSnapshot.data?.docs ?? [];
                final books = booksSnapshot.data?.docs ?? [];
                final allBooks = [...audiobooks, ...books];

                final filteredBooks = allBooks.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bookId = data['id']?.toString();

                  if (bookId == null || !_favoriteBooks.contains(bookId))
                    return false;

                  final matchesSearch =
                      data['title'].toLowerCase().contains(_searchQuery) ||
                          data['author'].toLowerCase().contains(_searchQuery) ||
                          data['genre'].toLowerCase().contains(_searchQuery);

                  final matchesFilter = _selectedFilter == 'All' ||
                      data['genre'].toLowerCase() ==
                          _selectedFilter.toLowerCase();

                  final matchesType = _selectedType == 'All' ||
                      (_selectedType == 'Books' && bookId.startsWith('b')) ||
                      (_selectedType == 'Audiobooks' && bookId.startsWith('a'));

                  return matchesSearch && matchesFilter && matchesType;
                }).toList();

                filteredBooks.sort((a, b) {
                  final titleA = (a.data() as Map<String, dynamic>)['title']
                          ?.toLowerCase() ??
                      '';
                  final titleB = (b.data() as Map<String, dynamic>)['title']
                          ?.toLowerCase() ??
                      '';
                  return titleA.compareTo(titleB);
                });

                return filteredBooks.isEmpty
                    ? Center(
                        child: Text('No favorite books found.',
                            style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black)),
                      )
                    : GridView.builder(
                        itemCount: filteredBooks.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: screenWidth > 800
                              ? 1.5
                              : screenWidth > 600
                                  ? 1.2
                                  : screenWidth > 400
                                      ? 0.7
                                      : 0.539,
                        ),
                        itemBuilder: (context, index) {
                          final book = filteredBooks[index];
                          final data = book.data() as Map<String, dynamic>;
                          final isAudiobook = audiobooks.contains(book);

                          return _buildBookCard(
                              context, data, isDarkMode, isAudiobook);
                        },
                      );
              }
            },
          );
        }
      },
    );
  }

  Widget _buildBookCard(BuildContext context, Map<String, dynamic> book,
      bool isDarkMode, bool isAudiobook) {
    _favoriteBooks.contains(book['id']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              if (isAudiobook) {
                return AudioBookDetailsScreen(
                  book: book,
                  bookId: book['id'].toString(),
                );
              } else {
                return BookDetailsScreen(
                  book: book,
                  bookId: book['id'].toString(),
                  bookData: const {},
                  onLikeStatusChanged: null,
                );
              }
            },
          ),
        );
      },
      child: Hero(
        tag: 'book-${book['id']}',
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Image.network(
                      book['cover'] ??
                          'https://media.istockphoto.com/id/1396814518/vector/image-coming-soon-no-photo-no-thumbnail-image-available-vector-illustration.jpg?s=612x612&w=0&k=20&c=hnh2OZgQGhf0b46-J2z7aHbIWwq8HNlSDaNp2wn_iko=',
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'] ?? 'Unknown Title',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book['author'] ?? 'Unknown Author',
                      style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDarkMode) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search,
            color: isDarkMode ? Colors.grey : Colors.pinkAccent),
        hintText: 'Search for favorite books...',
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
            color:
                isDarkMode ? Colors.grey.shade400 : Colors.pinkAccent.shade100),
      ),
      onChanged: (query) {
        setState(() {
          _searchQuery = query.toLowerCase();
        });
      },
    );
  }

  Widget _buildTypeFilter(bool isDarkMode) {
    List<String> types = ['All', 'Books', 'Audiobooks'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilterChip(
              label: Text(
                type,
                style: TextStyle(
                  color: _selectedType == type
                      ? Colors.white
                      : (isDarkMode
                          ? Colors.grey.shade400
                          : Colors.pinkAccent.shade700),
                ),
              ),
              selected: _selectedType == type,
              onSelected: (isSelected) {
                setState(() {
                  _selectedType = isSelected ? type : 'All';
                });
              },
              backgroundColor: isDarkMode
                  ? Colors.grey.shade800
                  : Colors.pinkAccent.shade100,
              selectedColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.pinkAccent.shade200,
              labelStyle: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChips(bool isDarkMode) {
    List<String> filters = [
      'All',
      'Fantasy',
      'Fiction',
      'History',
      'Romance',
      'Science',
      'Studies'
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: _selectedFilter == filter
                      ? Colors.white
                      : (isDarkMode
                          ? Colors.grey.shade400
                          : Colors.pinkAccent.shade700),
                ),
              ),
              selected: _selectedFilter == filter,
              onSelected: (isSelected) {
                setState(() {
                  _selectedFilter = isSelected ? filter : 'All';
                });
              },
              backgroundColor: isDarkMode
                  ? Colors.grey.shade800
                  : Colors.pinkAccent.shade100,
              selectedColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.pinkAccent.shade200,
              labelStyle: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ),
    );
  }
}
