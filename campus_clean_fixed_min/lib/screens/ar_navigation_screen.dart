import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

import '../db/app_db.dart';

class ARNavigationScreen extends StatefulWidget {
  final String? initialRoom;
  const ARNavigationScreen({super.key, this.initialRoom});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  CameraController? _cam;
  bool _loading = true;
  String? _error;

  bool _demoMode = false;

  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;

  Map<String, double> _targets = {};
  String? _selectedRoom;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _demoMode = false;
    });

    try {
      await _loadTargetsFromDb();

      if (_targets.isEmpty) {
        setState(() {
          _loading = false;
          _error = "No rooms found. Add schedule data in Excel and re-import.";
        });
        return;
      }

      final incoming = widget.initialRoom?.trim();
      _selectedRoom =
          (incoming != null &&
              incoming.isNotEmpty &&
              _targets.containsKey(incoming))
          ? incoming
          : _targets.keys.first;

      // compass (demo modda bile çalışsın)
      _compassSub?.cancel();
      _compassSub = FlutterCompass.events?.listen((e) {
        if (!mounted) return;
        if (e.heading == null) return;
        setState(() => _heading = e.heading);
      });

      // camera permission yoksa demo mode
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        setState(() {
          _loading = false;
          _demoMode = true;
        });
        return;
      }

      // camera init
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _loading = false;
          _demoMode = true;
        });
        return;
      }

      final chosen = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      final controller = CameraController(
        chosen,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _cam = controller;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Init failed: $e";
      });
    }
  }

  Future<void> _loadTargetsFromDb() async {
    final db = await AppDb.instance.db;

    // 1) targets varsa oku
    List<Map<String, Object?>> rows = [];
    try {
      rows = await db.query('targets');
    } catch (_) {
      rows = [];
    }

    final map = <String, double>{};
    for (final r in rows) {
      final room = (r['room'] ?? '').toString().trim();
      final bearingVal = r['bearing'];
      final bearing = (bearingVal is num)
          ? bearingVal.toDouble()
          : double.tryParse(bearingVal.toString()) ?? 0;
      if (room.isNotEmpty) map[room] = bearing;
    }

    // 2) boşsa schedule room’lardan çıkar (bearing=0)
    if (map.isEmpty) {
      final sched = await db.query('schedule', columns: ['room']);
      final rooms = <String>{};
      for (final r in sched) {
        final room = (r['room'] ?? '').toString().trim();
        if (room.isNotEmpty) rooms.add(room);
      }
      for (final room in rooms) {
        map[room] = 0;
      }
    }

    _targets = map;
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _cam?.dispose();
    super.dispose();
  }

  double _normalizeDeg(double d) {
    d %= 360;
    if (d < 0) d += 360;
    return d;
  }

  double _deltaToTarget(double heading, double target) {
    final h = _normalizeDeg(heading);
    final t = _normalizeDeg(target);
    var delta = t - h;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta;
  }

  @override
  Widget build(BuildContext context) {
    final targetBearing = _selectedRoom == null
        ? null
        : _targets[_selectedRoom!];
    final heading = _heading;

    final delta = (heading != null && targetBearing != null)
        ? _deltaToTarget(heading, targetBearing)
        : null;

    final arrowRad = delta == null ? 0.0 : (delta * math.pi / 180);

    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    } else {
      body = Stack(
        fit: StackFit.expand,
        children: [
          if (!_demoMode && _cam != null && _cam!.value.isInitialized)
            CameraPreview(_cam!)
          else
            Container(color: Colors.black12),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _topPanel(heading, targetBearing, delta),
            ),
          ),

          Center(
            child: Transform.rotate(
              angle: arrowRad,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: const Icon(
                  Icons.navigation,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _instruction(delta),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_demoMode ? "AR Navigation (Demo)" : "AR Navigation"),
        actions: [
          IconButton(
            tooltip: "Re-init",
            onPressed: _initAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _topPanel(double? heading, double? targetBearing, double? delta) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_demoMode)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  "Demo mode: camera unavailable/denied.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            Row(
              children: [
                const Icon(Icons.place),
                const SizedBox(width: 8),
                const Text(
                  "Target:",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedRoom,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: _targets.keys
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRoom = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Heading: ${heading?.toStringAsFixed(0) ?? '-'}°",
                  ),
                ),
                Expanded(
                  child: Text(
                    "Target: ${targetBearing?.toStringAsFixed(0) ?? '-'}°",
                  ),
                ),
                Expanded(
                  child: Text("Δ: ${delta?.toStringAsFixed(0) ?? '-'}°"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _instruction(double? delta) {
    String text;
    if (delta == null) {
      text = "Move the phone to get compass data…";
    } else if (delta.abs() < 12) {
      text = "Go straight ✅";
    } else if (delta > 0) {
      text = "Turn RIGHT ➡️ (${delta.toStringAsFixed(0)}°)";
    } else {
      text = "Turn LEFT ⬅️ (${delta.abs().toStringAsFixed(0)}°)";
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
