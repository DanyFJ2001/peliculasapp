import 'dart:convert';
import 'package:appcine/pantallas/reproduccionpeli.dart';
import 'package:flutter/material.dart';


class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  Future<List> leerJson(context) async {
    String jsonString = await DefaultAssetBundle.of(context).loadString("assets/data/peliculas.json");
    return json.decode(jsonString);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catálogo de Películas',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          Expanded(
            child: FutureBuilder(
              future: leerJson(context),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final peliculas = snapshot.data!;
                  return ListView.builder(
                    itemCount: peliculas.length,
                    itemBuilder: (context, index) {
                      final pelicula = peliculas[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          leading: Container(
                            width: 60,
                            height: 80,
                            child: Image.network(
                              pelicula['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.movie, size: 30),
                                );
                              },
                            ),
                          ),
                          title: Text(pelicula['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              Text(
                                '${pelicula['year']} • ${pelicula['duration']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                pelicula['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReproduccionScreen(
                                  titulo: pelicula['name'],
                                  videoId: pelicula['videoId'],
                                  description: pelicula['description'],
                                  year: pelicula['year'],
                                  duration: pelicula['duration'],
                                  rating: pelicula['rating'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                } else {
                  return Center(child: Text("Cargando películas..."));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}