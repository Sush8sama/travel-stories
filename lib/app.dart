import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// database imports
import 'database/database_helper.dart';
import 'database/data_model.dart';
import 'database/snapshot_model.dart';
import 'database/trip_model.dart';

const title = 'travel stories';

///----------------------------------
/// ROOT
/// --------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MapPage(title: title),
    );
  }
}

///----------------------------------
/// STATEFUL WIDGET
/// --------------------------------

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title});
  final String title;

  @override
  State<MapPage> createState() => _MapPageState();
}

///----------------------------------
/// APPSTATE
/// --------------------------------

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();  // google maps controller
  final TextEditingController _memoController = TextEditingController(); // text input controller
  LatLng? _currentPosition;
  String? _mapStyle;
  double _mapBottomPadding = 0;

  /// PERMISSION HANDLING
  // could add more specific returns here like enums of cases
  Future<bool> _handlePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /// UPDATES CURRENT POSITION OF THE STATE
  Future<void> _updatePosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final newLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _currentPosition = newLatLng;
      });

      // wait for the map controller to be available, if needed
      if (_controller.isCompleted) {
        final controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(newLatLng, 14),
        );
      } else {
        // If the map isn't ready yet, waiting for the future will await until onMapCreated runs.
        final controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(newLatLng, 14),
        );
      }
    } catch (e) {
      // handle errors (permissions, timeouts, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  /// INITIALIZATION
  Future<void> _initLocation() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location unavailable')),
        );
      }
      return;
    }
    await _updatePosition();
  }

  /// MAP STYLE
  Future<void> _loadMapStyle() async {
    _mapStyle = await DefaultAssetBundle.of(context)
        .loadString('assets/map_style.json');
  }

  /// LIFECYCLE
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapStyle();
  }
  @override
  void initState(){
    super.initState();
    _initLocation();
  }
  @override
  void dispose() {
    // If controller is completed, dispose the underlying GoogleMapController
    _memoController.dispose();
    if (_controller.isCompleted) {
      _controller.future.then((c) => c.dispose());
    }
    super.dispose();
  }

  /// BUTTON LOGIC
  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }
  void _onPressSnapshotButton() async {
    _updatePosition();
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location data...')),
      );
      return;
    }
    final double halfScreenHeight = MediaQuery.of(context).size.height * 0.5;
    setState(() {
      _mapBottomPadding = halfScreenHeight;
    });
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 13.0));
    _memoController.clear();
    if (mounted) {
      _showEditSnapshotSheet();
    }
  }


  /// SCREEN LOGIC
  void _showEditSnapshotSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Needed for the sheet to be draggable full screen
      backgroundColor: Colors.transparent, // Allows us to control the styling
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // Sheet starts covering % of the screen
          minChildSize: 0.05,     // Can be dragged down to
          maxChildSize: 0.93,     // Can be dragged up to
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              child: ListView(
                controller: scrollController, // Vital for drag behavior
                padding: const EdgeInsets.all(20),
                children: [
                  // --- Drag Handle ---
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),

                  // --- Title ---
                  Text(
                    "New Snapshot",
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // --- Coordinates (Read only) ---
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        "${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Description Input ---
                  TextField(
                    controller: _memoController,
                    decoration: const InputDecoration(
                      labelText: "Description / Memo",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 30),

                  // --- Confirm Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Close the sheet
                        Navigator.pop(context);
                        // Save data
                        _saveSnapshotToDB();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text("Confirm & Save"),
                    ),
                  ),

                  // Add extra padding for keyboard
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveSnapshotToDB() async {
    try {
      final dbHelper = DatabaseHelper.instance;

      int tripId;
      List<Trip> trips = await dbHelper.readAllTrips();

      // Check for trip or create default
      if (trips.isNotEmpty) {
        tripId = trips.last.id!;
      } else {
        final newTrip = Trip(
          title: "Test Trip",
          description: "Default trip for testing snapshots",
          createdAt: DateTime.now(),
        );
        tripId = await dbHelper.create(newTrip);
      }

      // Create Snapshot with the user's input (_memoController)
      final newSnapshot = Snapshot(
        tripId: tripId,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        timestamp: DateTime.now(),
        memo: _memoController.text, // <--- User input here
        markerColor: Colors.red[300].hashCode,
        photoPaths: [], // Add if your model supports list, otherwise json string
        markerIcon: "default",
        lineStyle: "default",
      );

      await dbHelper.create(newSnapshot);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Snapshot saved with memo: "${_memoController.text}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database Error: $e')),
        );
      }
    }
  }

  /// BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // --- Map ---
          GoogleMap(
            onMapCreated: _onMapCreated,
            padding: EdgeInsets.only(bottom: _mapBottomPadding),
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? const LatLng(0, 0),
              zoom: _currentPosition != null ? 14.0 : 2.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // --- Loading indicator ---
          if (_currentPosition == null)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Center(child: CircularProgressIndicator()),
            ),

          // --- Snapshot button ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: ElevatedButton.icon(
                  onPressed: _onPressSnapshotButton,
                  icon: const Icon(Icons.camera),
                  label: const Text('Save Snapshot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  )
              )
              ),
          ),

          // --- Snapshot editing screen ---

        ],
      ),
    );
  }
}
