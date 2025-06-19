import 'package:flutter/material.dart';

class BuscarScreen extends StatefulWidget {
  final List<dynamic> allMovies;
  final Function(Map<String, dynamic>) onMovieTap;

  const BuscarScreen({
    super.key,
    required this.allMovies,
    required this.onMovieTap,
  });

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  List<dynamic> _filteredMovies = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredMovies = widget.allMovies;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMovies(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMovies = widget.allMovies;
      } else {
        _filteredMovies = widget.allMovies.where((movie) {
          return movie['name'].toLowerCase().contains(query.toLowerCase()) ||
                 movie['description'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Text(
            'Buscar',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Buscar películas, series, documentales...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.6),
            size: 24,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterMovies('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: _filterMovies,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return _buildRecentSearches();
    }

    if (_filteredMovies.isEmpty) {
      return _buildNoResults();
    }

    return _buildMoviesGrid();
  }

  Widget _buildRecentSearches() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Categorías populares',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildCategoriesGrid(),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Tendencias de búsqueda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildTrendingSearches(),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'name': 'Acción', 'icon': Icons.local_fire_department, 'color': Colors.red},
      {'name': 'Comedia', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.orange},
      {'name': 'Drama', 'icon': Icons.theater_comedy, 'color': Colors.blue},
      {'name': 'Terror', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.purple},
      {'name': 'Ciencia Ficción', 'icon': Icons.rocket_launch, 'color': Colors.cyan},
      {'name': 'Animación', 'icon': Icons.palette, 'color': Colors.pink},
    ];

    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                _searchController.text = category['name'] as String;
                _filterMovies(category['name'] as String);
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (category['color'] as Color).withOpacity(0.8),
                      (category['color'] as Color).withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (category['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingSearches() {
    final trendingSearches = [
      'Avengers',
      'Spider-Man',
      'Batman',
      'Harry Potter',
      'Star Wars',
      'Marvel',
      'DC Comics',
      'Disney',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: trendingSearches.map((search) {
          return GestureDetector(
            onTap: () {
              _searchController.text = search;
              _filterMovies(search);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    search,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No se encontraron resultados',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con palabras diferentes o revisa la ortografía',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _filterMovies('');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Limpiar búsqueda',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredMovies.length,
      itemBuilder: (context, index) {
        final movie = _filteredMovies[index];
        return _buildMovieCard(movie);
      },
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    return GestureDetector(
      onTap: () => widget.onMovieTap(movie),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Imagen de la película
              Image.network(
                movie['image'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF1C1C1E),
                    child: const Center(
                      child: Icon(Icons.movie, size: 40, color: Colors.white38),
                    ),
                  );
                },
              ),
              
              // Gradiente overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              
              // Información de la película
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${movie['year']} • ${movie['rating']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Badge de rating en la esquina superior derecha
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRatingColor(movie['rating']).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    movie['rating'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

  Color _getRatingColor(String rating) {
    switch (rating.toUpperCase()) {
      case 'G':
        return Colors.green;
      case 'PG':
        return Colors.blue;
      case 'PG-13':
        return Colors.orange;
      case 'R':
      case 'NC-17':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}