import 'package:flutter/material.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  // MVP: kampüs içi yazılı yön tarifleri (örnek)
  final Map<String, List<String>> routesFromMainEntrance = {
    "AYZ.E1-320": [
      "Start at the Main Entrance.",
      "Walk straight for ~25 meters.",
      "Turn right at the security desk.",
      "Continue straight until the corridor ends.",
      "Take the stairs to Floor 3.",
      "Turn left and follow the signs to E1 Block.",
      "Room AYZ.E1-320 will be on your right.",
    ],
    "AYZ.E1-110": [
      "Start at the Main Entrance.",
      "Walk straight for ~20 meters.",
      "Turn left at the cafeteria sign.",
      "Go straight for ~30 meters.",
      "Enter E1 Block corridor.",
      "Room AYZ.E1-110 will be on your left.",
    ],
    "AYZ.223[0]": [
      "Start at the Main Entrance.",
      "Walk straight for ~15 meters.",
      "Turn right at the information desk.",
      "Take the elevator to Floor 2.",
      "Exit the elevator and turn left.",
      "Continue straight; room AYZ.223[0] is ahead on the right.",
    ],
    "AYZ.133[0]": [
      "Start at the Main Entrance.",
      "Walk straight for ~10 meters.",
      "Turn right and enter the main corridor.",
      "Continue straight for ~40 meters.",
      "Room AYZ.133[0] will be on your left.",
    ],
  };

  final List<String> roomOptions = [
    "AYZ.E1-320",
    "AYZ.E1-110",
    "AYZ.223[0]",
    "AYZ.133[0]",
  ];

  String selectedRoom = "AYZ.E1-320";

  @override
  Widget build(BuildContext context) {
    final steps = routesFromMainEntrance[selectedRoom] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Campus Navigation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select a classroom",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedRoom,
              items: roomOptions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedRoom = value);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Destination",
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Turn-by-turn directions (Prototype)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                itemCount: steps.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(child: Text("${index + 1}")),
                    title: Text(steps[index]),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              "Note: This is a rule-based prototype. In a full version, directions can be generated from a campus map graph.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
