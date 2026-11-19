import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseListo = false;
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 6));
    firebaseListo = true;
  } catch (e) {
    debugPrint('Error al inicializar Firebase: $e');
  }

  runApp(CatalogApp(firebaseListo: firebaseListo));
}

class CatalogApp extends StatelessWidget {
  final bool firebaseListo;
  const CatalogApp({super.key, required this.firebaseListo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catálogo con Firebase',
      theme: ThemeData.dark(),
      home: MovieCatalogScreen(firebaseListo: firebaseListo),
    );
  }
}

class MovieCatalogScreen extends StatefulWidget {
  final bool firebaseListo;
  const MovieCatalogScreen({super.key, required this.firebaseListo});

  @override
  State<MovieCatalogScreen> createState() => _MovieCatalogScreenState();
}

class _MovieCatalogScreenState extends State<MovieCatalogScreen> {
  Future<void> _agregarPelicula() async {
    if (!widget.firebaseListo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase aún no está conectado; revisa la configuración.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('peliculas').add({
        'titulo': 'Película #${DateTime.now().second}',
        'descripcion': 'Agregada desde la app en Flutter.',
        'fecha': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Película guardada en Firebase!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar en Firestore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Películas'),
        centerTitle: true,
      ),
      body: widget.firebaseListo
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('peliculas').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error al leer datos: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sin películas aún.\nToca el botón + para agregar una.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.movie, color: Colors.redAccent),
                        title: Text(data['titulo'] ?? 'Sin título'),
                        subtitle: Text(data['descripcion'] ?? 'Sin descripción'),
                      ),
                    );
                  },
                );
              },
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'La app abrió, pero Firebase.initializeApp() no completó.\nRevisa google-services.json y la consola de Firebase.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarPelicula,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}