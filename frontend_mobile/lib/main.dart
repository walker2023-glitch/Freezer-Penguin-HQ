import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// TODO: Replace with your specific Dell PowerEdge R330 Tailscale IP and port
const String backendUrl = "http://[YOUR_TAILSCALE_IP]:8080/api";

void main() {
  runApp(const FreezerPenguinApp());
}

class FreezerPenguinApp extends StatelessWidget {
  const FreezerPenguinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freezer Penguin',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: AppColors.outline,
                displayColor: AppColors.outline,
              ),
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.orange,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// --- Colors ---
class AppColors {
  static const Color background = Color(0xFFD1E6F7);
  static const Color surface = Color(0xFFA9D2F0);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF05162E);
  static const Color primary = Color(0xFF00A3FF);
  static const Color orange = Color(0xFFF37321); // Beak Orange
  static const Color textVariant = Color(0xFF2D5B88);
}

// --- Main Navigation ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const HomeDashboardView(),
    const IceFloeView(),
    const IntakePortalView(),
    const PenguinTipsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.outline, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.ac_unit, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'Freezer Penguin',
              style: GoogleFonts.quicksand(
                color: AppColors.outline,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined, color: AppColors.outline),
            onPressed: () {},
          ),
        ],
      ),
      body: _views[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.outline, width: 2),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textVariant,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.ac_unit_outlined), activeIcon: Icon(Icons.ac_unit), label: 'Ice Floe'),
            BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box), label: 'Intake'),
            BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), activeIcon: Icon(Icons.lightbulb), label: 'Tips'),
          ],
        ),
      ),
    );
  }
}

// --- Reusable Bento Card ---
class BentoCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const BentoCard({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.surface,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.outline, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

// --- 1. Home Dashboard ---
class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Stay frosty!', style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Here is the current state of your icebox.', style: TextStyle(color: AppColors.textVariant, fontSize: 16)),
        const SizedBox(height: 24),
        
        // Capacity Bento
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.severe_cold, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Icebox Capacity', style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      border: Border.all(color: AppColors.outline, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Optimal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('78%', style: GoogleFonts.quicksand(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('Full', style: TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  border: Border.all(color: AppColors.outline, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.78,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      border: Border(right: BorderSide(color: AppColors.outline, width: 2)),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Stats Row
        Row(
          children: [
            Expanded(
              child: BentoCard(
                backgroundColor: AppColors.orange,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text('3', style: GoogleFonts.quicksand(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('EXPIRING', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: BentoCard(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text('42', style: GoogleFonts.quicksand(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

// --- 2. The Ice Floe (Inventory) ---
class IceFloeView extends StatelessWidget {
  const IceFloeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The Ice Floe', style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('Your frozen assets.', style: TextStyle(color: AppColors.textVariant, fontSize: 16)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border.all(color: AppColors.outline, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 24),
        _buildInventoryItem(Icons.set_meal, 'Wild Caught Salmon', 'Qty: 2 • Bottom Drawer', 'Expired', AppColors.orange, Icons.warning),
        const SizedBox(height: 16),
        _buildInventoryItem(Icons.icecream, 'Vanilla Bean Ice Cream', 'Qty: 1 • Door Shelf', 'Critical', AppColors.primary, Icons.notifications_active),
      ],
    );
  }

  Widget _buildInventoryItem(IconData icon, String title, String subtitle, String status, Color statusColor, IconData statusIcon) {
    return BentoCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              border: Border.all(color: AppColors.outline, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: AppColors.outline),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              border: Border.all(color: AppColors.outline, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. Intake Portal ---
class IntakePortalView extends StatefulWidget {
  const IntakePortalView({super.key});

  @override
  State<IntakePortalView> createState() => _IntakePortalViewState();
}

class _IntakePortalViewState extends State<IntakePortalView> {
  int _selectedMode = 1; // 0: Barcode, 1: Manual, 2: Vision

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Intake Portal', style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold)),
        const Text('Log new provisions for the frozen expanse.', style: TextStyle(color: AppColors.textVariant, fontSize: 16)),
        const SizedBox(height: 24),
        
        // Segmented Toggle Bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outline, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _buildToggleButton(0, 'Barcode', Icons.barcode_reader),
              _buildToggleButton(1, 'Manual', Icons.edit_document),
              _buildToggleButton(2, 'Vision', Icons.visibility),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Manual Entry Form
        BentoCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField('e.g., Krill Patties, Frozen Peas'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildTextField('1', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Storage Zone', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildTextField('Deep Freeze (Bottom)'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.inventory_2, color: Colors.white),
                  label: Text('Add to Freezer', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.outline, width: 2),
                    ),
                    elevation: 0,
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildToggleButton(int index, String label, IconData icon) {
    bool isSelected = _selectedMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceLowest : Colors.transparent,
            border: isSelected ? Border.all(color: AppColors.outline, width: 2) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.outline : AppColors.textVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.outline : AppColors.textVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {TextAlign textAlign = TextAlign.start}) {
    return TextField(
      textAlign: textAlign,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textVariant),
        filled: true,
        fillColor: AppColors.surfaceLowest,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
    );
  }
}

// --- 4. Penguin Tips ---
class PenguinTipsView extends StatelessWidget {
  const PenguinTipsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BentoCard(
          backgroundColor: AppColors.surfaceLowest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outline, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('WEEKLY SPOTLIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
              ),
              const SizedBox(height: 16),
              Text('Master the Deep Freeze', style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Discover eco-friendly ways to preserve your fresh produce and reduce food waste with our ultimate penguin-approved kitchen strategies!',
                style: TextStyle(fontSize: 16, color: AppColors.textVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BentoCard(
          backgroundColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  border: Border.all(color: AppColors.outline, width: 2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text('Blanching 101', style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text(
                'A quick boil followed by an ice bath stops enzymes, locking in bright colors and flavor.',
                style: TextStyle(color: Colors.white),
              )
            ],
          ),
        )
      ],
    );
  }
}