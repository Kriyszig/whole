import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './pages/report.dart';
import './pages/details.dart';
import './pages/login.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: Hole(),
    );
  }
}

class Hole extends StatefulWidget {
  @override
  State<Hole> createState() => HoleState();
}

class HoleState extends State<Hole> {
  Completer<GoogleMapController> _controller = Completer();
  Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  List<DocumentSnapshot> _markersDB =  <DocumentSnapshot>[];
  bool _loggedIn = false;
  bool _sudo = false;
  bool _closeIssue = false;

  void _addMarkers(LatLng newLocation, double hue) {
    final String reportId = '${newLocation.latitude}${newLocation.longitude}';
    final MarkerId id =
        MarkerId(reportId);
        
    final Marker _newAddition = Marker(
      markerId: id,
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      position: newLocation,
      onTap: () {
        if(_closeIssue && hue == BitmapDescriptor.hueYellow)
          return;
        
        if(!_closeIssue) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => Detail(
                reportId: newLocation,
                closed: hue == BitmapDescriptor.hueGreen,
                reopen: () async {
                  final QuerySnapshot qs = await Firestore.instance.collection('markershack').getDocuments();
                  setState(() {
                    _markersDB = qs.documents;
                  });
                  _addMarkers(newLocation, BitmapDescriptor.hueRed);
                },
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                Offset begin = Offset(1.0, 0.0);
                Offset end = Offset.zero;
                Curve curve = Curves.decelerate;

                Animatable<Offset> tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                  
                );
              },
            ),
          );
        } else {
          final Marker _newAddition = Marker(
            markerId: id,
            position: newLocation,
          );

          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => Report(
                reportPosition: CameraPosition(
                  target: newLocation,
                  zoom: 17,
                ),
                reportMarker: <Marker>[
                  _newAddition,
                ],
                previouslyExists: false,
                setExternalState: () async {
                  setState(() {
                    _closeIssue = false;
                  });
                  final QuerySnapshot qs = await Firestore.instance.collection('markershack').getDocuments();
                  setState(() {
                    _markersDB = qs.documents;
                  });
                  _addMarkers(newLocation, BitmapDescriptor.hueGreen);
                },
                closeIssue: _closeIssue,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                Offset begin = Offset(1.0, 0.0);
                Offset end = Offset.zero;
                Curve curve = Curves.decelerate;

                Animatable<Offset> tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                  
                );
              },
            ),
          );
        }
      },
    );

    setState(() {
      _markers[id] = _newAddition;
    });
  }

  void _addNewReport(LatLng reportPosition) {
    final String reportId = '${reportPosition.latitude}${reportPosition.longitude}';
    final MarkerId id =
        MarkerId(reportId);
        
    final Marker _newAddition = Marker(
      markerId: id,
      position: reportPosition,
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Report(
          reportPosition: CameraPosition(
            target: reportPosition,
            zoom: 17,
          ),
          reportMarker: <Marker>[
            _newAddition,
          ],
          previouslyExists: false,
          setExternalState: () async {
            final QuerySnapshot qs = await Firestore.instance.collection('markershack').getDocuments();
            setState(() {
              _markersDB = qs.documents;
            });
            _addMarkers(reportPosition, BitmapDescriptor.hueRed);
          },
          closeIssue: _closeIssue,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          Offset begin = Offset(1.0, 0.0);
          Offset end = Offset.zero;
          Curve curve = Curves.decelerate;

          Animatable<Offset> tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  static final CameraPosition _goaTop = CameraPosition(
    target: LatLng(15.3751094, 74.0663112),
    zoom: 9.75,
  );

  @override
	void initState(){
		super.initState();
    Firestore.instance.collection('markershack').getDocuments().then((QuerySnapshot qs) {
      List<DocumentSnapshot> markers =  qs.documents;
      setState(() {
        _markersDB = markers;
      });
      for(int i = 0 ; i < markers.length; ++i) {
        Map<String, dynamic> currentDocumentData = markers[i].data;
        final double latitude = currentDocumentData['latitude'];
        final double longitude = currentDocumentData['longitude'];
        final bool status = currentDocumentData['status'];

        final LatLng reportLocation = LatLng(latitude, longitude);
        final double hue = (status)? BitmapDescriptor.hueGreen: BitmapDescriptor.hueRed;

        _addMarkers(reportLocation, hue);
      }
    });
	}

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              child: Center(
                child: Column(
                  children: <Widget>[
                    Text(
                      'Hole',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Making the roads whole again',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: !_loggedIn,
              child: FlatButton(
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(
                        setSuperState: (bool setSudo) {
                          setState(() {
                            _loggedIn = true;
                            _sudo = setSudo;
                          });
                        },  
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        Offset begin = Offset(1.0, 0.0);
                        Offset end = Offset.zero;
                        Curve curve = Curves.decelerate;

                        Animatable<Offset> tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Visibility(
              visible: !_closeIssue && _loggedIn && _sudo,
              child: FlatButton(
                child: Text(
                  'Close Issues',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _closeIssue = true;
                    _markers = <MarkerId, Marker>{};
                    for(int i = 0 ; i < _markersDB.length; ++i) {
                      Map<String, dynamic> currentDocumentData = _markersDB[i].data;
                      final double latitude = currentDocumentData['latitude'];
                      final double longitude = currentDocumentData['longitude'];
                      final bool status = currentDocumentData['status'];

                      final LatLng reportLocation = LatLng(latitude, longitude);
                      final double hue = (!status)? BitmapDescriptor.hueGreen: BitmapDescriptor.hueYellow;

                      _addMarkers(reportLocation, hue);
                    }
                  });
                },
              ),
            ),
            Visibility(
              visible: _closeIssue,
              child: FlatButton(
                child: Text(
                  'Report Issues',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _closeIssue = false;
                    _markers = <MarkerId, Marker>{};
                    for(int i = 0 ; i < _markersDB.length; ++i) {
                      Map<String, dynamic> currentDocumentData = _markersDB[i].data;
                      final double latitude = currentDocumentData['latitude'];
                      final double longitude = currentDocumentData['longitude'];
                      final bool status = currentDocumentData['status'];

                      final LatLng reportLocation = LatLng(latitude, longitude);
                      final double hue = (status)? BitmapDescriptor.hueGreen: BitmapDescriptor.hueRed;

                      _addMarkers(reportLocation, hue);
                    }
                  });
                },
              ),
            ),
            FlatButton(
              child: Text(
                'Emergency',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => null,
            ),
            Visibility(
              visible: _loggedIn,
              child: FlatButton(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _loggedIn = false;
                    _sudo = false;
                    _closeIssue = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        markers: Set<Marker>.of(_markers.values),
        initialCameraPosition: _goaTop,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        onLongPress: _addNewReport,
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              onPressed: _goToGoa,
              child: Icon(
                Icons.zoom_out_map,
              ),
              backgroundColor: Colors.blue,
            ),
          ),

          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              width: 100,
              height: 60,
              child: Center(
                child:Text(
                  'Long press at a point to report a new issue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToGoa() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_goaTop));
  }
}
