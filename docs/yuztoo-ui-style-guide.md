# Yuztoo UI Style Guide — Agent Prompt

> Paste this document (or the relevant section) into any Cursor session before implementing a new page.
> It captures the exact design language established across all polished screens in this codebase.

---

## 1. Non-Negotiable Rules (Read Before Every Screen)

1. Every screen uses **`AnnotatedRegion<SystemUiOverlayStyle>`** wrapping `Scaffold` — no exceptions.  
   Status bar color must match the topmost area; nav bar color must match the bottommost area.
2. Every screen with a visual back arrow must also add **`PopScope(canPop: false, onPopInvokedWithResult: ...)`** to handle the device back gesture/hardware button.
3. **Never** call `SystemChrome.setSystemUIOverlayStyle()` in `build()` — always use `AnnotatedRegion`.
4. All text uses **`GoogleFonts.outfit(...)`** — no raw `TextStyle(fontFamily: ...)` or `TextStyle()` alone.
5. Back button icon is always `Icons.arrow_back_ios_new_rounded` (NOT `arrow_back_ios`, NOT `arrow_back`) inside a `GestureDetector(behavior: HitTestBehavior.opaque)`, never `IconButton`.
6. Primary CTA buttons are **never** `ElevatedButton` or `FilledButton`. Use a gradient `Container` + `Material` + `InkWell` (or `GestureDetector`) — see Section 5.
7. Respect **`MediaQuery.of(context).padding.bottom`** for bottom-anchored content (CTAs, footer rows).
8. Follow DDD: no Firestore calls in presentation; all state through Riverpod providers.

---

## 2. Color Palette

### Dark/Auth/Merchant Screens (Navy Dark Theme)

| Token | Hex | Usage |
|---|---|---|
| `bgMain` | `#0E2A44` | Scaffold background, status bar, all dark screens |
| `bgHeader` | `#0B1F33` | Header areas, bottom nav, darker accents |
| `bgDark2` | `#0B1F33` | Card backgrounds, progress bar track, secondary surfaces |
| `primaryGold` | `#D4A017` | Primary CTA gradient start, active icons, gold accents |
| `goldLight` | `#D4AF37` | CTA gradient end, shimmer |
| `textLight` | `#F5F5F5` | Primary text on dark backgrounds |
| `textGrey` | `#B0B0B0` | Secondary/subtitle text on dark |
| `borderColor` | `rgba(255,255,255, 0.10)` | Subtle card borders on dark |
| `goldBorder` | `rgba(212,160,23, 0.25)` | Stronger accent borders |

```dart
// Reference class: MerchantOnboardingColors (or MerchantColors)
static const Color bgDark1    = Color(0xFF0E2A44);
static const Color bgDark2    = Color(0xFF0B1F33);
static const Color primaryGold = Color(0xFFD4A017);
static const Color goldLight   = Color(0xFFD4AF37);
static const Color textLight   = Color(0xFFF5F5F5);
static const Color textGrey    = Color(0xFFB0B0B0);
static const Color borderColor = Color(0x1AFFFFFF); // 10% white
```

### Light/Client/Storefront Screens

| Token | Hex | Usage |
|---|---|---|
| `cream` | `#FDFBF7` | Storefront background |
| `white` | `#FFFFFF` | Client screens background |
| `textPrimary` | `#1E293B` | Dark text on light bg |
| `textSecondary` | `#64748B` | Subtitles on light bg |
| `gold` | `#D4A017` | Accent/CTA on light screens |
| `navyDark` | `#0B162C` | Bottom nav background |

---

## 3. Typography — GoogleFonts.outfit ONLY

All text in the app uses **Outfit**. Never use the default `TextStyle()` without `GoogleFonts.outfit()`.

```dart
import 'package:google_fonts/google_fonts.dart';
```

### Dark Screen Text Scale

| Role | Size | Weight | Color | Notes |
|---|---|---|---|---|
| Page title (gradient) | 24–26px | w700 | via `ShaderMask` | Hero/section titles |
| Page title (plain) | 22px | w700 | textLight `#F5F5F5` | Step headers |
| Section subtitle | 13px | w400 | textGrey `#B0B0B0` | Below title |
| Card/item title | 14–15px | w600 | textLight | List items |
| Card/item body | 12–13px | w400 | textGrey | Descriptions |
| CTA button label | 16px | w700 | bgDark1 `#0E2A44` | On gold gradient |
| Link/action text | 13–14px | w500 | primaryGold | Underlined optional |
| Footer/legal | 11–12px | w400 | textGrey 70% | Bottom labels |

### Gradient Title Pattern (ShaderMask)

