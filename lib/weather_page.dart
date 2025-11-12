import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _loading = false;
  Map<String, dynamic>? _weather;

  Future<void> _fetchWeather(String city) async {
    final sanitizedCity = city.trim().replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'), '');
    if (sanitizedCity.isEmpty) {
      setState(() => _error = 'Por favor ingresa una ciudad válida.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _weather = null;
    });

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'q': '$sanitizedCity,MX',
      'appid': dotenv.env['API_KEY'],
      'units': 'metric',
      'lang': 'es'
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        setState(() {
          _weather = jsonDecode(response.body);
        });
      } else if (response.statusCode == 404) {
        setState(() => _error = 'Ciudad no encontrada.');
      } else if (response.statusCode == 429) {
        setState(() => _error = 'Demasiadas peticiones. Intenta más tarde.');
      } else {
        setState(() => _error = 'Error del servidor (${response.statusCode}).');
      }
    } on TimeoutException {
      setState(() => _error = 'Tiempo de espera agotado.');
    } catch (e) {
      setState(() => _error = 'Error de conexión: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clima con API Segura')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                hintText: 'Ejemplo: Querétaro',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _fetchWeather,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _fetchWeather(_controller.text),
              child: const Text('Consultar clima'),
            ),
            const SizedBox(height: 30),
            if (_loading)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_weather != null)
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weather!['name'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_weather!['main']['temp']}°C',
                          style: const TextStyle(fontSize: 48),
                        ),
                        Text(_weather!['weather'][0]['description']),
                      ],
                    ),
                  ),
                ),
              )
            else
              const Text('Introduce una ciudad para consultar el clima.'),
          ],
        ),
      ),
    );
  }
}
