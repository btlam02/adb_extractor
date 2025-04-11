#!/usr/bin/python
import sqlite3
import sys
import time

import polyline
import folium
import argparse
from geopy.geocoders import Nominatim
import xlsxwriter
import pyfiglet


# Author: Fabian Nunes
# Script to decode an encoded polyline value to a set of coordinates and show the route in a HTML map or convert them to a KML file
# Requires the polyline module (Install with pip install polyline) and folium (also PIP)
# Example: python decode_polyline.py file.txt -t html|kml

class Bcolors:
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    FAIL = '\033[91m'
    OKYELLOW = '\033[93m'
    ENDC = '\033[0m'

parser = argparse.ArgumentParser(
        description='Decode an encoded polyline value to a set of coordinates and generate a map')
parser.add_argument('-f', '--file', help='File with the encoded polyline', required=True)
parser.add_argument('-t', '--type', help='Type of output', required=True, choices=["html", "kml"])
args = parser.parse_args()

FILE = args.file
TYPE = args.type

conn = sqlite3.connect('coordinates.db')
c = conn.cursor()

def get_raw_fields(latitude, longitude):
    geolocator = Nominatim(user_agent="address-retrieval")
    location = geolocator.reverse(f"{latitude}, {longitude}")
    if location:
        raw_data = location.raw
        # check if raw_data["address"]["road"] exists
        not_present = False
        if "road" in raw_data["address"]:
            road = raw_data["address"]["road"]
        elif "hamlet" in raw_data["address"]:
            road = raw_data["address"]["hamlet"]
        else:
            road = 'Not Present'
            not_present = True

        if "city" in raw_data["address"]:
            city = raw_data["address"]["city"]
        elif "town" in raw_data["address"]:
            city = raw_data["address"]["town"]
        else:
            city = 'Not present'
            not_present = True

        if not not_present:
            store_raw_fields(latitude, longitude, road, city,
                             raw_data["address"]["postcode"], raw_data["address"]["country"])
        # create a dict
        obtained_data = {"road": road, "city": city, "postcode": raw_data["address"]["postcode"],
                         "country": raw_data["address"]["country"]}
        return obtained_data
    else:
        print("Location not found.")


# Function to store the raw fields in a sqlite database if not already present, and create the database if not present
def store_raw_fields(latitude_value, longitude_value, road_value, city_value, postcode_value, country_value):
    print(Bcolors.OKBLUE + "[Info ] Storing raw fields in database" + Bcolors.ENDC)
    # Check if the entry is already present
    c.execute('''SELECT * FROM raw_fields WHERE latitude=? AND longitude=?''', (latitude_value, longitude_value))
    if c.fetchone() is None:
        # Insert a row of data
        c.execute('''INSERT INTO raw_fields (latitude, longitude, road, city, postcode, country) 
                      VALUES (?, ?, ?, ?, ?, ?)''',
                  (latitude_value, longitude_value, road_value, city_value, postcode_value, country_value))

        # Save (commit) the changes
        conn.commit()


# Function to check if the raw fields are already present in the database and return them if present or return None
def check_raw_fields(latitude, longitude):
    # Check if the entry is already present
    print(Bcolors.OKBLUE + "[Info ] Checking if raw fields are already present in database" + Bcolors.ENDC)
    c.execute('''SELECT * FROM raw_fields WHERE latitude=? AND longitude=?''', (latitude, longitude))
    data = c.fetchone()
    # convert to dict
    return data


