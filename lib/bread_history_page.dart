import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BreadHistoryPage extends StatefulWidget {
  const BreadHistoryPage({Key? key}) : super(key: key);

  @override
  BreadHistoryPageState createState() => BreadHistoryPageState();
}

class BreadHistoryPageState extends State<BreadHistoryPage> {
  List<Map<String, dynamic>> _breadHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBreadHistory();
  }

  Future<void> _loadBreadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('bread_history') ?? '[]';
    setState(() {
      _breadHistory = List<Map<String, dynamic>>.from(
        jsonDecode(historyJson) as List,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Use theme's scaffold background color
      // backgroundColor: colorScheme.background, // Often the default

      appBar: AppBar(
        title: const Text('Bread History'),
        // backgroundColor and elevation are defined in AppBarTheme in MaterialApp
        // backgroundColor: Colors.brown[50], // Remove hardcoded color
        // elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary, // Use primary color
              ),
            )
          : _breadHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: colorScheme
                            .onSurfaceVariant, // Use a theme-aware color
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bread history yet',
                        style: textTheme.titleMedium?.copyWith(
                          // Use text theme
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your daily bread will appear here',
                        style: textTheme.bodyMedium?.copyWith(
                          // Use text theme
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _breadHistory.length,
                  itemBuilder: (context, index) {
                    final bread = _breadHistory[index];
                    final date = DateTime.parse(bread['date']);
                    final formattedDate =
                        '${date.month}/${date.day}/${date.year}';
                    return Card(
                      // Card color is defined in the theme
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            bread['imagePath'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          bread['name'],
                          style: textTheme.titleLarge?.copyWith(
                            // Use text theme
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              bread['origin'],
                              style: textTheme.bodyMedium?.copyWith(
                                // Use text theme
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Viewed on $formattedDate',
                              style: textTheme.bodySmall?.copyWith(
                                // Use text theme
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Navigate to detailed view of this bread
                          // This would be implemented in a full app
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
