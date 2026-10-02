import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../services/firestore_database.dart';
import '../models/spot.dart';
import '../models/food.dart';
import '../models/itinerary.dart';
import 'item_detail_page.dart';
import 'spot_food_page.dart';
// 🌟 引入交通服務 (TDX API)
import '../services/traffic_service.dart';

class MapPage extends StatefulWidget {
  final dynamic initialItem;
  final Itinerary? itinerary;

  const MapPage({super.key, this.initialItem, this.itinerary});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final FirestoreDatabase _db = FirestoreDatabase();
  final MapController _mapController = MapController();
  final User? _user = FirebaseAuth.instance.currentUser;

  Itinerary? _selectedItinerary;
  TabController? _dayTabController;
  int _selectedDayIndex = 0;

  int _extraDays = 0;
  DateTime? _startDate;

  final LatLng _chiayiCenter = const LatLng(23.4811, 120.4497);

  final List<Color> _dayColors = [
    AppColors.primary,
    const Color(0xFFE67E22),
    const Color(0xFFD35400),
    const Color(0xFFF39C12),
    const Color(0xFFBA4A00),
    const Color(0xFFDC7633),
  ];

  // 🌟 用來裝交通資料的清單
  List<YouBikeStation> _youbikeStations = [];
  List<BusStation> _busStations = [];

  // 🌟 控制顯示狀態與縮放門檻
  bool _showYouBikes = false;
  bool _showBuses = false;
  final double _bikeZoomThreshold = 15.5;
  final double _busZoomThreshold = 15.0;

  @override
  void initState() {
    super.initState();
    _selectedItinerary = widget.itinerary;
    _initDayTabs();
    _handleLocation();

    // 🌟 畫面一載入排隊抓資料
    _loadAllTrafficData();
  }

  Future<void> _loadAllTrafficData() async {
    await _loadYouBikeData();
    await _loadBusData();
  }

  Future<void> _loadYouBikeData() async {
    final stations = await TrafficService().getChiayiYouBikes();
    if (mounted) {
      setState(() {
        _youbikeStations = stations;
      });
    }
  }

  Future<void> _loadBusData() async {
    final stations = await TrafficService().getChiayiBusStations();
    if (mounted) {
      setState(() {
        _busStations = stations;
      });
    }
  }

  void _initDayTabs() {
    if (_selectedItinerary != null) {
      int maxDayInItems = 1;
      if (_selectedItinerary!.items.isNotEmpty) {
        maxDayInItems = _selectedItinerary!.items.map((e) => e.day).reduce((a, b) => a > b ? a : b);
      }
      int totalDays = (maxDayInItems > _extraDays ? maxDayInItems : _extraDays);
      _dayTabController = TabController(length: totalDays + 1, vsync: this);
      _dayTabController!.index = _selectedDayIndex < _dayTabController!.length ? _selectedDayIndex : 0;
      _dayTabController!.addListener(() {
        if (!_dayTabController!.indexIsChanging) {
          setState(() => _selectedDayIndex = _dayTabController!.index);
        }
      });
    }
  }

  void _addDay() {
    setState(() {
      int currentMax = 1;
      if (_selectedItinerary!.items.isNotEmpty) {
        currentMax = _selectedItinerary!.items.map((e) => e.day).reduce((a, b) => a > b ? a : b);
      }
      _extraDays = (currentMax > _extraDays ? currentMax : _extraDays) + 1;
      _initDayTabs();
    });
  }

