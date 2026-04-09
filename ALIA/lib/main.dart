import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/add_task_screen.dart';
import 'screens/plan_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const AILAApp());
}

class AILAApp extends StatelessWidget {
  const AILAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AILA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFF60A5FA),
          surface: Color(0xFF16162A),
          error: Color(0xFFF87171),
        ),
        textTheme: GoogleFonts.dmSansTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.syne(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          titleLarge: GoogleFonts.syne(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          titleMedium: GoogleFonts.syne(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFC4B5FD),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF16162A),
          selectedItemColor: Color(0xFF7C3AED),
          unselectedItemColor: Color(0xFF55557A),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF16162A),
          labelStyle: const TextStyle(color: Color(0xFF8888AA)),
          hintStyle: const TextStyle(color: Color(0xFF55557A)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2D2D4E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2D2D4E)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF16162A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF252540)),
          ),
          elevation: 0,
        ),
      ),
      home: const RootNavigator(),
    );
  }
}

class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});

  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TasksScreen(),
    AddTaskScreen(),
    PlanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF1E1E38), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Add'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Plan'),
          ],
        ),
      ),
    );
  }
}
