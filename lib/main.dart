import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  
import 'dart:async';   
import 'save_parking_screen.dart';  

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
  List<List<dynamic>> _locations = [];  
  final double _radiusInMeters = 200.0;  
  List<List<dynamic>> _trafficData = []; 
  List<List<dynamic>> _trafficIncidents = []; 
  late Timer _timer;  

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();  
    _fetchParkingLotsData();  
    _fetchTrafficSpeedData();  
    _fetchTrafficIncidentData();  
    _startAutoRefresh();  
  }

  @override
  void dispose() {
    _timer.cancel();  
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
      _mapController.move(_currentPosition!, 15.0); 
    });
  }

  // Fetch parking lot data from the API
  Future<void> _fetchParkingLotsData() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_data')); // Replace with your API endpoint

    if (response.statusCode == 200) {
 
      List<dynamic> data = json.decode(response.body);


      setState(() {
        _locations = List<List<dynamic>>.from(data.map((lot) => lot));
      });
    } else {

      throw Exception('Failed to load parking lot data');
    }
  }

  // Fetch traffic speed data from the API
  Future<void> _fetchTrafficSpeedData() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_traffic_speed_data')); // Replace with your API endpoint

    if (response.statusCode == 200) {

      List<dynamic> data = json.decode(response.body);


      setState(() {
        _trafficData = List<List<dynamic>>.from(data.map((item) => item));
      });
    } else {

      throw Exception('Failed to load traffic speed data');
    }
  }

  // Fetch traffic incident data from the API
  Future<void> _fetchTrafficIncidentData() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/traffic_incidents')); 

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

  List<Polyline> _buildTrafficSpeedPolylines() {
    if (_trafficData.isEmpty) {
      return [];
    }

    return _trafficData
        .map((data) {
          var startCoordinates = data[1].split(' '); 
          var endCoordinates = data[2].split(' '); 
          int speedRange = data[0]; 

          double startLon = double.parse(startCoordinates[0]);
          double startLat = double.parse(startCoordinates[1]);
          double endLon = double.parse(endCoordinates[0]);
          double endLat = double.parse(endCoordinates[1]);

          Color color = _getSpeedColor(speedRange);

          return Polyline(
            points: [LatLng(startLat, startLon), LatLng(endLat, endLon)],
            strokeWidth: 8.0,  
            color: color,
          );
        })
        .toList();
  }

  // Function to build custom markers for multiple locations from API
  List<Marker> _buildMarkers() {
    return _locations
        .map((lot) {
          var coordinates = lot[3].split(' '); 

          if (coordinates.length < 2 || coordinates[0] == 'N/A' || coordinates[1] == 'N/A') {
            return null;  
          }

          try {
            double lat = double.parse(coordinates[0]);
            double lon = double.parse(coordinates[1]);

            return Marker(
              point: LatLng(lat, lon),
              width: 150,  
              height: 100,  
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
                      '${lot[0]}',  
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
            return null;  
          }
        })
        .where((marker) => marker != null)  
        .toList()
        .cast<Marker>();  
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
            width: 150, 
            height: 150, 
            child: Container(
              padding: EdgeInsets.all(12), 
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
                    overflow: TextOverflow.ellipsis, 
                  ),
                  SizedBox(height: 8), 
                  Expanded(
                    child: SingleChildScrollView(  
                      child: Text(
                        details,
                        style: TextStyle(fontSize: 12, color: Colors.white),
                        maxLines: 3, 
                        overflow: TextOverflow.ellipsis, 
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
          initialCenter: _currentPosition ?? LatLng(51.5074, -0.1278), 
          initialZoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _buildMarkers() + _buildTrafficIncidentMarkers(),  
          ),
          PolylineLayer(
            polylines: _buildTrafficSpeedPolylines(), 
          ),
          if (_currentPosition != null) ...[
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _currentPosition!,
                  radius: _radiusInMeters,
                  color: Colors.red.withOpacity(0.3), 
                  borderColor: Colors.red,  
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition!,
                  width: 50,
                  height: 50,
                  child: Icon(Icons.directions_car, color: Colors.black, size: 40), 
                ),
              ],
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(_currentPosition!, 15.0);
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}
