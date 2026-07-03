import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mizan_web/core/l10n/app_localizations.dart';
import 'package:mizan_web/core/widgets/rotating_logo.dart';
import '../../providers/locale_provider.dart';
import '../../core/l10n/l10n.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  const Navbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 200,
      leading: InkWell(
        onTap: () => context.go('/'),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Row(
          children: [
            const SizedBox(width: 12),
            RotatingLogo(size: isMobile ? 36.0 : 42.0),
            const SizedBox(width: 8),
            Text(
              "HOME",
              style: TextStyle(
                color: const Color(0xFF1B5E20),
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Multi-language Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              value: localeProvider.locale,
              icon: const Icon(
                Icons.language,
                color: Color(0xFF1B5E20),
                size: 20,
              ),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) localeProvider.setLocale(newLocale);
              },
              items: L10n.all
                  .map(
                    (locale) => DropdownMenuItem(
                      value: locale,
                      child: Text(
                        locale.languageCode.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        // Menu Toggle (Now handles the cleaned-up Drawer)
        IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: Color(0xFF1B5E20),
            size: 28,
          ),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
