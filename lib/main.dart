import 'package:documentmanager/invoice_status.dart';
import 'package:documentmanager/invoice_summary.dart';
import 'package:documentmanager/payment_history.dart';
import 'package:documentmanager/payment_logging.dart';
import 'package:documentmanager/reciept_generation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prevent duplicate initialization
  try {
    // Try to initialize only if not already done
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyD0MWojZWiN6GE_BkAjz1hSgANSRkTw3W4",
          authDomain: "documentmanager-8bc79.firebaseapp.com",
          projectId: "documentmanager-8bc79",
          storageBucket: "documentmanager-8bc79.firebasestorage.app",
          messagingSenderId: "75816416281",
          appId: "1:75816416281:web:a3d3b39ebdfcf29964a688",
          measurementId: "G-SZ3KBY265V",
        ),
      );
    }
  } catch (e) {
    print('Firebase initialization skipped: $e');
  }

  runApp(CostManagementApp());
}

class CostManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cost Management',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF009688),
          secondary: Color(0xFF26A69A),
          surface: Colors.white,
          background: Colors.grey[50]!,
          error: Color(0xFFD32F2F),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF009688),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF009688)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF009688),
          elevation: 4,
        ),
      ),
      home: MainHome(),
    );
  }
}

class MainHome extends StatefulWidget {
  @override
  _MainHomeState createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    PaymentLoggingScreen(),
    ReceiptGenerationScreen(),
    InvoiceStatusTrackingScreen(),
    PaymentHistoryLogScreen(),
    InvoiceSummaryReportScreen(),
  ];

  final List<String> _titles = [
    'Log Payment',
    'Generate Receipt',
    'Invoice Status',
    'Payment History',
    'Invoice Summary',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Receipt'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Summary'),
        ],
      ),
    );
  }
}
