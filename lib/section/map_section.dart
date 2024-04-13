import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:hans/service/h3.dart';
import 'package:intl/intl.dart';
import 'package:tekflat_design/tekflat_design.dart';

import 'dart:developer' as developer;

final dateFormat = DateFormat('yyyy-MM-dd hh:mm:ss');

class MapSection extends StatefulWidget {
  const MapSection({
    super.key,
  });
  @override
  State<StatefulWidget> createState() => _MapSection();
}

class _MapSection extends State<MapSection> {
  /*
  MapController mapController = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
    enableTracking: true,
    unFollowUser: false,
  ));
  */
  // default constructor
  MapController mapController = MapController.withUserPosition(
    trackUserLocation: const UserTrackingOption(
      enableTracking: true,
      unFollowUser: false,
    )
  );

  GeoPoint? _location;
  DateTime _now = DateTime.now();
  Timer? _timer;

  _MapSection();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      //GeoPoint? location = mapController.initPosition;
      developer.log("Looking for location");
      GeoPoint? location;
      try {
        //await mapController.currentLocation();
        location = await mapController.myLocation();
        await mapController.goToLocation(location);


        // time = Random().nextInt(100);
        var (BigInt h3Index, GeoPoint center) =
            H3.getH3Center(location);
        developer.log("center $center");
        developer.log("point $location");
        Color color = Colors.red;
        Color colorTime = Colors.blue;
        
        var boundaryList = h3.h3ToGeoBoundary(h3Index);
        var i = 0;
        for (i = 0; i < boundaryList.length; i++) {
          await mapController.drawCircle(CircleOSM(
            key: "${i}boundary",
            centerPoint: GeoPoint(
                latitude: boundaryList[i].lat, longitude: boundaryList[i].lon),
            radius: 1,
            color: Colors.black,
            strokeWidth: 10,
          ));
        }

        await mapController.drawCircle(CircleOSM(
          key: "1circle",
          centerPoint: location,
          radius: 3,
          color: colorTime,
          strokeWidth: 10,
        ));
        await mapController.drawCircle(CircleOSM(
          key: "circle$h3Index",
          centerPoint: center,
          radius: 5,
          color: color,
          strokeWidth: 10,
        ));
        await mapController.drawCircle(CircleOSM(
          key: "2circle",
          centerPoint: center,
          radius: 1,
          //borderColor: Colors.black,
          color: Colors.black,
          strokeWidth: 10,
        ));

        developer.log("location found");
      } catch (e, stacktrace) {
        developer.log("location error $e");
        developer.log(e.toString(), stackTrace: stacktrace);
      }
      setState(() {
        if (location != null) {
          _location = location;
        }

        _now = DateTime.now();
      });
    });
  }

  void _openPopUpShare(){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        var emailController = TextEditingController();
        var messageController = TextEditingController();
        return AlertDialog(
          alignment: Alignment.center,
          scrollable: false,
          title: const Text('Share'),
          content: SingleChildScrollView(
            child: Column(
              //shrinkWrap: true,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(hintText: 'Social Network 1'),
                  ),
                TextFormField(
                  controller: messageController,
                  decoration: const InputDecoration(hintText: 'Social Network 2'),
                  ),
                ],
              ),
            ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Copy Link'),
            ),
            TextButton(
              onPressed: () {
                // Send them to your email maybe?
                var email = emailController.text;
                var message = messageController.text;
                Navigator.pop(context);
              },
              child: Text('Send'),
            ),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      TekTypography(
          text:
              "${dateFormat.format(_now)}\nLongitude : ${_location?.longitude}\nLatitude ${_location?.latitude}"),
      SizedBox(
        height: 2*TekResponsiveConfig().currentWidth/3,
        width: TekResponsiveConfig().currentWidth/2,
        child: OSMFlutter(
            controller: mapController,
            osmOption: OSMOption(
              userTrackingOption: const UserTrackingOption(
                enableTracking: true,
                unFollowUser: false,
              ),
              zoomOption: const ZoomOption(
                initZoom: 18,
                minZoomLevel: 3,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.location_history_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.double_arrow,
                    size: 48,
                  ),
                ),
              ),
              roadConfiguration: const RoadOption(
                roadColor: Colors.yellowAccent,
              ),
              /* markerOption: MarkerOption(
                  defaultMarker: const MarkerIcon(
                icon: Icon(
                  Icons.person_pin_circle,
                  color: Colors.blue,
                  size: 56,
                ),
              )), */
            )),
        ),
        //Sharebutton
        TekVSpace.p18,
        TekButton(
          key: const Key('shareButton'),
          text: 'Share',
          width: double.infinity,
          type: TekButtonType.primary,
          onPressed: _openPopUpShare,
        ),
      ]
    );
  }
}
