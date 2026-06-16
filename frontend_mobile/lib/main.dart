import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Your designated machine network target configurations
const String backendUrl = "http://100.81.95.123:8080/api";

class AppStrings {
  static const Map<String, String> en = {
    'app_title': 'Freezer Penguin',
    'welcome_msg': 'Stay frosty!',
    'sub_welcome': 'Here is the current state of your icebox.',
    'tab_home': 'Home',
    'tab_inventory': 'The Ice Floe',
    'tab_intake': 'Intake Portal',
    'tab_tips': 'Penguin Tips',
    'capacity_title': 'Icebox Capacity',
    'status_optimal': 'Optimal',
    'status_full': 'Full',
    'lbl_expiring': 'EXPIRING',
    'lbl_total': 'TOTAL',
    'inv_sub': 'Your frozen assets.',
    'btn_filter': 'Filter',
    'intake_sub': 'Log new provisions for the frozen expanse.',
    'toggle_barcode': 'Barcode',
    'toggle_manual': 'Manual',
    'toggle_vision': 'Vision',
    'form_name': 'Item Name',
    'hint_name': 'e.g., Krill Patties, Frozen Peas',
    'form_qty': 'Quantity',
    'form_zone': 'Storage Zone',
    'hint_zone': 'Deep Freeze (Bottom)',
    'btn_add': 'Add to Freezer',
    'tips_spotlight': 'WEEKLY SPOTLIGHT',
    'tips_title_1': 'Master the Deep Freeze',
    'tips_body_1': 'Discover eco-friendly ways to preserve your fresh produce and reduce food waste with our ultimate penguin-approved kitchen strategies!',
    'tips_title_2': 'Blanching 101',
    'tips_body_2': 'A quick boil followed by an ice bath stops enzymes, locking in bright colors and flavor.',
  };

  static const Map<String, String> zhCantonese = {
    'app_title': '雪櫃企鵝',
    'welcome_msg': '保持冰爽！',
    'sub_welcome': '依家check吓你個雪櫃嘅狀態：',
    'tab_home': '首頁',
    'tab_inventory': '冰層庫存',
    'tab_intake': '入庫門戶',
    'tab_tips': '企鵝貼士',
    'capacity_title': '雪櫃容量',
    'status_optimal': '最佳狀態',
    'status_full': '已滿',
    'lbl_expiring': '即將過期',
    'lbl_total': '總數',
    'inv_sub': '你嘅冷凍資產。',
    'btn_filter': '篩選',
    'intake_sub': '記錄放入雪櫃嘅新物資。',
    'toggle_barcode': '條碼掃描',
    'toggle_manual': '手動輸入',
    'toggle_vision': '影像識別',
    'form_name': '項目名稱',
    'hint_name': '例如：磷蝦肉餅、急凍青豆',
    'form_qty': '數量',
    'form_zone': '儲存區域',
    'hint_zone': '深層冷凍區 (底部)',
    'btn_add': '放入雪櫃',
    'tips_spotlight': '每週焦點',
    'tips_title_1': '精通深層冷凍',
    'tips_body_1': '探索環保嘅方法去保存你哋嘅新鮮食材，利用我哋企鵝認證嘅廚房策略減少嘢食浪費！',
    'tips_title_2': '殺青技術 101',
    'tips_body_2': '快速白灼然後放入冰水可以停止酵素作用，鎖住鮮艷嘅顏色同原味。',
  };
}

void main() {
  runApp(const FreezerPenguinApp());
}

class FreezerPenguinApp extends StatefulWidget {
  const FreezerPenguinApp({super.key});

  @override
  State<FreezerPenguinApp> createState() => _FreezerPenguinAppState();
}

class _FreezerPenguinAppState extends State<FreezerPenguinApp> {
  bool _isAntarcticMode = true; // Tracks theme mode state

  @override
  Widget build(BuildContext context) {
    // Dynamic styling layout assignment
    final Color currentBackground = _isAntarcticMode ? AppColors.antarcticBackground : AppColors.crispKitchenBackground;
    final Color currentSurface = _isAntarcticMode ? AppColors.antarcticSurface : AppColors.crispKitchenSurface;

    return MaterialApp(
      title: 'Freezer Penguin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: currentBackground,
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: AppColors.outline,
                displayColor: AppColors.outline,
              ),
        ),
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.orange,
          surface: currentSurface,
          background: currentBackground,
        ),
      ),
      home: MainNavigationScreen(
        isAntarcticMode: _isAntarcticMode,
        onThemeToggle: () => setState(() => _isAntarcticMode = !_isAntarcticMode),
      ),
    );
  }
}

// --- Professional Core Design System Tokens ---
class AppColors {
  // Mode Layer 1: Antarctic Mode (Soft Ice Blue Layouts)
  static const Color antarcticBackground = Color(0xFFD1E6F7);
  static const Color antarcticSurface = Color(0xFFA9D2F0);

  // Mode Layer 2: Crisp Kitchen Mode (High Contrast Clean Studio Layouts)
  static const Color crispKitchenBackground = Color(0xFFF4F9FD);
  static const Color crispKitchenSurface = Color(0xFFE1EFFB);

