from flask import Flask, jsonify
import requests

app = Flask(__name__)

# Traffic Speed Bands URL and headers
traffic_speed_url = "https://datamall2.mytransport.sg/ltaodataservice/v3/TrafficSpeedBands"
traffic_speed_headers = {
    'AccountKey': 'ENTERAPIKEY'  # Replace with your actual AccountKey
}

# Car Park Availability URL and headers
car_park_url = "https://datamall2.mytransport.sg/ltaodataservice/CarParkAvailabilityv2"
car_park_headers = {
    'AccountKey': 'ENTERAPIKEY'  # Ensure no leading space in the AccountKey
}

# Traffic Incidents URL and headers
traffic_incidents_url = "https://datamall2.mytransport.sg/ltaodataservice/TrafficIncidents"
traffic_incidents_headers = {
    'AccountKey': 'ENTERAPIKEY'  # Replace with your actual AccountKey
}

@app.route('/get_traffic_speed_data', methods=['GET'])
def get_traffic_speed_data():
    payload = {}
    
    # Fetch the latest traffic speed data
    response = requests.get(traffic_speed_url, headers=traffic_speed_headers, data=payload)

    # Check if the response is in JSON format and parse it
    try:
        data = response.json()
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        data = {}

    # Nested list to store the speedband details in the requested format
    speedband_list = []

    # Ensure the response data is a dictionary with a 'value' key
    if isinstance(data, dict) and 'value' in data:
        for road in data['value']:
            if isinstance(road, dict):  # Ensure each road is a dictionary
                speed_band = road.get('SpeedBand', 'N/A')
                start_lon = road.get('StartLon', 'N/A')
                start_lat = road.get('StartLat', 'N/A')
                end_lon = road.get('EndLon', 'N/A')
                end_lat = road.get('EndLat', 'N/A')

                # Add the values in the requested order: [speedband, start_long start_lat, end_long end_lat]
                speedband_list.append([speed_band, f"{start_lon} {start_lat}", f"{end_lon} {end_lat}"])

    return jsonify(speedband_list)


@app.route('/get_data', methods=['GET'])
def get_data():
    payload = {}
    
    # Fetch the latest data from the car park availability API
    response = requests.get(car_park_url, headers=car_park_headers, data=payload)

    # Check if the response is in JSON format and parse it
    try:
        data = response.json()
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        data = {}

    # Nested list to store the car park details in the requested format
    nested_list = []

    # Ensure the response data is a dictionary with a 'value' key
    if isinstance(data, dict) and 'value' in data:
        for car_park in data['value']:
            if isinstance(car_park, dict):  # Ensure car_park is a dictionary
                agency = car_park.get('Agency', 'N/A')
                available_lots = car_park.get('AvailableLots', 'N/A')
                development = car_park.get('Development', 'N/A')
                location = car_park.get('Location', 'N/A')

                # Split the location (latitude and longitude)
                lat_long = location.split() if location != 'N/A' else ['N/A', 'N/A']

                # Ensure there are exactly two items in lat_long
                if len(lat_long) == 2:
                    lat_long_str = f"{lat_long[0]} {lat_long[1]}"
                else:
                    lat_long_str = "N/A N/A"  # Handle the case when location is not properly formatted

                # Add the values in the requested order: [agency, available_lots, development, location]
                nested_list.append([agency, available_lots, development, lat_long_str])

    return jsonify(nested_list)


@app.route('/traffic_incidents', methods=['GET'])
def get_traffic_incidents():
    # Fetch the latest traffic incident data
    response = requests.get(traffic_incidents_url, headers=traffic_incidents_headers)

    # Check if the response is in JSON format and parse it
    try:
        data = response.json()
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        data = {}

    # List to store traffic incidents in the requested format
    traffic_incidents_list = []

    # Ensure the response data is a dictionary with a 'value' key
    if isinstance(data, dict) and 'value' in data:
        for incident in data['value']:
            if isinstance(incident, dict):  # Ensure incident is a dictionary
                incident_type = incident.get('Type', 'N/A')  # Assuming Type is present for the incident type
                latitude = incident.get('Latitude', 'N/A')
                longitude = incident.get('Longitude', 'N/A')
                message = incident.get('Message', 'No message')

                # Add the values in the requested order: [type, lang, lat, message]
                traffic_incidents_list.append([incident_type, longitude, latitude, message])

    return jsonify(traffic_incidents_list)


if __name__ == "__main__":
    app.run(debug=True)
