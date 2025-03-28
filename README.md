# ParkALot
This is the project I've come up with for the LTA x ITSS hackathon 2025. All the code needed will be stored here for anyone interested! 
The full code is located at master branch , view the code there!

### Outline of the project:
An all-in-one app for road commuters to use. Leveraging third-party and crowdsourced information, our app prototype uses multiple API from the LTA DataMall and aims to make travelling with a car more convenient for everyone. The data from our prototype constantly refreshes for the latest information as well. The features include:
1.	A Map with the parking lots from the Carpark Availability API showing the number of available lots at that location 
2.	A heatmap overlay showing the speed of various roads in Singapore from the Traffic Speed Bands API, allowing users to choose which roads to commute on.
3.	A pop-up on the map at the location where incidents happened from the Traffic Incidents API, allowing users to avoid these roads for a faster commute.
4.	A simple interface to key in information on your parking lot number or take a picture of your current parking lo,t and a button to remove the currently stored data

### How the project works:
The code is split into 2 parts, one in python and one in flutter. Both is required for the project to operate.
The python code acts as a transmitting device where it cleans the data and through the flask library , hosts it locally for the flutter file to work
The Flutter code is the main app where it takes in the information from the python API ive created and display all its information in a user friendly way.

### Features of the Code:
•	Location Tracking:
o	Retrieves and updates the user's current location, which is used to center the map and add a "my location" button for easy access.
•	Parking Lot Display:
o	Fetches and displays parking lot data from a local API. Each parking lot is represented by a marker with information about availability and agency.
•	Traffic Speed and Incident Data:
o	Fetches real-time traffic speed data and incident reports from external APIs. Displays traffic incidents and speed variations on the map with custom markers and polylines.
•	Dynamic Data Updates:
o	Automatically refreshes the data every 30 seconds using a timer to keep the map up-to-date.
•	Interactive Map:
o	Users can see nearby parking lots, the current traffic situation, and their own location on a map that updates dynamically.
•	Custom Markers and Styling:
o	The app includes various styles for markers, such as custom sizes, colors, and text displays, to highlight parking lot details and traffic incidents.
•	Navigation to Save Parking Screen:
o	Users can tap on a button in the app bar to navigate to a new screen where they can save their current parking location.


#### Imports and Libraries:
•	flutter/material.dart: Used for creating the UI of the application, including the structure and design of elements like buttons, containers, and icons.
•	flutter_map/flutter_map.dart: Provides functionality for displaying maps in the app, enabling interactive maps and markers.
•	latlong2/latlong.dart: This library is used to handle geographical coordinates (latitude and longitude).
•	geolocator/geolocator.dart: Helps in accessing the device's location for geolocation services, used to obtain the current position of the user.
•	http/http.dart: Provides functionality for making HTTP requests to fetch data from APIs.
•	dart:convert: Enables the decoding of JSON data into Dart objects (used to parse the API responses).
•	save_parking_screen.dart: A custom page imported for navigating the user to a screen for saving their parking spot.
________________________________________
#### Classes and Methods:
1.	MyApp:
o	This is the root widget of the application. It defines the material app structure and specifies the home screen (MapScreen).
2.	MapScreen:
o	A StatefulWidget that manages the map display and location tracking.
o	State: _MapScreenState:
	_currentPosition: Stores the current position of the user (latitude and longitude).
	_locations: Holds the list of parking lot data from the API.
	_trafficData: Stores traffic speed data.
	_trafficIncidents: Holds traffic incident data.
o	initState():
	This method initializes data fetching for the current location, parking lot data, traffic speed data, and traffic incident data.
o	_getCurrentLocation():
	Retrieves the device’s current location using Geolocator.
	Updates the map’s center point to the user’s location.
o	_fetchParkingLotsData():
	Fetches parking lot data from the API endpoint (http://127.0.0.1:5000/get_data).
	Decodes the JSON response and updates the _locations list.
o	_fetchTrafficSpeedData():
	Fetches traffic speed data from another API endpoint (http://127.0.0.1:5000/get_traffic_speed_data).
	Decodes the JSON response and stores it in _trafficData.
o	_fetchTrafficIncidentData():
	Fetches traffic incident data from the API (http://127.0.0.1:5000/traffic_incidents).
	Decodes the response and stores the data in _trafficIncidents.
o	_getSpeedColor():
	Returns a color based on the traffic speed range (red for slow, green for fast).
o	_buildTrafficSpeedPolylines():
	Converts the traffic speed data into polyline representations on the map, with different colors indicating different speeds.
o	_buildMarkers():
	Creates markers for parking lot locations based on the data retrieved from the API.
	Skips markers if the coordinates are invalid or missing.
o	_buildTrafficIncidentMarkers():
	Builds markers for traffic incidents, with a detailed description and information.
	Adds custom markers with a red accent to represent incidents.


