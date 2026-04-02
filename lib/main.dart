import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'tab_add.dart';
import 'tab_list.dart';
import 'tab_purchase.dart';
import 'widgets/background_glow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await FirebaseAuth.instance.signInAnonymously();
  } catch (_) {
    // Firebase may not be configured in every environment.
  }

  runApp(const SurgeryMemoApp());
}

class SurgeryMemoApp extends StatelessWidget {
  const SurgeryMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFFF4F7FB);
    const ink = Color(0xFF1D2740);
    const terracotta = Color(0xFF5672D9);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Surgery Memo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: terracotta,
          brightness: Brightness.light,
          surface: base,
        ),
        scaffoldBackgroundColor: base,
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1.1,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyLarge: TextStyle(fontSize: 15, color: ink, height: 1.5),
          bodyMedium: TextStyle(
            fontSize: 13,
            color: Color(0xFF5D6885),
            height: 1.45,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.72),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7E1F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: terracotta, width: 1.4),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.86),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFDCE5F2)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE3ECFB),
          labelStyle: const TextStyle(
            color: ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          side: BorderSide.none,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const RecordsListScreen(),
      const CounselingRecordScreen(),
      const PurchaseScreen(),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FAFF), Color(0xFFEAF1FD), Color(0xFFE6F6F4)],
          ),
        ),
        child: Stack(
          children: [
            const BackgroundGlow(
              alignment: Alignment.topRight,
              color: Color(0xFF8EA7FF),
              size: 240,
            ),
            const BackgroundGlow(
              alignment: Alignment.centerLeft,
              color: Color(0xFF82D1C8),
              size: 220,
            ),
            SafeArea(child: screens[_index]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 78,
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        indicatorColor: const Color(0xFFDDE7FF),
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.doc_text),
            selectedIcon: Icon(CupertinoIcons.doc_text_fill),
            label: '記録一覧',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.square_pencil),
            selectedIcon: Icon(CupertinoIcons.square_pencil),
            label: '記録作成',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.star_circle),
            selectedIcon: Icon(CupertinoIcons.star_circle_fill),
            label: '有料機能',
          ),
        ],
      ),
    );
  }
}
