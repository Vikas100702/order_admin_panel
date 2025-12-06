import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2A2D3E); // Dark Navy (Sidebar)
  static const Color accentColor = Color(
    0xFF2196F3,
  ); // Blue (Buttons/Highlights)
  static const Color bgColor = Color(0xFFF5F7FA); // Light Grey (Background)
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFEF5350);

  static TextStyle get titleStyle => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static TextStyle get subTitleStyle => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.grey[700],
  );

  static TextStyle get bodyStyle =>
      GoogleFonts.poppins(fontSize: 14, color: Colors.black87);

  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: accentColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
    elevation: 4,
  );
}
