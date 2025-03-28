import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';  // For handling LatLng

class SaveParkingScreen extends StatefulWidget {
  final LatLng? currentPosition;  // Add this parameter to accept current position

  // Constructor to accept currentPosition as an optional parameter
  SaveParkingScreen({Key? key, this.currentPosition}) : super(key: key);

  @override
  _SaveParkingScreenState createState() => _SaveParkingScreenState();
}

class _SaveParkingScreenState extends State<SaveParkingScreen> {
  final TextEditingController _parkingLotController = TextEditingController();
  File? _image;
  bool _isPhotoTaken = false;

  List<Map<String, dynamic>> _savedParkingLots = [];

  Future<void> _pickImage({required ImageSource source}) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _image = File(image.path);
        _isPhotoTaken = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(source == ImageSource.camera ? "Photo Taken!" : "Image Selected!")));
    }
  }

  void _saveParkingLot() {
    String lotName = _parkingLotController.text;

    if (lotName.isNotEmpty) {
      setState(() {
        _savedParkingLots.add({
          'name': lotName,
          'image': _isPhotoTaken ? _image : null,
          'location': widget.currentPosition,  // Save current location with the parking lot
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Parking lot '$lotName' saved!")));
      _parkingLotController.clear();
      setState(() {
        _image = null;
        _isPhotoTaken = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a parking lot name!")));
    }
  }

  void _clearParkingLot() {
    setState(() {
      _savedParkingLots.clear();
      _image = null;
      _isPhotoTaken = false;
      _parkingLotController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Parking lot data cleared!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Save Parking Lot")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _parkingLotController,
              decoration: InputDecoration(
                labelText: 'Parking Lot Name',
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Show selected image if available
            _isPhotoTaken
                ? Column(
                    children: [
                      Image.file(_image!, width: 150, height: 150, fit: BoxFit.cover),
                      SizedBox(height: 10),
                    ],
                  )
                : Container(),

            // Buttons for taking photo and selecting from gallery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(source: ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text("Take a Photo"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(source: ImageSource.gallery),
                  icon: Icon(Icons.photo),
                  label: Text("Pick from Gallery"),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveParkingLot,
              child: Text("Save Parking Lot"),
            ),
            SizedBox(height: 20),

            // Show saved parking lot info
            _savedParkingLots.isNotEmpty
                ? Column(
                    children: [
                      Text(
                        "You Parked your vehicle at:",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _savedParkingLots.last['name'],
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      SizedBox(height: 10),
                      _savedParkingLots.last['image'] != null
                          ? Image.file(_savedParkingLots.last['image'], width: 150, height: 150, fit: BoxFit.cover)
                          : Container(),
                      SizedBox(height: 10),
                      Text(
                        "Location: Latitude: ${_savedParkingLots.last['location']?.latitude}, Longitude: ${_savedParkingLots.last['location']?.longitude}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  )
                : Container(),

            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _clearParkingLot,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                minimumSize: Size(double.infinity, 60),
              ),
              child: Text(
                "I have left",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
