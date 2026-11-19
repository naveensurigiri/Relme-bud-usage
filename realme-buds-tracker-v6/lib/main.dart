import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'controller.dart';
import 'protocol.dart';
import 'rfcomm.dart';

const appName = 'Realme Buds Tracker';
const userName = 'Naveen';
const deviceModel = 'Realme Air Buds 7';
const muted = Color(0xFF6B6B66);
const accent = Color(0xFF534AB7);

final controller = BudsController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await controller.init();
  runApp(const BudsApp());
}

class BudsApp extends StatelessWidget {
  const BudsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: accent)),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/logo.svg',
                      width: 44, height: 44, semanticsLabel: '$appName logo'),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi $userName, welcome back',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                        Text('$appName · $deviceModel',
                            style: TextStyle(fontSize: 13, color: muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Dashboard')),
                  ButtonSegment(value: 1, label: Text('Buds')),
                  ButtonSegment(value: 2, label: Text('Analytics')),
                ],
                selected: {_index},
                onSelectionChanged: (s) => setState(() => _index = s.first),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: const [DashboardPage(), BudsPage(), AnalyticsPage()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helpers

class Tick extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  const Tick({super.key, required this.builder});

  @override
  State<Tick> createState() => _TickState();
}

class _TickState extends State<Tick> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

String fmtHms(int seconds) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(seconds ~/ 3600)}:${two((seconds % 3600) ~/ 60)}:${two(seconds % 60)}';
}

String fmtShort(int seconds) => '${seconds ~/ 3600}h ${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}m';

String pctText(int? v) => v == null ? '--' : '$v%';

(Color, Color) modeColors(int? code) {
  switch (code) {
    case modeAnc:
      return (const Color(0xFFEEEDFE), const Color(0xFF3C3489));
    case modeTransparency:
      return (const Color(0xFFE1F5EE), const Color(0xFF085041));
    case modeNormal:
      return (const Color(0xFFFAECE7), const Color(0xFF712B13));
    default:
      return (const Color(0xFFEEEEEE), const Color(0xFF444441));
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<(String, String)> rows;

  const InfoCard({super.key, required this.title, required this.titleColor, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            for (final (name, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(name, style: const TextStyle(color: muted)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(value, textAlign: TextAlign.right)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String title;
  final String value;
  final Color background;
  final Color foreground;

  const StatTile({
    super.key,
    required this.title,
    required this.value,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: foreground)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: foreground)),
        ],
      ),
    );
  }
}

// Dashboard

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Tick(builder: (context) {
        final c = controller;
        final b = c.battery;
        final (modeBg, modeFg) = modeColors(c.modeCode);
        final connected = c.state == LinkState.connected;
        final busy = c.state == LinkState.connecting;
        return ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Text('Connected time',
                      style: TextStyle(fontSize: 13, color: Color(0xFFEEEDFE))),
                  Text(fmtHms(c.connectedSeconds),
                      style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFEEEDFE),
                          fontFeatures: [FontFeature.tabularFigures()])),
                  Text(c.state == LinkState.connected
                      ? 'Connected'
                      : c.state == LinkState.connecting
                          ? 'Connecting…'
                          : c.state == LinkState.retrying
                              ? 'Retrying…'
                              : c.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFEEEDFE))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: StatTile(
                        title: 'Left bud',
                        value: pctText(b.left),
                        background: const Color(0xFFE1F5EE),
                        foreground: const Color(0xFF04342C))),
                const SizedBox(width: 8),
                Expanded(
                    child: StatTile(
                        title: 'Right bud',
                        value: pctText(b.right),
                        background: const Color(0xFFE1F5EE),
                        foreground: const Color(0xFF04342C))),
                const SizedBox(width: 8),
                Expanded(
                    child: StatTile(
                        title: 'Case',
                        value: pctText(b.caseLevel),
                        background: const Color(0xFFFAECE7),
                        foreground: const Color(0xFF4A1B0C))),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Text('Noise mode', style: TextStyle(color: muted)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: modeBg, borderRadius: BorderRadius.circular(12)),
                      child: Text(modeName(c.modeCode), style: TextStyle(color: modeFg)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            InfoCard(title: 'Status', titleColor: const Color(0xFF3C3489), rows: [
              ('Device', c.deviceLabel),
              ('Permission', c.permissionLabel),
              ('Wearing', 'Not available yet'),
            ]),
            const SizedBox(height: 12),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Choose your buds (pair them in phone Bluetooth first)'),
              value: c.bonded.any((d) => d.address == c.address) ? c.address : null,
              items: [
                for (final BondedDevice d in c.bonded)
                  DropdownMenuItem(
                    value: d.address,
                    child: Text('${d.name.isEmpty ? "Unnamed" : d.name} · ${d.address}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (c.permission == PermState.denied || connected || busy)
                  ? null
                  : c.selectDevice,
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: c.address == null || busy || c.permission == PermState.denied
                        ? null
                        : (connected ? c.disconnect : c.connect),
                    child: Text(connected ? 'Disconnect' : (busy ? 'Connecting…' : 'Connect')),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: c.loadBonded, child: const Text('Refresh list')),
              ],
            ),
          ],
        );
      }),
    );
  }
}

