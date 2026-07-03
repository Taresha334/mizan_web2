// filepath: lib/features/farmers/pages/mizan_agent_map_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MizanAgentMapPage extends StatefulWidget {
  final LatLng initialCenter;
  final bool isPickerMode;
  const MizanAgentMapPage({
    super.key,
    this.initialCenter = const LatLng(8.5410, 39.2689),
    this.isPickerMode = false,
  });

  @override
  State<MizanAgentMapPage> createState() => _MizanAgentMapPageState();
}

class _MizanAgentMapPageState extends State<MizanAgentMapPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, String> _categoryOptions = {
    'Agricultural Agent / Agro-Dealer': 'agent',
    'Veterinary Doctor / AI Technician': 'vet',
    'Labour Worker / Farm Manager': 'worker',
    'Farmer / Seed Multiplier': 'farmer',
    'Agricultural-Pharmacist / Agronomist': 'specialist',
    'Logistics / Post-Harvest Expert': 'logistics',
    'Other Agricultural Partner': 'others',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categoryOptions.length + 1,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isPickerMode
          ? AppBar(
              title: const Text("PICK LOCATION"),
              backgroundColor: const Color(0xFF1B5E20),
            )
          : AppBar(
              title: const Text("MIZAN SERVICE HUB"),
              backgroundColor: const Color(0xFF1B5E20),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  const Tab(text: "ALL"),
                  ..._categoryOptions.keys.map(
                    (l) => Tab(text: l.toUpperCase()),
                  ),
                ],
              ),
            ),
      body: widget.isPickerMode
          ? MapContentWidget(
              key: const ValueKey("PICKER"),
              categoryKey: null,
              isPickerMode: true,
              initialCenter: widget.initialCenter,
            )
          : TabBarView(
              controller: _tabController,
              children: [
                MapContentWidget(
                  key: const ValueKey("ALL"),
                  categoryKey: null,
                  isPickerMode: false,
                  initialCenter: widget.initialCenter,
                ),
                ..._categoryOptions.values.map(
                  (v) => MapContentWidget(
                    key: ValueKey(v),
                    categoryKey: v,
                    isPickerMode: false,
                    initialCenter: widget.initialCenter,
                  ),
                ),
              ],
            ),
    );
  }
}

class MapContentWidget extends StatefulWidget {
  final String? categoryKey;
  final bool isPickerMode;
  final LatLng initialCenter;
  const MapContentWidget({
    super.key,
    this.categoryKey,
    required this.isPickerMode,
    required this.initialCenter,
  });

  @override
  State<MapContentWidget> createState() => _MapContentWidgetState();
}

class _MapContentWidgetState extends State<MapContentWidget>
    with AutomaticKeepAliveClientMixin {
  final PopupController _popupController = PopupController();
  final MapController _mapController = MapController();
  String _searchQuery = "";

  @override
  bool get wantKeepAlive => true;

  Future<void> _makePhoneCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  LatLng _getJitteredPosition(LatLng point, int index, int total) {
    if (total == 1) return point;
    const double offset = 0.0003;
    final angle = 2 * pi * index / total;
    return LatLng(
      point.latitude + offset * cos(angle),
      point.longitude + offset * sin(angle),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final query = Supabase.instance.client
        .from('profiles')
        .select('*')
        .eq('is_active', true)
        .not('latitude', 'is', null);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.isPickerMode ? const Stream.empty() : query.asStream(),
      builder: (context, snapshot) {
        final data = snapshot.hasData
            ? snapshot.data!.where((a) {
                final filterRole = (widget.categoryKey ?? "")
                    .toLowerCase()
                    .trim();

                // DATA RECONCILIATION: Check both columns to bypass database trigger normalization
                final dbCustomRole = (a['custom_role']?.toString() ?? "")
                    .toLowerCase()
                    .trim();
                final dbCategory = (a['category']?.toString() ?? "")
                    .toLowerCase()
                    .trim();

                // Effective role: custom_role first, fallback to category
                final effectiveRole = dbCustomRole.isNotEmpty
                    ? dbCustomRole
                    : dbCategory;

                final matchesCategory =
                    (widget.categoryKey == null || effectiveRole == filterRole);
                final matchesCity =
                    _searchQuery.isEmpty ||
                    (a['city_name'] ?? "").toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );

                return matchesCategory && matchesCity;
              }).toList()
            : [];

        return Column(
          children: [
            if (!widget.isPickerMode)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: "Search by City",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            Expanded(
              child: FlutterMap(
                key: ValueKey(widget.categoryKey),
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.initialCenter,
                  initialZoom: 11.0,
                  onTap: widget.isPickerMode
                      ? (_, point) => Navigator.pop(context, point)
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  if (!widget.isPickerMode)
                    PopupMarkerLayer(
                      options: PopupMarkerLayerOptions(
                        popupController: _popupController,
                        markers: List.generate(data.length, (i) {
                          final a = data[i];
                          final pos = _getJitteredPosition(
                            LatLng(
                              (a['latitude'] as num).toDouble(),
                              (a['longitude'] as num).toDouble(),
                            ),
                            i,
                            data.length,
                          );
                          return Marker(
                            key: ValueKey(a['id']),
                            point: pos,
                            child: GestureDetector(
                              onTap: () => _popupController.showPopupsOnlyFor([
                                Marker(
                                  key: ValueKey(a['id']),
                                  point: pos,
                                  child: const Icon(
                                    Icons.person_pin_circle,
                                    color: Color(0xFF1B5E20),
                                    size: 35,
                                  ),
                                ),
                              ]),
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Color(0xFF1B5E20),
                                size: 35,
                              ),
                            ),
                          );
                        }),
                        popupDisplayOptions: PopupDisplayOptions(
                          builder: (c, m) {
                            final a = data.firstWhere(
                              (x) => x['id'] == (m.key as ValueKey).value,
                            );
                            return Card(
                              child: Container(
                                width: 250,
                                padding: const EdgeInsets.all(8),
                                child: ListTile(
                                  title: Text(
                                    a['full_name'] ?? 'Agent',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${a['custom_role'] ?? 'Agent'}\n${a['city_name'] ?? 'N/A'}",
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.green,
                                    ),
                                    onPressed: () =>
                                        _makePhoneCall(a['phone'] ?? ""),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
