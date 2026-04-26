import 'package:flutter/material.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/custom_horizontal_divider.dart';
import 'package:purepath/core/widgets/space.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kLightGreyColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Space.vertical(12),
          _postText(),
          Space.vertical(12),
          _postImage(),
          Space.vertical(12),
          CustomHorizontalDivider(),
          Space.vertical(8),
          _actionsRow(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
        ),
        Space.horizontal(10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sarah Jenkins",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text("2h ago", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const Icon(Icons.more_horiz),
      ],
    );
  }

  Widget _postText() {
    return const Text(
      "Just finished the morning walk at Central Park. "
      "The new blossom trees are absolutely stunning this year! 🌸 "
      "Who else is out enjoying the weather?",
      style: TextStyle(fontSize: 15, height: 1.5),
    );
  }

  Widget _postImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _actionsRow() {
    return Row(
      children: [
        const Icon(Icons.favorite_border, size: 22),
        const SizedBox(width: 6),
        const Text("124"),
        const SizedBox(width: 20),

        const Icon(Icons.chat_bubble_outline, size: 22),
        const SizedBox(width: 6),
        const Text("18"),
        const SizedBox(width: 20),
      ],
    );
  }
}
