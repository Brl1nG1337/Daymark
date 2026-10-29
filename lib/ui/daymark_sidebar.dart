import 'package:flutter/material.dart';

import 'theme/daymark_theme.dart';

class DaymarkSidebar extends StatelessWidget {
  const DaymarkSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1000;
    return Container(
      width: compact ? 76 : 228,
      color: DaymarkColors.sidebar,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
      child: Column(
        children: [
          SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (!compact) const SizedBox(width: 16),
                const Icon(
                  Icons.tablet_mac_outlined,
                  color: Color(0xff00b6e8),
                  size: 30,
                ),
                if (!compact) ...[
                  const SizedBox(width: 14),
                  const Flexible(
                    child: Text(
                      'Daymark',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          _destination(0, 'Heute', Icons.today_outlined, compact),
          const SizedBox(height: 8),
          _destination(1, 'Klassen', Icons.groups_rounded, compact),
          const SizedBox(height: 8),
          _destination(2, 'Planung', Icons.calendar_month_outlined, compact),
          const Spacer(),
          const Divider(color: Color(0xff30485d), indent: 10, endIndent: 10),
          const SizedBox(height: 10),
          _destination(3, 'Einstellungen', Icons.settings_outlined, compact),
        ],
      ),
    );
  }

  Widget _destination(int index, String label, IconData icon, bool compact) {
    final selected = index == selectedIndex;
    return Tooltip(
      message: compact ? label : '',
      child: Material(
        color: selected ? DaymarkColors.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelected(index),
          child: Semantics(
            selected: selected,
            button: true,
            label: compact ? label : null,
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  if (!compact) const SizedBox(width: 16),
                  Icon(icon, size: 29, color: const Color(0xffd4e9f9)),
                  if (!compact) ...[
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