  void _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  void didUpdateWidget(MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itinerary != oldWidget.itinerary) {
      setState(() {
        _selectedItinerary = widget.itinerary;
        _initDayTabs();
      });
      _handleLocation();
    }
  }

  void _handleLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedItinerary != null && _selectedItinerary!.items.isNotEmpty) {
        final points = _selectedItinerary!.items
            .map((e) => LatLng(e.geoPoint.latitude, e.geoPoint.longitude))
            .toList();
        if (points.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(points);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)));
        }
      } else if (widget.initialItem != null) {
        final lat = widget.initialItem.geoPoint.latitude;
        final lng = widget.initialItem.geoPoint.longitude;
        if (lat != 0) _mapController.move(LatLng(lat, lng), 16.0);
      }
    });
  }

  void _saveChanges() async {
    if (_selectedItinerary != null) await _db.saveItinerary(_selectedItinerary!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildMapLayer(),
          Positioned(right: 16, bottom: 280, child: _buildMapControls()),
          DraggableScrollableSheet(
            initialChildSize: _selectedItinerary == null ? 0.35 : 0.65,
            minChildSize: 0.2,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    _buildDragHandle(),
                    if (_selectedItinerary == null)
                      Expanded(child: _buildItinerarySelector(scrollController))
                    else
                      Expanded(child: _buildTimelineView(scrollController)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapLayer() {
    return StreamBuilder<List<Spot>>(
      stream: _db.getSpots(),
      builder: (context, spotSnapshot) {
        return StreamBuilder<List<Food>>(
          stream: _db.getFoods(),
          builder: (context, foodSnapshot) {
            List<Marker> markers = [];
            List<Polyline> polylines = [];

            if (_selectedItinerary != null) {
              final items = _selectedDayIndex == 0
                  ? _selectedItinerary!.items
                  : _selectedItinerary!.items.where((e) => e.day == _selectedDayIndex).toList();

              final points = items.map((e) => LatLng(e.geoPoint.latitude, e.geoPoint.longitude)).toList();

              if (points.isNotEmpty) {
                Color lineColor = _selectedDayIndex == 0 ? AppColors.primary : _dayColors[(_selectedDayIndex - 1) % _dayColors.length];
                polylines.add(Polyline(points: points, color: lineColor.withOpacity(0.6), strokeWidth: 4));

                for (int i = 0; i < items.length; i++) {
                  markers.add(Marker(
                    point: points[i], width: 40, height: 40,
                    child: CircleAvatar(
                      backgroundColor: _dayColors[(items[i].day - 1) % _dayColors.length],
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ));
                }
              }
            } else {
              if (spotSnapshot.hasData) {
                markers.addAll(spotSnapshot.data!.map((s) => Marker(
                  point: LatLng(s.geoPoint.latitude, s.geoPoint.longitude),
                  child: GestureDetector(onTap: () => _showPreview(s), child: const Icon(Icons.location_on, color: Colors.red, size: 35)),
                )));
              }
              if (foodSnapshot.hasData) {
                markers.addAll(foodSnapshot.data!.map((f) => Marker(
                  point: LatLng(f.geoPoint.latitude, f.geoPoint.longitude),
                  child: GestureDetector(onTap: () => _showPreview(f), child: const Icon(Icons.restaurant, color: Colors.orange, size: 28)),
                )));
              }
            }

            // 🌟 繪製公車站牌 Marker (加上了點擊事件 GestureDetector)
            if (_showBuses && _busStations.isNotEmpty) {
              markers.addAll(
                _busStations.map((station) {
                  return Marker(
                    width: 32.0,
                    height: 32.0,
                    point: LatLng(station.lat, station.lon),
                    child: GestureDetector(
                      onTap: () => _showBusDynamicPreview(station), // 🌟 點擊觸發彈出視窗
                      child: Tooltip(
                        message: '${station.name}\n(點擊查看公車動態)',
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.indigo, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4)
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            color: Colors.indigo,
                            size: 18.0,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }

            // 🌟 繪製 YouBike 站點 Marker
            if (_showYouBikes && _youbikeStations.isNotEmpty) {
              markers.addAll(
                _youbikeStations.map((station) {
                  final bool hasBikes = station.availableBikes > 0;
                  final Color markerColor = hasBikes ? Colors.teal : Colors.grey;

                  return Marker(
                    width: 36.0,
                    height: 36.0,
                    point: LatLng(station.lat, station.lon),
                    child: Tooltip(
                      message: '${station.name}\n可借: ${station.availableBikes} 台\n可還: ${station.emptySpaces} 格',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                          border: Border.all(color: markerColor, width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4)
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_bike,
                              color: markerColor,
                              size: 14.0,
                            ),
                            Text(
                              '${station.availableBikes}',
                              style: TextStyle(
                                color: markerColor,
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            }

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _chiayiCenter,
                initialZoom: 14.0,
                onPositionChanged: (position, hasGesture) {
                  final zoom = position.zoom;
                  if (zoom != null) {
                    bool shouldShowBikes = zoom >= _bikeZoomThreshold;
                    bool shouldShowBuses = zoom >= _busZoomThreshold;

                    if (_showYouBikes != shouldShowBikes || _showBuses != shouldShowBuses) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _showYouBikes = shouldShowBikes;
                            _showBuses = shouldShowBuses;
                          });
                        }
                      });
                    }
                  }
                },
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'org.ncyu.explore_chiayi'),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildItinerarySelector(ScrollController sc) {
    if (_user == null) return const Center(child: Text('請先登入帳號'));
    return StreamBuilder<List<Itinerary>>(
      stream: _db.getUserItineraries(_user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data ?? [];
        return ListView(
          controller: sc,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            const Text('選擇行程', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textTitle)),
            const SizedBox(height: 16),
            ...list.map((it) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.map_outlined, color: AppColors.primary),
                title: Text(it.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${it.items.length} 個地點'),
                onTap: () => setState(() {
                  _selectedItinerary = it;
                  _extraDays = 0;
                  _initDayTabs();
                  _handleLocation();
                }),
              ),
            )),
            _buildAddButton(
              onTap: _addNewItinerary,
              label: '新增行程列表',
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  void _addNewItinerary() async {
    if (_user == null) return;
    final newItin = Itinerary(
      id: '', uid: _user!.uid, title: '我的新行程', dateRange: '未定日期',
      items: [], createdAt: DateTime.now(),
    );
    final String docId = await _db.saveItinerary(newItin);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已新增行程列表'),
          action: SnackBarAction(
            label: '查看',
            onPressed: () {
              setState(() {
                _selectedItinerary = Itinerary(
                  id: docId,
                  uid: newItin.uid,
                  title: newItin.title,
                  dateRange: newItin.dateRange,
                  items: [],
                  createdAt: newItin.createdAt,
                );
                _extraDays = 0;
                _initDayTabs();
                _handleLocation();
              });
            },
          ),
        ),
      );
    }
  }

  Widget _buildTimelineView(ScrollController sc) {
    final itin = _selectedItinerary!;
    final List<ItineraryItem> filteredItems = _selectedDayIndex == 0
        ? itin.items
        : itin.items.where((e) => e.day == _selectedDayIndex).toList();

    return Column(
      children: [
        if (_dayTabController != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _dayTabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      const Tab(text: '總覽'),
                      ...List.generate(_dayTabController!.length - 1, (i) {
                        int dayNum = i + 1;
                        String dateStr = _startDate != null ? " (${_startDate!.add(Duration(days: i)).month}/${_startDate!.add(Duration(days: i)).day})" : "";
                        return Tab(text: '第 $dayNum 天$dateStr');
                      }),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.calendar_month, color: AppColors.primary), onPressed: _selectStartDate),
                IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primary), onPressed: _addDay),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: ReorderableListView.builder(
            scrollController: sc,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 8,
              color: Colors.transparent,
              child: child,
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            itemCount: filteredItems.length + 1,
            onReorder: (oldIdx, newIdx) {
              if (oldIdx >= filteredItems.length) return;
              if (newIdx > filteredItems.length) newIdx = filteredItems.length;
              setState(() {
                if (oldIdx < newIdx) newIdx -= 1;
                final item = filteredItems.removeAt(oldIdx);
                filteredItems.insert(newIdx, item);

                if (_selectedDayIndex == 0) {
                  itin.items.clear();
                  itin.items.addAll(filteredItems);
                } else {
                  final List<ItineraryItem> otherItems = itin.items.where((e) => e.day != _selectedDayIndex).toList();
                  itin.items.clear();
                  itin.items.addAll(otherItems);
                  itin.items.addAll(filteredItems);
                  itin.items.sort((a, b) {
                    if (a.day != b.day) return a.day.compareTo(b.day);
                    return 0;
                  });
                }
                _saveChanges();
              });
            },
            itemBuilder: (context, index) {
              if (index == filteredItems.length) {
                return Padding(
                  key: const ValueKey('add_item_button'),
                  padding: const EdgeInsets.only(left: 68, right: 16, bottom: 40),
                  child: _buildAddButton(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SpotFoodPage(
                      targetDay: _selectedDayIndex == 0 ? 1 : _selectedDayIndex,
                    ))),
                    label: '新增景點/美食',
                  ),
                );
              }
              final item = filteredItems[index];
              return _buildTimelineItem(item, index + 1, ValueKey(item.id + index.toString()), index == filteredItems.length - 1);
            },
          ),
        ),
        TextButton.icon(onPressed: () => setState(() => _selectedItinerary = null), icon: const Icon(Icons.swap_horiz), label: const Text('更換行程清單')),
      ],
    );
  }

  Widget _buildAddButton({required VoidCallback onTap, required String label}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(ItineraryItem item, int step, Key key, bool isLast) {
    final String defaultTime = "00:00";
    final Color dayColor = _dayColors[(item.day - 1) % _dayColors.length];

    return Container(
      key: key,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60, alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => _pickTime(item),
                child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(item.startTime ?? defaultTime, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: dayColor))),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (!isLast) Container(margin: const EdgeInsets.only(top: 26), width: 2, color: dayColor.withOpacity(0.3)),
                  Positioned(top: 1, child: Container(width: 23, height: 23, decoration: BoxDecoration(color: dayColor, shape: BoxShape.circle), child: Center(child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 30),
                child: InkWell(
                  onTap: () async {
                    final full = item.type == 'spot' ? await _db.getSpot(item.id) : await _db.getFood(item.id);
                    if (full != null && mounted) Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetailPage(
                      item: full,
                      targetDay: item.day,
                    )));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dayColor.withOpacity(0.15)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_convertUrl(item.imageUrl), width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image_outlined))),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textTitle))),
                        IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.textTitle, size: 20), onPressed: () => _removeItem(item)),
                        const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem(ItineraryItem item) { setState(() { _selectedItinerary!.items.remove(item); _saveChanges(); }); }

  void _pickTime(ItineraryItem item) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        final idx = _selectedItinerary!.items.indexOf(item);
        if (idx != -1) {
          _selectedItinerary!.items[idx] = ItineraryItem(
              id: item.id, name: item.name, type: item.type,
              geoPoint: item.geoPoint, imageUrl: item.imageUrl,
              startTime: picked.format(context), day: item.day
          );
          _saveChanges();
        }
      });
    }
  }

  Widget _buildMapControls() => Column(children: [
    FloatingActionButton(heroTag: 'map_in', mini: true, backgroundColor: Colors.white, child: const Icon(Icons.add, color: AppColors.primary), onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
    const SizedBox(height: 8),
    FloatingActionButton(heroTag: 'map_out', mini: true, backgroundColor: Colors.white, child: const Icon(Icons.remove, color: AppColors.primary), onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
  ]);

  Widget _buildDragHandle() => Container(width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)));

  void _showPreview(dynamic item) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (c) => Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetailPage(
          item: item,
          targetDay: _selectedDayIndex == 0 ? 1 : _selectedDayIndex,
        ))), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('查看詳細介紹'))),
      ]),
    ));
  }

  // 🌟 點擊公車站牌後彈出的動態資訊視窗 (新增)
  void _showBusDynamicPreview(BusStation station) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 頂部站牌名稱
                  Row(
                    children: [
                      const Icon(Icons.directions_bus, color: Colors.indigo, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            station.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textTitle)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 使用 FutureBuilder 即時呼叫 API 取得動態
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300), // 限制高度避免內容過多破圖
                    child: FutureBuilder<List<BusArrival>>(
                        future: TrafficService().getBusArrivalTimes(station.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text('目前查無經過此站的公車動態', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                )
                            );
                          }

                          final arrivals = snapshot.data!;
                          // 根據到站時間進行排序 (把即將到站的排在最前面)
                          arrivals.sort((a, b) {
                            if (a.estimateTime != null && b.estimateTime != null) {
                              return a.estimateTime!.compareTo(b.estimateTime!);
                            } else if (a.estimateTime != null) {
                              return -1;
                            } else if (b.estimateTime != null) {
                              return 1;
                            }
                            return 0;
                          });

                          return ListView.builder(
                              shrinkWrap: true,
                              itemCount: arrivals.length,
                              itemBuilder: (context, index) {
                                final arrival = arrivals[index];
                                // 判斷是否兩分鐘內到站，用紅色字體警示
                                final isArriving = arrival.estimateTime != null && arrival.estimateTime! <= 120;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: Colors.indigo.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: Text(
                                        arrival.routeName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 15)
                                    ),
                                  ),
                                  trailing: Text(
                                    arrival.statusText,
                                    style: TextStyle(
                                        color: isArriving ? Colors.red : Colors.grey[700],
                                        fontWeight: isArriving ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 16
                                    ),
                                  ),
                                );
                              }
                          );
                        }
                    ),
                  ),
                ],
              )
          );
        }
    );
  }

  String _convertUrl(String url) {
    if (url.contains('drive.google.com')) {
      final id = url.contains('id=') ? url.split('id=')[1].split('&')[0] : (url.contains('/file/d/') ? url.split('/file/d/')[1].split('/')[0] : '');
      return 'https://drive.google.com/uc?export=view&id=$id';
    }
    return url;
  }
}