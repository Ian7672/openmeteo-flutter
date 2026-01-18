import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('settings')),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader(lang.translate('theme')),
          _buildThemeToggle(context, themeProvider, lang),
          SizedBox(height: 24),

          _buildSectionHeader(lang.translate('language')),
          _buildLanguageTile(context, lang, 'English', 'en'),
          _buildLanguageTile(context, lang, 'Indonesia', 'id'),
          _buildLanguageTile(context, lang, '中文 (Chinese)', 'zh'),
          _buildLanguageTile(context, lang, '日本語 (Japanese)', 'ja'),
          _buildLanguageTile(context, lang, '한국어 (Korean)', 'ko'),
          _buildLanguageTile(context, lang, 'العربية (Arabic)', 'ar'),
          _buildLanguageTile(context, lang, 'Русский (Russian)', 'ru'),
          _buildLanguageTile(context, lang, 'हिन्दी (Hindi)', 'hi'),

          Divider(height: 32),

          _buildSectionHeader(lang.translate('donation')),
          _buildLinkTile(
            context,
            'Trakteer',
            'https://trakteer.id/Ian7672',
            Icons.favorite_rounded,
            Colors.redAccent,
          ),
          _buildLinkTile(
            context,
            'Ko-fi',
            'https://ko-fi.com/Ian7672',
            Icons.coffee_rounded,
            Color(0xFF29ABE2),
          ),

          Divider(height: 32),

          _buildSectionHeader(lang.translate('credits')),
          _buildLinkTile(
            context,
            'GitHub: Ian7672',
            'https://github.com/Ian7672',
            Icons.code_rounded,
            Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    ThemeProvider themeProvider,
    LanguageProvider lang,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: Color(0xFF667EEA),
        ),
        title: Text(
          lang.translate('dark_mode'),
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Switch(
          value: themeProvider.isDarkMode,
          onChanged: (value) => themeProvider.toggleTheme(value),
          activeColor: Color(0xFF667EEA),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    LanguageProvider lang,
    String name,
    String code,
  ) {
    final isSelected = lang.currentLocale.languageCode == code;
    return ListTile(
      title: Text(name),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Color(0xFF667EEA))
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        lang.setLanguage(code);
      },
    );
  }

  Widget _buildLinkTile(
    BuildContext context,
    String name,
    String url,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(name),
      trailing: Icon(Icons.open_in_new_rounded, size: 16, color: Colors.grey),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
    );
  }
}
