import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zalo_mobile_app/common/constants/api_constants.dart';

class StickerPicker extends StatefulWidget {
  const StickerPicker({super.key});

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  List<String> stickers = [];
  bool isLoading = true;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTrending();
  }

  /// 🔥 Lấy sticker trending từ :contentReference[oaicite:0]{index=0}
  Future<void> fetchTrending() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
        "https://api.giphy.com/v1/stickers/trending"
            "?api_key=${ApiConstants.GIPHY_API_KEY}&limit=30",
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        final results = (data['data'] as List)
            .map((e) => e['images']['fixed_height']['url'] as String)
            .toList();

        setState(() {
          stickers = results;
          isLoading = false;
        });
      } else {
        throw Exception("API error");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🔍 Search sticker
  Future<void> fetchSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
        "https://api.giphy.com/v1/stickers/search"
            "?api_key=${ApiConstants.GIPHY_API_KEY}&q=$query&limit=30",
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        final results = (data['data'] as List)
            .map((e) => e['images']['fixed_height']['url'] as String)
            .toList();

        setState(() {
          stickers = results;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          /// 🔹 Thanh kéo
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          /// 🔍 Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Tìm sticker...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.trending_up),
                  onPressed: fetchTrending,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                fetchSearch(value);
              },
            ),
          ),

          const SizedBox(height: 10),

          /// 📦 Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : stickers.isEmpty
                ? const Center(child: Text("Không có sticker"))
                : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: stickers.length,
              itemBuilder: (context, index) {
                final url = stickers[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, url);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}