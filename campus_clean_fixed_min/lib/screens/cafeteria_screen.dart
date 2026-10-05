import 'package:flutter/material.dart';

class CafeteriaScreen extends StatefulWidget {
  const CafeteriaScreen({super.key});

  @override
  State<CafeteriaScreen> createState() => _CafeteriaScreenState();
}

class _CafeteriaScreenState extends State<CafeteriaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, List<String>> weeklyMenu = {
    'Monday': ['Lentil Soup', 'Chicken Saute', 'Rice', 'Dessert'],
    'Tuesday': ['Ezogelin Soup', 'Meatballs', 'Pasta', 'Fruit'],
    'Wednesday': ['Tomato Soup', 'Baked Chicken', 'Bulgur Pilaf', 'Dessert'],
    'Thursday': ['Tarhana Soup', 'Beef Saute', 'Rice', 'Salad'],
    'Friday': ['Vegetable Soup', 'Fish', 'Mashed Potatoes', 'Fruit'],
  };

  List<String> get todayMenu => weeklyMenu['Monday']!; // demo

  final TextEditingController _planController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _planController.dispose();
    super.dispose();
  }

  void _savePlan() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved: ${_planController.text}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cafeteria Menu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TODAY
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: todayMenu.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.restaurant_menu),
                          title: Text(todayMenu[index]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Note: In a real system, this data would be fetched from the university cafeteria API.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _planController,
                  decoration: const InputDecoration(
                    labelText: 'Today I plan to eat...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savePlan,
                    child: const Text('Save Plan'),
                  ),
                ),
              ],
            ),
          ),

          // WEEK
          ListView(
            padding: const EdgeInsets.all(16),
            children: weeklyMenu.entries.map((entry) {
              return Card(
                child: ExpansionTile(
                  title: Text(entry.key),
                  children: entry.value
                      .map(
                        (meal) => ListTile(
                          leading: const Icon(Icons.circle, size: 10),
                          title: Text(meal),
                        ),
                      )
                      .toList(),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
