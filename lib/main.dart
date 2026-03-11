import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breadify/bread_db.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'notification_service.dart';
import 'settings_page.dart';
import 'bread_history_page.dart';
import 'theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Schedule daily notification
  final prefs = await SharedPreferences.getInstance();
  final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
  if (notificationsEnabled) {
    await notificationService.scheduleDailyBreadNotification();
  }

  runApp(
    ChangeNotifierProvider(
      // Wrap the app with ChangeNotifierProvider
      create: (_) => ThemeNotifier(),
      child: const BreadifyApp(),
    ),
  );
}

class BreadifyApp extends StatelessWidget {
  const BreadifyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Watch the themeMode from the ThemeNotifier
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Breadify',
      theme: ThemeData(
        // Light theme
        primarySwatch: Colors.brown,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.brown[50],
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.brown[800]), // Icons color
          titleTextStyle: TextStyle(
            color: Colors.brown[800],
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        cardColor: Colors.white, // Card background for light mode
      ),
      darkTheme: ThemeData.dark().copyWith(
        // Dark theme based on ThemeData.dark()
        primaryColor: Colors.brown[700],
        hintColor: Colors.amber,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900], // Dark AppBar background
          elevation: 0,
          iconTheme:
              const IconThemeData(color: Colors.white70), // Dark icons color
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        cardColor: Colors.grey[850], // Card background for dark mode
        scaffoldBackgroundColor:
            Colors.grey[900], // Scaffold background for dark mode
      ),
      themeMode: themeNotifier.themeMode, // Use the theme mode from notifier
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/settings': (context) => const SettingsPage(),
        '/history': (context) => const BreadHistoryPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late Bread _todaysBread;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation _opacityAnimation;
  late Animation _scaleAnimation;
  String _lastUpdated = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _loadBreadOfTheDay();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBreadOfTheDay() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastBreadDate = prefs.getString('last_bread_date');

    if (lastBreadDate == today) {
      // Load saved bread data if it's from today
      final savedBreadData = prefs.getString('bread_data');
      if (savedBreadData != null) {
        final breadData = json.decode(savedBreadData);
        _todaysBread = Bread.fromJson(breadData);
        _lastUpdated = prefs.getString('last_updated') ?? 'Today';
      } else {
        await _getNewBread();
      }
    } else {
      await _getNewBread();
    }

    setState(() {
      _isLoading = false;
    });

    _animationController.forward();
  }

  Future<void> _getNewBread() async {
    // Get a random bread from our database
    _todaysBread = breadDatabase[Random().nextInt(breadDatabase.length)];
    // Save it
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await prefs.setString('last_bread_date', today);
    await prefs.setString('bread_data', json.encode(_todaysBread.toJson()));

    final now = DateFormat('MMM d, h:mm a').format(DateTime.now());
    await prefs.setString('last_updated', now);
    _lastUpdated = now;

    // Save to history
    await _saveBreadToHistory(_todaysBread);
  }

  Future<void> _saveBreadToHistory(Bread bread) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('bread_history') ?? '[]';
    final history = List<Map<String, dynamic>>.from(
      jsonDecode(historyJson) as List,
    );
    // Add current bread to history with today's date
    history.insert(0, {
      ...bread.toJson(),
      'date': DateTime.now().toIso8601String(),
    });

    // Limit history to last 30 items
    if (history.length > 30) {
      history.removeRange(30, history.length);
    }

    await prefs.setString('bread_history', jsonEncode(history));
  }

  Future<void> _refreshBread() async {
    _animationController.reset();
    setState(() {
      _isLoading = true;
    });
    await _getNewBread();
    setState(() {
      _isLoading = false;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Use colors from the current theme's color scheme
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Use theme's scaffold background color
      // backgroundColor: colorScheme.background, // This is often the default

      appBar: AppBar(
        // AppBar theme is defined in MaterialApp theme
        title: Row(
          children: [
            Image.asset(
              'assets/icons/app_icon.png',
              height: 24,
              width: 24,
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Breadify',
              style: textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold), // Use text theme
            ),
          ],
        ),
        centerTitle: false,
        // backgroundColor is defined in the AppBarTheme in MaterialApp
        // elevation is defined in the AppBarTheme in MaterialApp
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
            tooltip: 'View Bread History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary, // Use primary color for indicator
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshBread,
              color: colorScheme
                  .primary, // Use primary color for refresh indicator
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                'Bread of the Day',
                                style: textTheme.headlineMedium?.copyWith(
                                  // Use text theme
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme
                                      .onSurface, // Use onSurface for text
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Last updated: $_lastUpdated',
                                style: textTheme.bodySmall?.copyWith(
                                  // Use text theme
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme
                                      .onSurfaceVariant, // A slightly less prominent color
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Card(
                              // Card color is defined in the theme
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  _todaysBread.imagePath,
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _todaysBread.name,
                              style: textTheme.headlineSmall?.copyWith(
                                // Use text theme
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _todaysBread.origin,
                              style: textTheme.titleMedium?.copyWith(
                                // Use text theme
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              // Card color is defined in the theme
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              // color: Colors.brown[50], // Remove hardcoded color
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'About this bread',
                                      style: textTheme.titleLarge?.copyWith(
                                        // Use text theme
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _todaysBread.description,
                                      style: textTheme
                                          .bodyMedium, // Use text theme
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFactSection('Fun Facts', _todaysBread.facts,
                                context), // Pass context
                            const SizedBox(height: 16),
                            _buildFactSection(
                                'Ingredients',
                                _todaysBread.ingredients,
                                context), // Pass context
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshBread,
        backgroundColor: colorScheme.primary, // Use onPrimary for icon color
        tooltip: 'Get a new bread', // Use primary color
        child: Icon(Icons.refresh, color: colorScheme.onPrimary),
      ),
    );
  }

  // Pass BuildContext to _buildFactSection
  Widget _buildFactSection(
      String title, List<dynamic> items, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      // Card color is defined in the theme
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      // color: Colors.amber[50], // Remove hardcoded color
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                // Use text theme
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((fact) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: textTheme.bodyMedium?.copyWith(
                            // Use text theme
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          )),
                      Expanded(
                        child: Text(
                          fact.toString(), // Convert to string
                          style: textTheme.bodyMedium, // Use text theme
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