  // Constants
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF05162E); // 2px Border Navy
  static const Color primary = Color(0xFF00A3FF); // Glacier Blue Accent
  static const Color orange = Color(0xFFF37321);  // Beak Orange Warning Accent
  static const Color textVariant = Color(0xFF2D5B88);
}

// --- Main Navigation Container ---
class MainNavigationScreen extends StatefulWidget {
  final bool isAntarcticMode;
  final VoidCallback onThemeToggle;

  const MainNavigationScreen({
    super.key,
    required this.isAntarcticMode,
    required this.onThemeToggle,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isCantonese = false;

  @override
  Widget build(BuildContext context) {
    // Dynamically assigns the target translation dictionary pack
    final strings = _isCantonese ? AppStrings.zhCantonese : AppStrings.en;

    // Isolate structural screen generation logic to accept the layout token array
    final List<Widget> views = [
      HomeDashboardView(strings: strings),
      IceFloeView(strings: strings),
      IntakePortalView(strings: strings),
      PenguinTipsView(strings: strings),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.outline, width: 2)),
        title: Row(
          children: [
            const Icon(Icons.ac_unit, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              strings['app_title']!,
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
          TextButton(
            child: Text(
              _isCantonese ? "EN" : "廣東話",
              style: GoogleFonts.quicksand(
                color: AppColors.outline,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              setState(() {
                _isCantonese = !_isCantonese;
              });
            },
          ),
          IconButton(
            icon: Icon(
              widget.isAntarcticMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              color: AppColors.outline,
            ),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: views[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textVariant,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: strings['tab_home']),
            BottomNavigationBarItem(icon: const Icon(Icons.ac_unit_outlined), activeIcon: const Icon(Icons.ac_unit), label: strings['tab_inventory']),
            BottomNavigationBarItem(icon: const Icon(Icons.add_box_outlined), activeIcon: const Icon(Icons.add_box), label: strings['tab_intake']),
            BottomNavigationBarItem(icon: const Icon(Icons.lightbulb_outline), activeIcon: const Icon(Icons.lightbulb), label: strings['tab_tips']),
          ],
        ),
      ),
    );
  }
}

// --- Reusable Structural Bento Component ---
class BentoCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const BentoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.outline, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

// --- 1. Home Dashboard Core View ---
class HomeDashboardView extends StatelessWidget {
  final Map<String, String> strings;
  const HomeDashboardView({super.key, required this.strings});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(strings['welcome_msg']!, style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(strings['sub_welcome']!, style: const TextStyle(color: AppColors.textVariant, fontSize: 16)),
        const SizedBox(height: 24),
        
        // Capacity Management Component
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
                      Text(strings['capacity_title']!, style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      border: Border.all(color: AppColors.outline, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(strings['status_optimal']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('78%', style: GoogleFonts.quicksand(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(strings['status_full']!, style: const TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600)),
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
        
        // Dynamic Operational Metrics Row
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
                    Text(strings['lbl_expiring']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                    Text(strings['lbl_total']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

// --- 2. The Ice Floe View ---
class IceFloeView extends StatelessWidget {
  final Map<String, String> strings;
  const IceFloeView({super.key, required this.strings});

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
                Text(strings['tab_inventory']!, style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(strings['inv_sub']!, style: const TextStyle(color: AppColors.textVariant, fontSize: 16)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border.all(color: AppColors.outline, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(strings['btn_filter']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 24),
        _buildInventoryItem(Icons.set_meal, 'Wild Caught Salmon', 'Qty: 2 • Bottom Drawer', strings['lbl_expiring']!, AppColors.orange, Icons.warning),
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

// --- 3. Intake Portal View ---
class IntakePortalView extends StatefulWidget {
  final Map<String, String> strings;
  const IntakePortalView({super.key, required this.strings});

  @override
  State<IntakePortalView> createState() => _IntakePortalViewState();
}

class _IntakePortalViewState extends State<IntakePortalView> {
  int _selectedMode = 1;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.strings['tab_intake']!, style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold)),
        Text(widget.strings['intake_sub']!, style: const TextStyle(color: AppColors.textVariant, fontSize: 16)),
        const SizedBox(height: 24),
        
        // High-Fidelity Custom Segmentation Component
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppColors.outline, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _buildToggleButton(0, widget.strings['toggle_barcode']!, Icons.barcode_reader),
              _buildToggleButton(1, widget.strings['toggle_manual']!, Icons.edit_document),
              _buildToggleButton(2, widget.strings['toggle_vision']!, Icons.visibility),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Native Data Entry Form
        BentoCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.strings['form_name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField(widget.strings['hint_name']!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.strings['form_qty']!, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        Text(widget.strings['form_zone']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildTextField(widget.strings['hint_zone']!),
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
                  label: Text(widget.strings['btn_add']!, style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

// --- 4. Penguin Tips View ---
class PenguinTipsView extends StatelessWidget {
  final Map<String, String> strings;
  const PenguinTipsView({super.key, required this.strings});

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
                child: Text(strings['tips_spotlight']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
              ),
              const SizedBox(height: 16),
              Text(strings['tips_title_1']!, style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                strings['tips_body_1']!,
                style: const TextStyle(fontSize: 16, color: AppColors.textVariant),
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
              Text(strings['tips_title_2']!, style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                strings['tips_body_2']!,
                style: const TextStyle(color: Colors.white),
              )
            ],
          ),
        )
      ],
    );
  }
}