import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Quote {
  final int id;
  final String text;
  final String author;

  Quote({required this.id, required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as int? ?? 0,
      text: json['frase'] as String? ?? '',
      author: json['autor'] as String? ?? 'Desconhecido',
    );
  }
}

class QuoteNotifier extends StateNotifier<AsyncValue<Quote>> {
  QuoteNotifier() : super(const AsyncValue.loading()) {
    fetchQuote();
  }

  // Fallback quotes just in case the API request fails
  static final List<Quote> _fallbackQuotes = [
    Quote(
      id: -1,
      text:
          "Eu faço da dificuldade a minha motivação. A volta por cima vem na continuação.",
      author: "Chorão",
    ),
    Quote(
      id: -2,
      text:
          "Tudo o que um sonho precisa para ser realizado é alguém que acredite que ele possa ser realizado.",
      author: "Roberto Shinyashiki",
    ),
    Quote(
      id: -3,
      text: "A persistência é o caminho do êxito.",
      author: "Charles Chaplin",
    ),
    Quote(
      id: -4,
      text: "No meio da dificuldade encontra-se a oportunidade.",
      author: "Albert Einstein",
    ),
    Quote(
      id: -5,
      text:
          "Lute. Acredite. Conquiste. Perca. Deseje. Espere. Alcance. Invada. Caia. Seja tudo o quiser ser, mas, acima de tudo, seja você sempre.",
      author: "Tumblr",
    ),
  ];

  Future<void> fetchQuote() async {
    state = const AsyncValue.loading();
    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/devmatheusguerra/frasesJSON/master/frases.json'));

      if (response.statusCode == 200) {
        // Fix encoding issues if any by decoding as utf8
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(decodedBody);

        if (data.isNotEmpty) {
          // Select a random quote from the array
          final dataList = data.cast<Map<String, dynamic>>();
          dataList.shuffle();
          final randomData = dataList.first;
          state = AsyncValue.data(Quote.fromJson(randomData));
          return;
        }
      }

      // If we reach here, either the list was empty or the status wasn't 200
      _useFallback();
    } catch (e) {
      // In case of any exception (like no internet connection)
      _useFallback();
    }
  }

  void _useFallback() {
    final list = List<Quote>.from(_fallbackQuotes);
    list.shuffle();
    state = AsyncValue.data(list.first);
  }
}

final quoteProvider =
    StateNotifierProvider<QuoteNotifier, AsyncValue<Quote>>((ref) {
  return QuoteNotifier();
});
