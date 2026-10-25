import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../l10n/app_localizations.dart';

class LanguageController extends GetxController {
  static const String _storageKey = 'selected_language';
  final GetStorage _storage = GetStorage();

  final Rx<Locale> currentLocale = const Locale('en').obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    final String? savedLang = _storage.read<String>(_storageKey);
    if (savedLang != null && (savedLang == 'hi' || savedLang == 'en')) {
      currentLocale.value = Locale(savedLang);
    } else {
      currentLocale.value = const Locale('en');
    }
  }

  static LanguageController get to => Get.find<LanguageController>();

  static String get currentLang {
    try {
      if (Get.isRegistered<LanguageController>()) {
        return Get.find<LanguageController>().currentLocale.value.languageCode;
      }
    } catch (_) {}
    return 'en';
  }

  bool get isHindi => currentLocale.value.languageCode == 'hi';

  void changeLanguage(String langCode) {
    if (langCode != 'en' && langCode != 'hi') return;
    
    currentLocale.value = Locale(langCode);
    Get.updateLocale(Locale(langCode));
    _storage.write(_storageKey, langCode);

    Get.snackbar(
      langCode == 'hi' ? 'भाषा बदली गई' : 'Language Changed',
      langCode == 'hi'
          ? 'ऐप की भाषा अब हिंदी कर दी गई है।'
          : 'App language is now set to English.',
      backgroundColor: Colors.white,
      colorText: const Color(0xFF1B5E20),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
    );
  }

  /// Opens a modern, interactive language picker bottom sheet
  static void showLanguageBottomSheet(BuildContext context) {
    final langController = Get.find<LanguageController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Obx(() {
            final activeLang = langController.currentLocale.value.languageCode;
            final isHi = activeLang == 'hi';

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.translate_rounded, color: Color(0xFF2E7D32), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHi ? 'ऐप की भाषा चुनें' : 'Select App Language',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Text(
                          isHi ? 'अपनी पसंदीदा भाषा का चयन करें' : 'Choose your preferred language',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── English Option ──
                _buildLanguageTile(
                  context: ctx,
                  code: 'en',
                  name: 'English',
                  nativeName: 'English 🇬🇧',
                  subtitle: 'Default language',
                  isSelected: activeLang == 'en',
                  onTap: () {
                    langController.changeLanguage('en');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),

                // ── Hindi Option ──
                _buildLanguageTile(
                  context: ctx,
                  code: 'hi',
                  name: 'Hindi',
                  nativeName: 'हिंदी 🇮🇳',
                  subtitle: 'किसानों के लिए सहज व सरल',
                  isSelected: activeLang == 'hi',
                  onTap: () {
                    langController.changeLanguage('hi');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            );
          }),
        );
      },
    );
  }

  static Widget _buildLanguageTile({
    required BuildContext context,
    required String code,
    required String name,
    required String nativeName,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF9FBF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  code == 'hi' ? 'अ' : 'A',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 24)
            else
              Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }
}

extension AppLocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
