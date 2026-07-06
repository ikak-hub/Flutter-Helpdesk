import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistem warna HelpPoint v3 — identitas visual baru:
/// teal gelap institusional dipadu kuning keemasan, menggantikan
/// biru-navy/oranye generik versi sebelumnya.
class AppColors {
  // Warna utama
  static const Color primary = Color(0xFF0F4C4C);
  static const Color primaryLight = Color(0xFF3D7A8C);
  static const Color primaryDark = Color(0xFF0A3535);
  static const Color accent = Color(0xFFE8A33D);
  static const Color accentLight = Color(0xFFF0BD6E);

  // Status tiket — dipilih agar berbeda dari status-color Material baku
  static const Color statusOpen = Color(0xFF3D7A8C); // pending: biru teal
  static const Color statusInProgress = Color(0xFFC9622E); // progress: terracotta
  static const Color statusResolved = Color(0xFF4F7E5C); // selesai: hijau sage
  static const Color statusClosed = Color(0xFF6B6359); // tutup: abu hangat
  static const Color statusPending = Color(0xFF8C6FAE);
  static const Color statusRejected = Color(0xFFB85C5C);

  static const Color roleAdmin = Color(0xFF0F4C4C);
  static const Color roleHelpdesk = Color(0xFF3D7A8C);
  static const Color roleUser = Color(0xFF6B6359);

  // Latar krem hangat — bukan abu-biru generik
  static const Color backgroundLight = Color(0xFFF5F2EA);
  static const Color surfaceLight = Color(0xFFFFFEFB);
  static const Color cardLight = Color(0xFFFFFEFB);
  static const Color textPrimaryLight = Color(0xFF1A2E2E);
  static const Color textSecondaryLight = Color(0xFF6B6359);

  static const Color backgroundDark = Color(0xFF0F1A1A);
  static const Color surfaceDark = Color(0xFF1A2E2E);
  static const Color cardDark = Color(0xFF223B3B);
  static const Color textPrimaryDark = Color(0xFFEDE8DC);
  static const Color textSecondaryDark = Color(0xFF9CA8A3);

  // Garis takik (notch) khas tiket — dipakai di header & kartu signature
  static const Color notchLine = Color(0x33000000);
}

/// Bentuk signature: sudut kanan-atas terpotong miring, seperti sobekan
/// tiket. Dipakai pada kartu-kartu kunci (header dashboard, kartu tiket
/// utama) agar berbeda dari rounded-rect generik di semua sisi.
class TicketNotchBorder extends OutlinedBorder {
  final double radius;
  final double notch;

  const TicketNotchBorder({
    super.side = BorderSide.none,
    this.radius = 18,
    this.notch = 22,
  });

  @override
  TicketNotchBorder copyWith({
    BorderSide? side,
    double? radius,
    double? notch,
  }) {
    return TicketNotchBorder(
      side: side ?? this.side,
      radius: radius ?? this.radius,
      notch: notch ?? this.notch,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) {
    return TicketNotchBorder(
      side: side.scale(t),
      radius: radius * t,
      notch: notch * t,
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();

    path.moveTo(rect.left + radius, rect.top);
    path.lineTo(rect.right - notch, rect.top);
    path.lineTo(rect.right, rect.top + notch);
    path.lineTo(rect.right, rect.bottom - radius);

    path.arcToPoint(
      Offset(rect.right - radius, rect.bottom),
      radius: Radius.circular(radius),
    );

    path.lineTo(rect.left + radius, rect.bottom);

    path.arcToPoint(
      Offset(rect.left, rect.bottom - radius),
      radius: Radius.circular(radius),
    );

    path.lineTo(rect.left, rect.top + radius);

    path.arcToPoint(
      Offset(rect.left + radius, rect.top),
      radius: Radius.circular(radius),
    );

    path.close();
    return path;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect.deflate(side.width));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side == BorderSide.none) return;

    canvas.drawPath(
      getOuterPath(rect),
      side.toPaint(),
    );
  }
}

/// Badge status bergaya "stempel" — sudut kiri dipotong, bukan pill
/// rounded generik, untuk membedakan dari badge Material standar.
class StampBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Widget? leading;
  const StampBadge({super.key, required this.label, required this.color, this.leading});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _StampClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 5, 10, 5),
        color: color.withOpacity(0.12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StampClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const cut = 6.0;
    final path = Path();
    path.moveTo(cut, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(cut, size.height);
    path.lineTo(0, size.height - cut);
    path.lineTo(0, cut);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class AppTheme {
  static TextTheme _textTheme(Color textColor, Color textSecondary) {
    final display = GoogleFonts.spaceGroteskTextTheme();
    final body = GoogleFonts.plusJakartaSansTextTheme();
    return body.copyWith(
      headlineSmall: display.headlineSmall
          ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      titleLarge: display.titleLarge
          ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      titleMedium: display.titleMedium
          ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      titleSmall:
          display.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(color: textColor),
      bodyMedium: body.bodyMedium?.copyWith(color: textColor),
      bodySmall: body.bodySmall?.copyWith(color: textSecondary),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _textTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surfaceLight,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.textSecondaryLight.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.textSecondaryLight.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryLight,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _textTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.accent,
        surface: AppColors.surfaceDark,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.accentLight,
        unselectedItemColor: AppColors.textSecondaryDark,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
