import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  // Add this import to handle JSON decoding
import 'dart:async';   // Add this import for Timer

import 'save_parking_screen.dart';  // Import the new page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;  // Current position
  List<List<dynamic>> _locations = [];  // List of locations from API
  final double _radiusInMeters = 200.0;  // Radius in meters
  List<List<dynamic>> _trafficData = []; // List to store traffic data
  List<List<dynamic>> _trafficIncidents = []; // List to store traffic incidents
  late Timer _timer;  // Timer for automatic refresh

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();  // Get current location when the app starts
    _fetchParkingLotsData();  // Initial fetch of parking lot data
    _fetchTrafficSpeedData();  // Initial fetch of traffic speed data
    _fetchTrafficIncidentData();  // Initial fetch of traffic incidents data
    _startAutoRefresh();  // Start auto-refresh every 30 seconds
  }

  @override
  void dispose() {
    _timer.cancel();  // Cancel the timer when the screen is disposed
    super.dispose();
  }

  // Function to get the current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Update the current position
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _mapController.move(_currentPosition!, 15.0); // Move the camera to the current location
    });
  }

  // Fetch parking lot data from the API
  Future<void> _fetchParkingLotsData() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_data')); // Replace with your API endpoint

    if (response.statusCode == 200) {
      // Parse the JSON response
      List<dynamic> data = json.decode(response.body);

      // Extract and store locations in the _locations list
      setState(() {
        _locations = List<List<dynamic>>.from(data.map((lot) => lot));
      });
    } else {
      // Handle error if API request fails
      throw Exception('Failed to load parking lot data');
    }
  }

  // Fetch traffic speed data from the API
  Future<void> _fetchTrafficSpeedData() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_traffic_speed_data')); // Replace with your API endpoint

    if (response.statusCode == 200) {
      // Parse the JSON response
      List<dynamic> data = json.decode(response.body);

      // Extract and store traffic data in the _trafficData list
      setState(() {
        _trafficData = List<List<dynamic>>.from(data.map((item) => item));
      });
    } else {
      // Handle error if API request fails
      throw Exception('Failed to load traffic speed data');
    }
  }

  // Fetch traffic incident data from the API
  Future<void> _fetchTrafficIncidentData() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/traffic_incidents')); // Replace with your API endpoint

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        _trafficIncidents = List<List<dynamic>>.from(data.map((item) => item));
      });
    } else {
      throw Exception('Failed to load traffic incident data');
    }
  }

  // Start automatic refresh every 30 seconds
  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      _fetchParkingLotsData();
      _fetchTrafficSpeedData();
      _fetchTrafficIncidentData();
    });
  }

  // Function to get color based on speed range
  Color _getSpeedColor(int speedRange) {
    switch (speedRange) {
      case 1:
        return Colors.red; // Low speed (0-9)
      case 2:
        return Colors.orange; // Medium-low speed (10-19)
      case 3:
        return Colors.yellow; // Medium speed (20-29)
      case 4:
        return Colors.greenAccent; // Medium-high speed (30-39)
      case 5:
        return Colors.green; // High speed (40-49)
      case 6:
        return Colors.blue; // Very high speed (50-59)
      case 7:
        return Colors.lightBlue; // Extremely high speed (60-69)
      case 8:
        return Colors.green[800]!; // Highest speed (70+)
      default:
        return Colors.grey; // Default color if speed range is unknown
    }
  }

  // Function to build traffic speed polylines with thicker lines
  List<Polyline> _buildTrafficSpeedPolylines() {
    if (_trafficData.isEmpty) {
      return [];
    }

    return _trafficData
        .map((data) {
          var startCoordinates = data[1].split(' '); // Start coordinates (lon, lat)
          var endCoordinates = data[2].split(' '); // End coordinates (lon, lat)
          int speedRange = data[0]; // Speed range

          // Parse the coordinates as doubles
          double startLon = double.parse(startCoordinates[0]);
          double startLat = double.parse(startCoordinates[1]);
          double endLon = double.parse(endCoordinates[0]);
          double endLat = double.parse(endCoordinates[1]);

          // Get the color based on speed range
          Color color = _getSpeedColor(speedRange);

          // Return polyline representing the traffic speed segment
          return Polyline(
            points: [LatLng(startLat, startLon), LatLng(endLat, endLon)],
            strokeWidth: 8.0,  // Increased line thickness
            color: color,
          );
        })
        .toList();
  }

  // Function to build custom markers for multiple locations from API
  List<Marker> _buildMarkers() {
    return _locations
        .map((lot) {
          var coordinates = lot[3].split(' '); // Getting the coordinates from the API data

          // Check if coordinates are 'N/A N/A' and skip invalid ones
          if (coordinates.length < 2 || coordinates[0] == 'N/A' || coordinates[1] == 'N/A') {
            return null;  // Skip the marker if coordinates are 'N/A N/A'
          }

          // Try to parse the coordinates as double, catch any errors
          try {
            double lat = double.parse(coordinates[0]);
            double lon = double.parse(coordinates[1]);

            // Return Marker widget directly without using 'builder'
            return Marker(
              point: LatLng(lat, lon),
              width: 150,  // Adjust width and height to fit the content
              height: 100,  // Adjust height as needed
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lot[0]}',  // Development name (e.g., "HDB")
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                    ),
                    Text(
                      'Available Lots: ${lot[1]}',
                      style: TextStyle(fontSize: 10, color: Colors.black),
                    ),
                    Text(
                      'Agency: ${lot[2]}',
                      style: TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ],
                ),
              ),
            );
          } catch (e) {
            return null;  // Skip the marker if parsing fails
          }
        })
        .where((marker) => marker != null)  // Remove null markers from the list
        .toList()
        .cast<Marker>();  // Ensure the list is cast to List<Marker>
  }

  // Function to build markers for traffic incidents
  List<Marker> _buildTrafficIncidentMarkers() {
    return _trafficIncidents.map((incident) {
      if (incident.length == 4) {
        try {
          double lon = incident[1];
          double lat = incident[2];
          String description = incident[0];
          String details = incident[3];

          return Marker(
            point: LatLng(lat, lon),
            width: 150, // Increased width to make the box bigger
            height: 150, // Increased height to make the box bigger
            child: Container(
              padding: EdgeInsets.all(12), // Added more padding for spacing
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    overflow: TextOverflow.ellipsis, // Truncate text if it's too long
                  ),
                  SizedBox(height: 8), // Increased space between description and details
                  Expanded(
                    child: SingleChildScrollView(  // Allow scrolling for longer details text
                      child: Text(
                        details,
                        style: TextStyle(fontSize: 12, color: Colors.white),
                        maxLines: 3, // Limit to 3 lines of text
                        overflow: TextOverflow.ellipsis, // Show ellipsis if text is too long
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          print('Error processing incident data: $incident. Error: $e');
        }
      } else {
        print('Invalid incident data (not 4 elements): $incident');
      }
      return null;
    }).where((marker) => marker != null).cast<Marker>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Lots Map"),
        actions: [
          IconButton(
            icon: Icon(Icons.add_location_alt),
            onPressed: () {
              // Navigate to the new Save Parking screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SaveParkingScreen(currentPosition: _currentPosition)),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentPosition ?? LatLng(51.5074, -0.1278), // Default to London's coordinates or current location
          initialZoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _buildMarkers() + _buildTrafficIncidentMarkers(),  // Combine both parking and traffic markers
          ),
          PolylineLayer(
            polylines: _buildTrafficSpeedPolylines(), // Add traffic speed polylines
          ),
          if (_currentPosition != null) ...[
            // Circle around user's location with 200m radius (red circle)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _currentPosition!,
                  radius: _radiusInMeters,
                  color: Colors.red.withOpacity(0.3), // Translucent red circle
                  borderColor: Colors.red,  // Red border
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            // Marker for the user location (black car icon)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition!,
                  width: 50,
                  height: 50,
                  child: Icon(Icons.directions_car, color: Colors.black, size: 40), // Black car icon
                ),
              ],
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(_currentPosition!, 15.0); // Move to current location
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}