// Buds

class BudsPage extends StatelessWidget {
  const BudsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => InfoCard(
            title: 'This device',
            titleColor: const Color(0xFF0F6E56),
            rows: [
              ('Name', controller.deviceLabel),
              ('Address', controller.address ?? '--'),
              ('Link', controller.state == LinkState.connected
                  ? 'Connected'
                  : controller.state == LinkState.connecting
                      ? 'Connecting…'
                      : controller.state == LinkState.retrying
                          ? 'Retrying…'
                          : controller.message),
              ('Permission', controller.permissionLabel),
              ('Firmware, serial', 'Not read yet'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const InfoCard(
          title: 'Specs (from reviews, not read from your buds)',
          titleColor: Color(0xFF534AB7),
          rows: [
            ('Bluetooth', '5.4'),
            ('Codecs', 'AAC, SBC, LHDC 5.0'),
            ('Driver', '12.4 mm dynamic'),
            ('ANC', 'Up to 52 dB'),
            ('Bud battery', '62 mAh each'),
            ('Case battery', '480 mAh'),
            ('Water and dust', 'IP55'),
          ],
        ),
        const SizedBox(height: 12),
        const Text('My notes', style: TextStyle(color: muted)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: controller.notes,
          maxLines: 3,
          onChanged: controller.setNotes,
          decoration: const InputDecoration(
            hintText: 'Add a note about these buds',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

// Analytics

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Tick(builder: (context) {
        final c = controller;
        String line(int mode) => '${c.stats[mode]!.count} times · ${fmtShort(c.secondsIn(mode))}';
        final modes = [modeAnc, modeTransparency, modeNormal];
        final total = modes.fold<int>(0, (a, m) => a + c.secondsIn(m));
        const barColors = {
          modeAnc: Color(0xFF7F77DD),
          modeTransparency: Color(0xFF1D9E75),
          modeNormal: Color(0xFFD85A30),
        };
        StatTile tile(String title, int mode, Color fg) => StatTile(
              title: title,
              value: line(mode),
              background: modeColors(mode).$1,
              foreground: fg,
            );
        return ListView(
          children: [
            Row(children: [
              Expanded(child: tile('ANC turned on', modeAnc, const Color(0xFF26215C))),
              const SizedBox(width: 8),
              Expanded(child: tile('Transparency on', modeTransparency, const Color(0xFF04342C))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: tile('Normal (ANC off)', modeNormal, const Color(0xFF4A1B0C))),
              const Spacer(),
            ]),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Time in each mode',
                        style: TextStyle(color: accent, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    if (total == 0)
                      const Text('No data yet', style: TextStyle(color: muted))
                    else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 14,
                          child: Row(
                            children: [
                              for (final m in modes)
                                if (c.secondsIn(m) > 0)
                                  Expanded(
                                      flex: c.secondsIn(m),
                                      child: Container(color: barColors[m])),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final m in modes) ...[
                            Text(modeName(m), style: TextStyle(color: barColors[m])),
                            const SizedBox(width: 12),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Counts and time only cover periods when this app was connected to your buds. '
              'The first mode seen after connecting is not counted as a switch.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        );
      }),
    );
  }
}
