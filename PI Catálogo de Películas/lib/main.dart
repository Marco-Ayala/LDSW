import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseListo = false;
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 6));
    firebaseListo = true;
  } catch (e) {
    debugPrint('Aviso al inicializar Firebase: $e');
  }

  runApp(MovieCatalogApp(firebaseListo: firebaseListo));
}

class MovieCatalogApp extends StatelessWidget {
  final bool firebaseListo;
  const MovieCatalogApp({super.key, required this.firebaseListo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catálogo de Películas',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: WelcomeScreen(firebaseListo: firebaseListo),
    );
  }
}

// 1. Pantalla de inicio: Bienvenida, Registro e Ingreso de usuario
class WelcomeScreen extends StatefulWidget {
  final bool firebaseListo;
  const WelcomeScreen({super.key, required this.firebaseListo});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _modoRegistro = false;
  String? _usuarioRegistrado;
  String? _passwordRegistrado;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _enviarFormulario() {
    final usuario = _usuarioController.text.trim();
    final pass = _passwordController.text.trim();

    if (usuario.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa tu usuario y contraseña.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_modoRegistro) {
      setState(() {
        _usuarioRegistrado = usuario;
        _passwordRegistrado = pass;
        _modoRegistro = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cuenta creada para "$usuario". Ahora puedes ingresar.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final nombreActivo = _usuarioRegistrado ?? usuario;
      if (_usuarioRegistrado != null &&
          (usuario != _usuarioRegistrado || pass != _passwordRegistrado)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario o contraseña incorrectos.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CatalogHomeScreen(
            usuario: nombreActivo,
            firebaseListo: widget.firebaseListo,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=1000&auto=format&fit=crop',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black87),
          ),
          Container(color: Colors.black.withOpacity(0.75)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.movie_filter_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '¡Bienvenido a CineCatálogo!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _modoRegistro
                          ? 'Crea tu cuenta para explorar películas'
                          : 'Ingresa con tu cuenta para ver el catálogo',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usuarioController,
                      decoration: const InputDecoration(
                        labelText: 'Usuario o correo',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _enviarFormulario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _modoRegistro ? 'Registrarse' : 'Ingresar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _modoRegistro = !_modoRegistro;
                        });
                      },
                      child: Text(
                        _modoRegistro
                            ? '¿Ya tienes cuenta? Ingresa aquí'
                            : '¿No tienes cuenta? Regístrate como usuario',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Contenedor principal con menú superior: Catálogo + Administración
class CatalogHomeScreen extends StatefulWidget {
  final String usuario;
  final bool firebaseListo;

  const CatalogHomeScreen({
    super.key,
    required this.usuario,
    required this.firebaseListo,
  });

  @override
  State<CatalogHomeScreen> createState() => _CatalogHomeScreenState();
}

class _CatalogHomeScreenState extends State<CatalogHomeScreen> {
  int _vistaActual = 0; // 0 = Catálogo, 1 = Administración

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _vistaActual == 0
              ? 'Catálogo (${widget.usuario})'
              : 'Administración de Películas',
        ),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Menú de navegación',
            icon: const Icon(Icons.menu),
            onSelected: (valor) {
              setState(() {
                _vistaActual = valor;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.local_movies, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Catálogo de películas'),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.amber),
                    SizedBox(width: 10),
                    Text('Administración (Alta/Baja)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _vistaActual == 0
          ? MovieCatalogTab(firebaseListo: widget.firebaseListo)
          : MovieAdminTab(firebaseListo: widget.firebaseListo),
    );
  }
}

// 2. PANTALLA DE CATÁLOGO (Firestore + respaldo/consulta HTTP)
class MovieCatalogTab extends StatefulWidget {
  final bool firebaseListo;
  const MovieCatalogTab({super.key, required this.firebaseListo});

  @override
  State<MovieCatalogTab> createState() => _MovieCatalogTabState();
}

class _MovieCatalogTabState extends State<MovieCatalogTab> {
  late Future<List<Map<String, dynamic>>> _httpFallbackFuture;

  @override
  void initState() {
    super.initState();
    _httpFallbackFuture = _obtenerPeliculasHttp();
  }

  Future<List<Map<String, dynamic>>> _obtenerPeliculasHttp() async {
    final res = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/posts?_limit=4'),
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      final ejemplos = [
        {
          'titulo': 'Interestelar',
          'anio': '2014',
          'director': 'Christopher Nolan',
          'genero': 'Ciencia Ficción',
          'sinopsis':
              'Un equipo de exploradores viaja a través de un agujero de gusano en el espacio para garantizar la supervivencia de la humanidad.',
          'imagen':
              'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=800&auto=format&fit=crop',
        },
        {
          'titulo': 'El Padrino',
          'anio': '1972',
          'director': 'Francis Ford Coppola',
          'genero': 'Drama / Crimen',
          'sinopsis':
              'El patriarca de una dinastía criminal transfiere el control de su imperio clandestino a su hijo menor.',
          'imagen':
              'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=800&auto=format&fit=crop',
        },
        {
          'titulo': 'Inception',
          'anio': '2010',
          'director': 'Christopher Nolan',
          'genero': 'Ciencia Ficción / Suspenso',
          'sinopsis':
              'Un ladrón especializado en extraer secretos del subconsciente durante el estado de sueño enfrenta su encargo más complejo.',
          'imagen':
              'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?q=80&w=800&auto=format&fit=crop',
        },
        {
          'titulo': 'Matrix',
          'anio': '1999',
          'director': 'Lana y Lilly Wachowski',
          'genero': 'Acción / Ciencia Ficción',
          'sinopsis':
              'Un programador descubre que la realidad cotidiana es una simulación digital controlada por máquinas.',
          'imagen':
              'https://images.unsplash.com/photo-1478720568477-152d9b164e26?q=80&w=800&auto=format&fit=crop',
        },
      ];

      return List.generate(data.length, (i) {
        final base = ejemplos[i % ejemplos.length];
        return {
          'titulo': base['titulo'],
          'anio': base['anio'],
          'director': base['director'],
          'genero': base['genero'],
          'sinopsis': base['sinopsis'],
          'imagen': base['imagen'],
          'origen': 'HTTP',
        };
      });
    }
    throw Exception('Error en petición HTTP (${res.statusCode})');
  }

  void _abrirDetalle(Map<String, dynamic> pelicula) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(pelicula: pelicula),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseListo) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _httpFallbackFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error HTTP: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          return _buildMovieGrid(items, esFirestore: false);
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('peliculas').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay películas en Firestore todavía.\nAbre el menú superior y ve a Administración para dar de alta una.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final peliculas = docs.map((d) {
          final map = d.data() as Map<String, dynamic>;
          return {
            'id': d.id,
            'titulo': (map['titulo'] ?? 'Sin título').toString(),
            'anio': (map['anio'] ?? 'N/D').toString(),
            'director': (map['director'] ?? 'Desconocido').toString(),
            'genero': (map['genero'] ?? 'General').toString(),
            'sinopsis': (map['sinopsis'] ?? 'Sin sinopsis disponible.').toString(),
            'imagen': (map['imagen'] ?? '').toString(),
          };
        }).toList();

        return _buildMovieGrid(peliculas, esFirestore: true);
      },
    );
  }

  Widget _buildMovieGrid(
    List<Map<String, dynamic>> peliculas, {
    required bool esFirestore,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: peliculas.length,
      itemBuilder: (context, index) {
        final peli = peliculas[index];
        final url = (peli['imagen'] ?? '').toString().trim();

        return InkWell(
          onTap: () => _abrirDetalle(peli),
          borderRadius: BorderRadius.circular(12),
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: url.isNotEmpty
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[850],
                            child: const Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[850],
                          child: const Icon(
                            Icons.movie,
                            size: 40,
                            color: Colors.redAccent,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    peli['titulo'] ?? 'Sin título',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 3. Pantalla de descripción de la película
class MovieDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pelicula;
  const MovieDetailScreen({super.key, required this.pelicula});

  @override
  Widget build(BuildContext context) {
    final url = (pelicula['imagen'] ?? '').toString().trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(pelicula['titulo'] ?? 'Detalle de Película'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: url.isNotEmpty
                  ? Image.network(
                      url,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 240,
                        color: Colors.grey[850],
                        alignment: Alignment.center,
                        child: const Icon(Icons.movie, size: 64),
                      ),
                    )
                  : Container(
                      height: 240,
                      color: Colors.grey[850],
                      alignment: Alignment.center,
                      child: const Icon(Icons.movie, size: 64),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              pelicula['titulo'] ?? 'Sin título',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _DatoFila(label: 'Año de estreno', valor: pelicula['anio'] ?? 'N/D'),
            _DatoFila(label: 'Director', valor: pelicula['director'] ?? 'N/D'),
            _DatoFila(label: 'Género', valor: pelicula['genero'] ?? 'N/D'),
            const SizedBox(height: 16),
            const Text(
              'Sinopsis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              pelicula['sinopsis'] ?? 'Sin sinopsis.',
              style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatoFila extends StatelessWidget {
  final String label;
  final String valor;
  const _DatoFila({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

// 4. Pantalla de administración: Alta y Baja en Firestore
class MovieAdminTab extends StatefulWidget {
  final bool firebaseListo;
  const MovieAdminTab({super.key, required this.firebaseListo});

  @override
  State<MovieAdminTab> createState() => _MovieAdminTabState();
}

class _MovieAdminTabState extends State<MovieAdminTab> {
  final _tituloCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  final _directorCtrl = TextEditingController();
  final _generoCtrl = TextEditingController();
  final _sinopsisCtrl = TextEditingController();
  final _imagenCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _anioCtrl.dispose();
    _directorCtrl.dispose();
    _generoCtrl.dispose();
    _sinopsisCtrl.dispose();
    _imagenCtrl.dispose();
    super.dispose();
  }

  Future<void> _darDeAlta() async {
    if (!widget.firebaseListo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase no está conectado en este momento.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_tituloCtrl.text.trim().isEmpty ||
        _anioCtrl.text.trim().isEmpty ||
        _directorCtrl.text.trim().isEmpty ||
        _generoCtrl.text.trim().isEmpty ||
        _sinopsisCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa título, año, director, género y sinopsis.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await FirebaseFirestore.instance.collection('peliculas').add({
        'titulo': _tituloCtrl.text.trim(),
        'anio': _anioCtrl.text.trim(),
        'director': _directorCtrl.text.trim(),
        'genero': _generoCtrl.text.trim(),
        'sinopsis': _sinopsisCtrl.text.trim(),
        'imagen': _imagenCtrl.text.trim().isEmpty
            ? 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=800&auto=format&fit=crop'
            : _imagenCtrl.text.trim(),
        'creadaEn': Timestamp.now(),
      });

      _tituloCtrl.clear();
      _anioCtrl.clear();
      _directorCtrl.clear();
      _generoCtrl.clear();
      _sinopsisCtrl.clear();
      _imagenCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Película dada de alta en la base de datos.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _darDeBaja(String docId, String titulo) async {
    try {
      await FirebaseFirestore.instance
          .collection('peliculas')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se dio de baja "$titulo".'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Alta de película',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tituloCtrl,
            decoration: const InputDecoration(
              labelText: 'Título',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _anioCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Año de estreno',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _directorCtrl,
            decoration: const InputDecoration(
              labelText: 'Director',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _generoCtrl,
            decoration: const InputDecoration(
              labelText: 'Género cinematográfico',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _sinopsisCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Sinopsis',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _imagenCtrl,
            decoration: const InputDecoration(
              labelText: 'URL de la imagen / póster',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _guardando ? null : _darDeAlta,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: const Text('Dar de alta película'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Baja de películas registradas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (!widget.firebaseListo)
            const Text('Conecta Firebase para administrar películas en la base de datos.')
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('peliculas').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text('No hay películas para dar de baja.');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final titulo = (data['titulo'] ?? 'Sin título').toString();

                    return Card(
                      child: ListTile(
                        title: Text(titulo),
                        subtitle: Text(
                          '${data['anio'] ?? ''} • ${data['director'] ?? ''}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _darDeBaja(doc.id, titulo),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}