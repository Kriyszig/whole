import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import './report.dart';
import '../components/like.dart';

class Detail extends StatefulWidget {
  final LatLng reportId;
  final bool closed;
  final dynamic reopen;
  Detail({this.reportId, this.closed, this.reopen});

  @override
  State<Detail> createState() => DetailState();
}

class DetailState extends State<Detail> {
  List<dynamic> _reportList = <dynamic>[];
  bool isProcessing = false;

  @override
	void initState(){
		super.initState();
    Firestore.instance.document('reportshack/${widget.reportId.latitude}_${widget.reportId.longitude}').get().then((DocumentSnapshot ds) {
      Map<String, dynamic> documentData = ds.data;
      documentData.forEach((String key, dynamic value) {
        List<String> reportListEntry = [key, value[0], value[1]]; 
        setState(() {
          _reportList.add(reportListEntry);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return (isProcessing)?
      Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.blue,
        child: Center(
          child: CircularProgressIndicator(
            backgroundColor: Colors.white,
          ),
        ),
      )
    :
      Scaffold(
        appBar: AppBar(
          title: Text(
            'Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Container(
          constraints: BoxConstraints(
            minHeight:  MediaQuery.of(context).size.height,
          ),
          child: ListView(
            children: _reportList.map((value) {
              final String title = value[0];
              final String description = value[1];
              final String imageUrl = (value.length > 2)? value[2]: '';

              return Container(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    (imageUrl.length > 0)?
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: Image(
                          image: NetworkImage(imageUrl),
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.contain,
                        ),
                      )
                    :
                      Container()
                    ,
                    Like(),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        description,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      height: 1,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.grey,
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        floatingActionButton: (widget.closed)?
          FloatingActionButton.extended(
            label: Text(
              'Reopen Issue',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            icon: Icon(
              Icons.open_in_new,
              color: Colors.white,
            ),
            backgroundColor: Colors.blue,
            onPressed: () async {
              setState(() {
                isProcessing = true;
              });
              final DocumentSnapshot ds = await Firestore.instance.document('markershack/${widget.reportId.latitude}_${widget.reportId.longitude}').get();
              Map<String, dynamic> snapshotData = ds.data;
              final int count = snapshotData['count'];
              snapshotData['count'] = (count + 1) % 10;
              if(count >= 9) {
                snapshotData['status'] = false;
              }

              await Firestore.instance.document('markershack/${widget.reportId.latitude}_${widget.reportId.longitude}').setData(snapshotData);
              if(count >= 9)
                await widget.reopen();

              Navigator.of(context).pop();
            }, 
          )
        :
          FloatingActionButton(
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
            backgroundColor: Colors.blue,
            onPressed: () async {
              final String reportId = '${widget.reportId.latitude}${widget.reportId.longitude}';
              final MarkerId id = MarkerId(reportId);
                  
              final Marker _newAddition = Marker(
                markerId: id,
                position: widget.reportId,
              );

              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => Report(
                    reportPosition: CameraPosition(
                      target: widget.reportId,
                      zoom: 17,
                    ),
                    reportMarker: <Marker>[
                      _newAddition,
                    ],
                    previouslyExists: true,
                    setExternalState: (String title, String description, String uri) {
                      List<String> reportListEntry = [title, description, uri]; 
                      setState(() {
                        _reportList.add(reportListEntry);
                      });
                    },
                    closeIssue: false,
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
          )
        ,
      )
    ;
  }
}