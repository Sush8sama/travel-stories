import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// root widget of your application
const title = 'travel stories';



// "operating system" of your application --> defines global configurations
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _longitude = 0;
  double _latitude = 0;
  DateTime _timestamp = DateTime.now();
  double _altitude = 0;



  Future _updatePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
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
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    var position =  await Geolocator.getCurrentPosition();

    setState(() {
      _longitude = position.longitude;
      _latitude = position.latitude;
      _timestamp = position.timestamp;
      _altitude = position.altitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Press to track location'),
            Text('Longitude: $_longitude'),
            Text('Latitude: $_latitude'),
            Text('Timestamp: $_timestamp'),
            Text('Altitude: $_altitude')
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updatePosition,
        tooltip: 'Position',
        child: const Icon(Icons.add),
      ),
    );
  }
}