if __name__ == '__main__':
    ascii_banner = pyfiglet.figlet_format("Garmin Parser")
    print(Bcolors.OKYELLOW + ascii_banner)
    print(Bcolors.ENDC)
    try:
        f = open(FILE, 'r')
    except IOError:
        print(Bcolors.FAIL + "File not found" + Bcolors.ENDC)
        sys.exit(1)

    # Create table if not present
    print(Bcolors.OKBLUE + "[Info ] Creating database if needed" + Bcolors.ENDC)
    c.execute('''CREATE TABLE IF NOT EXISTS raw_fields (id INTEGER PRIMARY KEY AUTOINCREMENT, stored_time TIMESTAMP DATETIME DEFAULT CURRENT_TIMESTAMP, latitude text, longitude text, road text, city text, postcode text, country text)''')

    print(Bcolors.OKBLUE + "[Info ] Reading file: " + FILE)
    f = open(FILE, "r")
    lines = f.readlines()
    f.close()

    print(Bcolors.OKBLUE + "[Info ] Decoding polyline")
    title_index = 0
    for line in lines:
        line = line.strip()
        print(Bcolors.OKBLUE + "[Info ] Decoding polyline: " + line)
        # print(line)
        try:
            coordinates = polyline.decode(line)
        except:
            print(Bcolors.FAIL + "Error decoding polyline" + Bcolors.ENDC)
            sys.exit(1)

        # print(coordinates)
        # Create an excel file with the coordinates
        print(Bcolors.OKBLUE + "[Info ] Creating excel file with coordinates" + Bcolors.ENDC)
        f = open('coordinates'+str(title_index)+'.xlsx', 'w')
        workbook = xlsxwriter.Workbook('coordinates'+str(title_index)+'.xlsx')
        worksheet = workbook.add_worksheet()
        row = 0
        col = 0
        worksheet.write(row, col, "Latitude")
        worksheet.write(row, col + 1, "Longitude")
        worksheet.write(row, col + 2, "Road")
        worksheet.write(row, col + 3, "City")
        worksheet.write(row, col + 4, "Postcode")
        worksheet.write(row, col + 5, "Country")
        row += 1
        for coordinate in coordinates:
            coordinate = str(coordinate)
            # remove the parenthesis
            coordinate = coordinate.replace("(", "")
            coordinate = coordinate.replace(")", "")
            coordinate = coordinate.split(",")
            lat = float(coordinate[0])
            lat = round(lat, 3)
            lon = float(coordinate[1])
            lon = round(lon, 3)

            worksheet.write(row, col, lat)
            worksheet.write(row, col + 1, lon)
            location = check_raw_fields(lat, lon)
            if location is None:
                print(Bcolors.OKBLUE + "[Info ] Location not found in database, querying Nominatim" + Bcolors.ENDC)
                location = get_raw_fields(lat, lon)
                for key, value in location.items():
                    if key == "road":
                        worksheet.write(row, col + 2, value)
                    elif key == "city":
                        worksheet.write(row, col + 3, value)
                    elif key == "postcode":
                        worksheet.write(row, col + 4, value)
                    elif key == "country":
                        worksheet.write(row, col + 5, value)
            else:
                print(Bcolors.OKBLUE + "[Info ] Location found in database" + Bcolors.ENDC)
                worksheet.write(row, col + 2, location[4])
                worksheet.write(row, col + 3, location[5])
                worksheet.write(row, col + 4, location[6])
                worksheet.write(row, col + 5, location[7])
            row += 1
        workbook.close()
        #print(Bcolors.OKGREEN + "[Done ] Decoded polyline: " + line)

        if TYPE == "html":
            # Generate HTML file with the map and the route using Folium
            place_lat = []
            place_lon = []
            print(Bcolors.OKBLUE + "[Info ] Generating HTML file with the map and the route")
            m = folium.Map(location=[coordinates[0][0], coordinates[0][1]], zoom_start=10, max_zoom=19)

            for coordinate in coordinates:
                # if points are to close, skip
                if len(place_lat) > 0 and abs(place_lat[-1] - coordinate[0]) < 0.0001 and abs(
                        place_lon[-1] - coordinate[1]) < 0.0001:
                    continue
                else:
                    place_lat.append(coordinate[0])
                    place_lon.append(coordinate[1])

            points = []
            for i in range(len(place_lat)):
                points.append([place_lat[i], place_lon[i]])

            # Add points to map
            for index, lat in enumerate(place_lat):
                # Start point
                if index == 0:
                    folium.Marker([lat, place_lon[index]],
                                  popup=('Start Location\n'.format(index)),
                                  icon=folium.Icon(color='blue', icon='flag', prefix='fa')).add_to(m)
                # last point
                elif index == len(place_lat) - 1:
                    folium.Marker([lat, place_lon[index]],
                                  popup=(('End Location\n').format(index)),
                                  icon=folium.Icon(color='red', icon='flag', prefix='fa')).add_to(m)
                # middle points

            # Create polyline
            folium.PolyLine(points, color="red", weight=2.5, opacity=1).add_to(m)
            # Save the map to an HTML file
            title = 'Garmin_Polyline_Map' + str(title_index)
            m.save(title + '.html')
            print(Bcolors.OKGREEN + "[Done ] Generated HTML file with the coordinates" + Bcolors.ENDC)
        elif TYPE == "kml":
            # Generate KML file with the coordinates
            print(Bcolors.OKBLUE + "[Info ] Generating KML file with the coordinates")
            kml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <kml xmlns="http://www.opengis.net/kml/2.2">
            <Document>
            <name>Coordinates</name>
            <description>Coordinates</description>
            <Style id="yellowLineGreenPoly">
                <LineStyle>
                    <color>7f00ffff</color>
                    <width>4</width>
                </LineStyle>
                <PolyStyle>
                    <color>7f00ff00</color>
                </PolyStyle>
            </Style>
            <Placemark>
                <name>Absolute Extruded</name>
                <description>Transparent green wall with yellow outlines</description>
                <styleUrl>#yellowLineGreenPoly</styleUrl>
                <LineString>
                    <extrude>1</extrude>
                    <tessellate>1</tessellate>
                    <altitudeMode>clampedToGround</altitudeMode>
                    <coordinates>
                    """
            for coordinate in coordinates:
                kml += str(coordinate[1]) + "," + str(coordinate[0]) + ",0 \n"
            kml = kml[:-1]
            kml += """
                    </coordinates>
                </LineString>
            </Placemark>
            </Document>
            </kml>
            """
            # remove the first space
            kml = kml[1:]
            # remove last line
            kml = kml[:-1]
            # remove extra indentation
            kml = kml.replace("    ", "")
            title = 'Garmin_Polyline_Map' + str(title_index) + '.kml'
            f = open(title, "w")
            f.write(kml)
            f.close()
            print(Bcolors.OKGREEN + "[Done ] Generated KML file with the coordinates" + Bcolors.ENDC)
        print(Bcolors.OKGREEN + "[Done ] Decoded polyline: " + line + Bcolors.ENDC)
        time.sleep(1)
        title_index += 1
    print(Bcolors.OKGREEN + "[Done ] Decoded all polylines" + Bcolors.ENDC)
    conn.close()