```dart
ShaderMask(
  shaderCallback: (bounds) => const LinearGradient(
    colors: [Color(0xFFF5F5F5), Color(0xFFD4A017)],
    stops: [0.5, 1.0],
  ).createShader(bounds),
  child: Text(
    'Titre de la page',
    style: GoogleFonts.outfit(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: -0.3,
    ),
  ),
),
```

---

## 4. Screen Scaffold Template (Dark Navy Theme)

```dart
@override
Widget build(BuildContext context) {
  final bottomPad = MediaQuery.of(context).padding.bottom;

  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0E2A44),         // match bgDark1
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,      // iOS
      systemNavigationBarColor: Color(0xFF0E2A44),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF0E2A44),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.onBack?.call();
        },
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(),   // back button + title or progress
              // ... scrollable content
              Expanded(child: _buildContent()),
              // Bottom CTA (if any)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 0, 20, (bottomPad > 0 ? bottomPad : 16) + 8),
                child: _buildPrimaryCta(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

### Screen Scaffold Template (Light/White Theme)

```dart
return AnnotatedRegion<SystemUiOverlayStyle>(
  value: const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ),
  child: Scaffold(
    backgroundColor: Colors.white,
    body: PopScope( ... ),
  ),
);
```

---

## 5. Primary CTA Button (Gold Gradient)

**Never use `ElevatedButton` or `FilledButton` for the main action.**

```dart
GestureDetector(
  onTap: _isEnabled ? _handleAction : null,
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    height: 54,
    decoration: BoxDecoration(
      gradient: _isEnabled
          ? const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFD4A017)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: _isEnabled ? null : const Color(0xFFD4A017).withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(14),
      boxShadow: _isEnabled
          ? [
              BoxShadow(
                color: const Color(0xFFD4A017).withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    ),
    child: Center(
      child: Text(
        'Continuer',
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _isEnabled
              ? const Color(0xFF0E2A44)
              : const Color(0xFFB0B0B0).withValues(alpha: 0.5),
          letterSpacing: 0.2,
        ),
      ),
    ),
  ),
),
```

### Secondary/Outlined Button

```dart
Container(
  height: 50,
  decoration: BoxDecoration(
    border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.6)),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Center(
    child: Text(
      'Action secondaire',
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFD4A017),
      ),
    ),
  ),
),
```

---

## 6. Back Button + Progress Bar Row

```dart
Widget _buildProgressBar(int current, int total) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: widget.onBack,
              behavior: HitTestBehavior.opaque,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFD4A017),   // gold on dark | Color(0xFF1E293B) on light
                size: 20,
              ),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: current / total,
              backgroundColor: const Color(0xFF0B1F33),   // bgDark2
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4A017)),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 44), // balance the left back button
      ],
    ),
  );
}
```

### Simple Top Bar (Back arrow + title inline)

```dart
Widget _buildTopBar() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
    child: Row(
      children: [
        GestureDetector(
          onTap: widget.onBack,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFD4A017),
              size: 20,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Titre',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF5F5F5),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 44), // balance
      ],
    ),
  );
}
```

---

## 7. Page Header Block (Left-Aligned)

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Option A: plain title
      Text(
        'Votre activité',
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF5F5F5),
          height: 1.25,
          letterSpacing: -0.3,
        ),
      ),
      // Option B: gradient title — use ShaderMask (see Section 3)
      const SizedBox(height: 4),
      Text(
        'Précisez votre spécialité',
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFB0B0B0),
          height: 1.4,
        ),
      ),
    ],
  ),
),
```

---

## 8. Input Fields

### Dark Screen

```dart
OutlineInputBorder _border(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: color),
);

TextFormField(
  style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFFF5F5F5)),
  decoration: InputDecoration(
    labelText: 'Email',
    labelStyle: GoogleFonts.outfit(
      fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFFB0B0B0)),
    hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF606070)),
    filled: true,
    fillColor: const Color(0xFF0B1F33),          // bgDark2
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
    enabledBorder: _border(const Color(0x1AFFFFFF)),
    focusedBorder: _border(const Color(0xFFD4A017)),
    errorBorder: _border(Colors.redAccent),
    focusedErrorBorder: _border(Colors.redAccent),
    prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFFB0B0B0), size: 20),
  ),
),
```

---

## 9. Cards

### Dark Feature Card

```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFF0B1F33),               // bgDark2
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0x1AFFFFFF)),  // 10% white
  ),
  child: Row(
    children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFD4A017).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.star_rounded, color: Color(0xFFD4A017), size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Titre', style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFF5F5F5))),
            const SizedBox(height: 2),
            Text('Description', style: GoogleFonts.outfit(
              fontSize: 12, color: const Color(0xFFB0B0B0))),
          ],
        ),
      ),
    ],
  ),
),
```

