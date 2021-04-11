import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int temperature = 0;
  String cityName = "London";
  int woeid = 0;

  String weather = "clear";
  String abbr = "c";
  String errorMessage = "";
  final List<_PositionItem> _positionItems = <_PositionItem>[];
  Position currentLocation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // getLocationSearch();
  }


  void getSearchLattLong(String lattlong) async {
    try {
      var url = Uri.parse(
          "https://www.metaweather.com/api/location/search/?lattlong=$lattlong");
      var result = await http.get(url);
      var decodeJson = json.decode(result.body)[0];
      print(decodeJson);
      setState(() {
        cityName = decodeJson["title"];
        woeid = decodeJson["woeid"];
        errorMessage = "";
      });
    } catch (error) {
      errorMessage = "No se encontró la ciudad, intenta nuevamente.";
      setState(() {

      });
    }
  }


  void getGeolocation() async {

    await Geolocator.getCurrentPosition().then((value) => {
      currentLocation = value
    });

    setState(() { });

    print(currentLocation.latitude.toString());
    print(currentLocation.longitude.toString());
    var pos = (currentLocation == null ? 'Unknown' : currentLocation.latitude.toString() + ',' + currentLocation.longitude.toString());
    getSearchLattLong(pos);
    getLocation();

  }
  void onGeoButtonClick(String pos) {
    getSearchLattLong(pos);
    getLocation();
  }
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error(
            'Location permissions are denied');
      }
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void getSearch(String name) async {
    try {
      var url = Uri.parse(
          "https://www.metaweather.com/api/location/search/?query=$name");
      var result = await http.get(url);
      var decodeJson = json.decode(result.body)[0];
      print(decodeJson);
      setState(() {
        cityName = decodeJson["title"];
        woeid = decodeJson["woeid"];
        errorMessage = "";
      });
    } catch (error) {
      errorMessage = "No se encontró la ciudad, intenta nuevamente.";
      setState(() {

      });
    }
  }
  void getLocation() async {
    var url = Uri.parse("https://www.metaweather.com/api/location/$woeid");
    var result = await http.get(url);
    var decodeJson = json.decode(result.body);
    var consolidateWeather = decodeJson["consolidated_weather"];
    var data = consolidateWeather[0];

    temperature = data["the_temp"].round();
    weather = data["weather_state_name"].replaceAll(" ", "").toLowerCase();
    abbr = data["weather_state_abbr"];
    setState(() {});
  }

  void onTextFieldSubmitted(String value) {
    getSearch(value);
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage(
              "assets/images/$weather.png",
            ),
            fit: BoxFit.cover),
      ),
      child: Scaffold(

        backgroundColor: Colors.transparent,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(

              child:  Icon(Icons.add_location),

              onPressed: () {
                getGeolocation();
                //var pos = (currentLocation == null ? 'Unknown' : currentLocation.latitude.toString() + ',' + currentLocation.longitude.toString());
                //onGeoButtonClick(pos);

              },

            ),
            Row( children: [
              Text(
                (currentLocation != null ? "Latitude: "+currentLocation.latitude.toString() : ""),
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              Text(
                (currentLocation != null ? "Longitude: "+ currentLocation.longitude.toString() : ""),
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],),

            Column(
              children: [
                Center(
                  child: Image.network(
                    "https://www.metaweather.com/static/img/weather/png/$abbr.png",
                    height: 80.0,

                  ),
                ),
                Center(
                  child: Text(
                    temperature.toString() + "°C",
                    style: TextStyle(
                      fontSize: 60.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    cityName ?? "",
                    style: TextStyle(
                        fontSize: 40.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: TextField(
                    onSubmitted: (String value) {
                      onTextFieldSubmitted(value);
                    },
                    style: TextStyle(color: Colors.white, fontSize: 25.0),
                    decoration: InputDecoration(
                      hintText: "Buscar otra ciudad...",
                      hintStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black87)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _PositionItemType {
  permission,
  position,
}

class _PositionItem {
  _PositionItem(this.type, this.displayValue);

  final _PositionItemType type;
  final String displayValue;
}