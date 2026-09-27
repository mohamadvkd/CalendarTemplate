import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CalendarStore.init();
  runApp(const CalendarApp());
}

class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.color,
    this.done = false,
  });

  final String id;
  final String title;
  final DateTime date;
  final String time;
  final int color;
  bool done;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'time': time,
        'color': color,
        'done': done,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> j) => CalendarEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        date: DateTime.parse(j['date'] as String),
        time: j['time'] as String? ?? '',
        color: j['color'] as int? ?? 0,
        done: j['done'] as bool? ?? false,
      );
}

class CalendarStore {
  static late SharedPreferences prefs;
  static const key = 'calendar_events';
  static List<CalendarEvent> events = [];

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      events = (jsonDecode(raw) as List)
          .map((e) => CalendarEvent.fromJson(e))
          .toList();
    }
  }

  static Future<void> save() => prefs.setString(
        key,
        jsonEncode(events.map((e) => e.toJson()).toList()),
      );
}

class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  bool dark = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'تقويمي',
        theme: CalendarTheme.light,
        darkTheme: CalendarTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: CalendarHome(onTheme: () => setState(() => dark = !dark)),
      );
}

class CalendarHome extends StatefulWidget {
  const CalendarHome({super.key, required this.onTheme});

  final VoidCallback onTheme;

  @override
  State<CalendarHome> createState() => _CalendarHomeState();
}

class _CalendarHomeState extends State<CalendarHome> {
  DateTime selected = DateTime.now();
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  int view = 0;

  List<CalendarEvent> get dayEvents => CalendarStore.events
      .where((e) =>
          e.date.year == selected.year &&
          e.date.month == selected.month &&
          e.date.day == selected.day)
      .toList()
    ..sort((a, b) => a.time.compareTo(b.time));

  List<CalendarEvent> get upcoming => CalendarStore.events
      .where((e) =>
          !e.done &&
          !e.date.isBefore(DateTime.now().subtract(const Duration(days: 1))))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  void refresh() {
    setState(() {});
    CalendarStore.save();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'تقويمي',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              onPressed: widget.onTheme,
              icon: const Icon(Icons.brightness_6_outlined),
            ),
            IconButton(
              onPressed: () => setState(() => selected = DateTime.now()),
              icon: const Icon(Icons.today_outlined),
            ),
          ],
        ),
        body: IndexedStack(
          index: view,
          children: [_calendar(), _agenda(), _settings()],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addEvent,
          icon: const Icon(Icons.add),
          label: const Text('حدث جديد'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: view,
          onDestinationSelected: (v) => setState(() => view = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'التقويم',
            ),
            NavigationDestination(
              icon: Icon(Icons.view_agenda_outlined),
              label: 'الأجندة',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              label: 'الإعدادات',
            ),
          ],
        ),
      );

  Widget _calendar() {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday % 7;
    final cells = <Widget>[];

    for (var i = 0; i < offset; i++) {
      cells.add(const SizedBox());
    }

    for (var day = 1; day <= days; day++) {
      final date = DateTime(month.year, month.month, day);
      final active = date.year == selected.year &&
          date.month == selected.month &&
          date.day == selected.day;
      final has = CalendarStore.events.any((e) =>
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day);

      cells.add(
        GestureDetector(
          onTap: () => setState(() => selected = date),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: active ? CalendarTheme.indigo : null,
              borderRadius: BorderRadius.circular(14),
              border: date.day == DateTime.now().day &&
                      date.month == DateTime.now().month &&
                      date.year == DateTime.now().year
                  ? Border.all(color: CalendarTheme.coral, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: active ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (has)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : CalendarTheme.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        _monthHeader(),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    'أحد',
                    'اثنين',
                    'ثلاثاء',
                    'أربعاء',
                    'خميس',
                    'جمعة',
                    'سبت',
                  ]
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: cells,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أحداث ${selected.day} ${_monthName(selected.month)}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              '${dayEvents.length} أحداث',
              style: const TextStyle(color: CalendarTheme.indigo),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (dayEvents.isEmpty)
          _empty('لا توجد أحداث لهذا اليوم')
        else
          ...dayEvents.map(_eventTile),
      ],
    );
  }

  Widget _monthHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () =>
                setState(() => month = DateTime(month.year, month.month - 1)),
            icon: const Icon(Icons.chevron_right),
          ),
          Text(
            '${_monthName(month.month)} ${month.year}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          IconButton(
            onPressed: () =>
                setState(() => month = DateTime(month.year, month.month + 1)),
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      );

  String _monthName(int m) => const [
        '',
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ][m];

  Widget _eventTile(CalendarEvent e) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Container(
            width: 8,
            height: 44,
            decoration: BoxDecoration(
              color: [
                CalendarTheme.indigo,
                CalendarTheme.coral,
                Colors.teal,
                Colors.amber,
              ][e.color % 4],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: Text(
            e.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(e.time.isEmpty ? 'طوال اليوم' : e.time),
          trailing: Checkbox(
            value: e.done,
            onChanged: (v) {
              e.done = v ?? false;
              refresh();
            },
          ),
        ),
      );

  Widget _agenda() => ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: [
          Text(
            'الأجندة القادمة',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'خطط لأيامك وأنجز ما يهمك',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (upcoming.isEmpty)
            _empty('لا توجد أحداث قادمة')
          else
            ...upcoming.map(
              (e) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => setState(() {
                    selected = e.date;
                    month = DateTime(e.date.year, e.date.month);
                    view = 0;
                  }),
                  leading: CircleAvatar(
                    backgroundColor:
                        CalendarTheme.indigo.withOpacity(.12),
                    child: Text(
                      '${e.date.day}',
                      style: const TextStyle(
                        color: CalendarTheme.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    e.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${e.date.day} ${_monthName(e.date.month)} ${e.date.year}  ${e.time}',
                  ),
                  trailing: Checkbox(
                    value: e.done,
                    onChanged: (v) {
                      e.done = v ?? false;
                      refresh();
                    },
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );

  Widget _settings() => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'الإعدادات',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('حذف كل الأحداث'),
              onTap: () {
                CalendarStore.events.clear();
                refresh();
              },
            ),
          ),
        ],
      );

  Future<void> _addEvent() async {
    final controller = TextEditingController();
    var date = selected;
    var time = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('إضافة حدث'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'اسم الحدث'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(
                  '${date.day} ${_monthName(date.month)} ${date.year}',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setDialog(() => date = picked);
                  }
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'الوقت اختياري',
                ),
                onChanged: (v) => time = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      CalendarStore.events.add(
        CalendarEvent(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: controller.text.trim(),
          date: date,
          time: time,
          color: CalendarStore.events.length % 4,
        ),
      );
      refresh();
    }
  }
}