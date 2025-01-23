import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'audio_book_details_screen.dart';

class AudioBooksScreen extends StatefulWidget {
  static const routeName = '/audioBooks';

  const AudioBooksScreen({super.key});

  @override
  _AudioBooksScreenState createState() => _AudioBooksScreenState();
}

class _AudioBooksScreenState extends State<AudioBooksScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

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
                      : [Colors.blue.shade700, Colors.blue.shade400],
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
                    _buildFilterChips(isDarkMode),
                    const SizedBox(height: 16),
                    Expanded(child: _buildAudioBooksGrid(context, isDarkMode)),
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
      tag: 'card_Audio Books',
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.black, Colors.grey.shade900]
                  : [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 30,
                left: 15,
                child: const Text(
                  'Audio Books',
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
                    Icons.headset,
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

  Widget _buildAudioBooksGrid(BuildContext context, bool isDarkMode) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('audiobooks').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('No audio books available.',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black)));
        } else {
          final books = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final matchesSearch =
                data['title'].toLowerCase().contains(_searchQuery) ||
                    data['author'].toLowerCase().contains(_searchQuery) ||
                    data['genre'].toLowerCase().contains(_searchQuery);

            final matchesFilter = _selectedFilter == 'All' ||
                data['genre'].toLowerCase() == _selectedFilter.toLowerCase();
            return matchesSearch && matchesFilter;
          }).toList();

          books.sort((a, b) {
            final titleA =
                (a.data() as Map<String, dynamic>)['title'].toLowerCase();
            final titleB =
                (b.data() as Map<String, dynamic>)['title'].toLowerCase();
            return titleA.compareTo(titleB);
          });

          final screenWidth = MediaQuery.of(context).size.width;

          return GridView.builder(
            itemCount: books.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 600 ? 4 : 2,
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
              final book = books[index];
              final data = book.data() as Map<String, dynamic>;
              return _buildBookCard(context, data, isDarkMode);
            },
          );
        }
      },
    );
  }

  Widget _buildBookCard(
      BuildContext context, Map<String, dynamic> book, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioBookDetailsScreen(
              book: book,
              bookId: book['id'].toString(),
            ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Image.network(
                    book['cover'] ??
                        'https://media.istockphoto.com/id/1396814518/vector/image-coming-soon-no-photo-no-thumbnail-image-available-vector-illustration.jpg?s=612x612&w=0&k=20&c=hnh2OZgQGhf0b46-J2z7aHbIWwq8HNlSDaNp2wn_iko=',
                    fit: BoxFit.cover,
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
                            : Colors.grey.shade600,
                      ),
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
        prefixIcon:
            Icon(Icons.search, color: isDarkMode ? Colors.grey : Colors.blue),
        hintText: 'Search for audio books...',
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : Colors.blue.shade300),
      ),
      onChanged: (query) {
        setState(() {
          _searchQuery = query.toLowerCase();
        });
      },
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
                          : Colors.blue.shade700),
                ),
              ),
              selected: _selectedFilter == filter,
              onSelected: (isSelected) {
                setState(() {
                  _selectedFilter = isSelected ? filter : 'All';
                });
              },
              backgroundColor:
                  isDarkMode ? Colors.grey.shade800 : Colors.blue.shade50,
              selectedColor:
                  isDarkMode ? Colors.grey.shade700 : Colors.blueAccent,
              labelStyle: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ),
    );
  }
}
