import 'package:flutter/material.dart';

import 'theme/daymark_theme.dart';

class DaymarkSidebar extends StatelessWidget {
  const DaymarkSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.currentTime,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final DateTime? currentTime;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1000;
    final salutation = daymarkSalutation(currentTime ?? DateTime.now());
    final greeting = '$salutation, Madame Röling';
    return Container(
      width: compact ? 76 : 260,
      color: DaymarkColors.sidebar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
        child: Column(
          children: [
            SizedBox(
              key: const ValueKey('sidebar-greeting'),
              height: 68,
              child: Tooltip(
                message: greeting,
                child: Semantics(
                  label: greeting,
                  child: compact
                      ? Center(
                          child: Icon(
                            Icons.waving_hand_outlined,
                            color: DaymarkColors.sidebarIcon,
                            size: 34,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: DaymarkColors.onSidebar.withValues(
                                    alpha: .1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.waving_hand_outlined,
                                  color: DaymarkColors.sidebarIcon,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$salutation,',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: DaymarkColors.sidebarIcon,
                                        fontSize: 16,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Madame Röling',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: DaymarkColors.onSidebar,
                                        fontSize: 19,
                                        height: 1.15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 13),
            Divider(
              key: const ValueKey('sidebar-greeting-divider'),
              height: 1,
              thickness: 1,
              indent: 4,
              endIndent: 4,
              color: DaymarkColors.sidebarIcon.withValues(alpha: .24),
            ),
            const SizedBox(height: 24),
            _destination(0, 'Unterricht', Icons.today_outlined, compact),
            const SizedBox(height: 8),
            _destination(1, 'Klassen', Icons.groups_rounded, compact),
            const SizedBox(height: 8),
            _destination(
              2,
              'Stundenplan',
              Icons.calendar_month_outlined,
              compact,
            ),
            const Spacer(),
            Divider(
              color: DaymarkColors.sidebarIcon.withValues(alpha: .28),
              indent: 10,
              endIndent: 10,
            ),
            const SizedBox(height: 10),
            _destination(3, 'Einstellungen', Icons.settings_outlined, compact),
          ],
        ),
      ),
    );
  }

  Widget _destination(int index, String label, IconData icon, bool compact) {
    return _SidebarDestination(
      label: label,
      icon: icon,
      compact: compact,
      selected: index == selectedIndex,
      onTap: () => onSelected(index),
    );
  }
}

class _SidebarDestination extends StatefulWidget {
  const _SidebarDestination({
    required this.label,
    required this.icon,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarDestination> createState() => _SidebarDestinationState();
}

class _SidebarDestinationState extends State<_SidebarDestination> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final useDarkHoverText =
        _hovered && Theme.of(context).brightness == Brightness.light;
    return Tooltip(
      message: widget.compact ? widget.label : '',
      child: Material(
        color: widget.selected
            ? DaymarkColors.sidebarSelected
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onHover: (hovered) => setState(() => _hovered = hovered),
          onTap: widget.onTap,
          child: Semantics(
            selected: widget.selected,
            button: true,
            label: widget.compact ? widget.label : null,
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: widget.compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  if (!widget.compact) const SizedBox(width: 16),
                  Icon(
                    widget.icon,
                    size: 29,
                    color: useDarkHoverText
                        ? DaymarkColors.ink
                        : DaymarkColors.sidebarIcon,
                  ),
                  if (!widget.compact) ...[
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: useDarkHoverText
                              ? DaymarkColors.ink
                              : DaymarkColors.onSidebar,
                          fontSize: 18,
                          fontWeight: widget.selected
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

String daymarkSalutation(DateTime time) => switch (time.hour) {
  >= 5 && < 11 => 'Guten Morgen',
  >= 11 && < 18 => 'Guten Tag',
  _ => 'Guten Abend',
};