### Selectable Grid Card (with check state)

```dart
GestureDetector(
  onTap: () => onTap(),
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    decoration: BoxDecoration(
      color: isSelected
          ? const Color(0xFFD4A017).withValues(alpha: 0.15)
          : const Color(0xFF0B1F33),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isSelected
            ? const Color(0xFFD4A017)
            : const Color(0x1AFFFFFF),
        width: isSelected ? 1.5 : 1,
      ),
    ),
    child: Stack(
      children: [
        // content
        if (isSelected)
          Positioned(
            top: 8, right: 8,
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFD4A017),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
            ),
          ),
      ],
    ),
  ),
),
```

---

## 10. Social/Link Footer Row

```dart
Text.rich(
  TextSpan(
    text: 'Vous avez déjà un compte ? ',
    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFB0B0B0)),
    children: [
      TextSpan(
        text: 'Se connecter',
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFD4A017),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFFD4A017),
        ),
        recognizer: TapGestureRecognizer()..onTap = onLoginTap,
      ),
    ],
  ),
),
```

---

## 11. "OU" Gradient Divider

```dart
Row(
  children: [
    Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, const Color(0xFFB0B0B0).withValues(alpha: 0.4)],
          ),
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        'ou continuer avec',
        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF808080)),
      ),
    ),
    Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFB0B0B0).withValues(alpha: 0.4), Colors.transparent],
          ),
        ),
      ),
    ),
  ],
),
```

---

## 12. Social Login Row (3 icon circles)

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    _SocialIconButton(icon: FontAwesomeIcons.google, onTap: () {}),
    const SizedBox(width: 16),
    _SocialIconButton(icon: FontAwesomeIcons.apple, onTap: () {}),
    const SizedBox(width: 16),
    _SocialIconButton(icon: FontAwesomeIcons.facebookF, onTap: () {}),
  ],
),

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1F33),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Center(
          child: FaIcon(icon, color: const Color(0xFFF5F5F5), size: 20),
        ),
      ),
    );
  }
}
```

---

## 13. Spacing Cheat Sheet (8pt Grid)

| Use | Value |
|---|---|
| Screen horizontal padding | `24px` |
| Screen horizontal padding (tight) | `20px` |
| Between title and subtitle | `4px` |
| Between sections | `16–24px` |
| Between cards in a list | `10–12px` |
| Card internal padding | `16px` |
| CTA button height | `54px` |
| Top bar / progress bar height area | `44px` (touch target) |
| Icon container (small) | `40×40px` |
| Icon container (medium) | `44×44px` |
| Bottom safe area buffer | `(bottomPad > 0 ? bottomPad : 16) + 8` |
| Top content start (after progress bar) | `fromLTRB(24, 8, 24, 16)` |

---

## 14. Animations

| Situation | Widget | Duration |
|---|---|---|
| CTA enable/disable | `AnimatedContainer` | `200ms` |
| Page entry (fade-in) | `FadeTransition` + `AnimationController` | `350–500ms` |
| Card selection | `AnimatedContainer` | `180ms` |

```dart
// Typical page entry animation setup
late AnimationController _animationController;

@override
void initState() {
  super.initState();
  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();
}

@override
void dispose() {
  _animationController.dispose();
  super.dispose();
}

// Usage:
FadeTransition(
  opacity: _animationController,
  child: /* your content */,
),
```

---

## 15. File Structure Pattern (part / part of)

For any screen > ~200 lines of UI:

```
lib/feature/<name>/presentation/
  <name>_screen.dart        ← StatefulWidget, imports, build() calls _buildXxxScaffold()
  <name>_screen.part.dart   ← part of '...dart'; extension _XxxScreenUi on _XxxScreenState { ... }
```

The `.dart` file only has the class skeleton + routing params + state variables.  
All widget-building methods live in the `.part.dart` extension.

---

## 16. Quick Copy — New Dark Screen Boilerplate

```dart
// my_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

part 'my_screen.part.dart';

class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key, required this.onBack, this.onNext});
  final VoidCallback onBack;
  final VoidCallback? onNext;

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildScaffold(context);
}
```

```dart
// my_screen.part.dart
part of 'my_screen.dart';

extension _MyScreenUi on _MyScreenState {
  Widget _buildScaffold(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0E2A44),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0E2A44),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0E2A44),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) widget.onBack();
          },
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildProgressBar(1, 3), // or _buildTopBar()
                _buildHeader(),
                Expanded(child: _buildContent()),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 0, 20, (bottomPad > 0 ? bottomPad : 16) + 8),
                  child: _buildCta(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ... _buildProgressBar, _buildHeader, _buildContent, _buildCta
}
```

---

*Last updated: April 2026 — ui-perfection branch*
