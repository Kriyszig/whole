import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class Report extends StatefulWidget {
  final CameraPosition reportPosition;
  final dynamic setExternalState;
  final List<Marker> reportMarker;
  final bool previouslyExists;
  final bool closeIssue;
  Report({this.reportPosition, this.setExternalState, this.reportMarker, this.previouslyExists, this.closeIssue});

  @override
  State<Report> createState() => ReportState();
}

class ReportState extends State<Report> {
  String _headline = '';
  String _description = '';
  TextEditingController _headlineController;
  TextEditingController _descriptionController;
  FocusNode _headlineFocus;
  FocusNode _descriptionFocus;
  File _image;
  bool inProgress = false;
  String _progressText = '';

  Future<void> _getImageFromCamera() async {
    _headlineFocus.unfocus();
    _descriptionFocus.unfocus();
    File image = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = image;
    });
  }

  Future<void> _getImageFromGallery() async {
    _headlineFocus.unfocus();
    _descriptionFocus.unfocus();
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  void _resetImage() {
    setState(() {
      _image = null;
    });
  }

  Future<String> _putImageInStorage() async {
    if(_image == null)
      return '';
    
    setState(() {
      _progressText = 'Uploading Image File';
    });

    final _trimmedHeadline = _headline.replaceAll(new RegExp(r' '), '');
    final String imgUid = '${widget.reportPosition.target.latitude}${widget.reportPosition.target.longitude}$_trimmedHeadline';
    final StorageReference ref = FirebaseStorage.instance.ref().child(imgUid).child("image.jpg");
    final StorageUploadTask uploadTask = ref.putFile(_image);
    final StorageTaskSnapshot onCompleteUpload = await uploadTask.onComplete;
    return await onCompleteUpload.ref.getDownloadURL();
  }

  Future<int> _submitToDatabase() async {
    if(_headline.length == 0 || _description.length == 0)
      return -1;

    setState(() {
      inProgress = true;
    });
    
    final String uploadedImageLink = await _putImageInStorage();
    
    final DocumentReference postRef = Firestore.instance.document('reportshack/${widget.reportPosition.target.latitude}_${widget.reportPosition.target.longitude}');

    setState(() {
      _progressText = 'Updating Database';
    });

    DocumentSnapshot postSnapshot = await postRef.get();
    if (widget.previouslyExists && !widget.closeIssue) {
      Map<String, dynamic> content = postSnapshot.data;
      content[_headline] = <String>[_description, uploadedImageLink];
      postRef.setData(content);
    } else {
      Map<String, dynamic> content = <String, dynamic>{};
      content[_headline] = <String>[_description, uploadedImageLink];
      Firestore.instance.document('reportshack/${widget.reportPosition.target.latitude}_${widget.reportPosition.target.longitude}').setData(content);

      final Map<String, dynamic> setMarker = <String, dynamic>{
        'latitude': widget.reportPosition.target.latitude,
        'longitude': widget.reportPosition.target.longitude,
        'status': widget.closeIssue,
        'count': 0,
      };
      await Firestore.instance.document('markershack/${widget.reportPosition.target.latitude}_${widget.reportPosition.target.longitude}').setData(setMarker);
    }

    if(widget.previouslyExists)
      await widget.setExternalState(_headline, _description, uploadedImageLink);
    else
      await widget.setExternalState();
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _headlineController = TextEditingController();
    _descriptionController = TextEditingController();
    _headlineFocus = FocusNode();
    _descriptionFocus = FocusNode();
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _descriptionController.dispose();
    _headlineFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (inProgress) ?
      Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.blue,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(
              backgroundColor: Colors.white,
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Text(
                _progressText,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            )
          ],
        ),
      )
    :
      Scaffold(
        appBar: AppBar(
          title: Text(
            'Report',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blue,
        ),
        body: ListView(
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: MediaQuery.of(context).size.width,
              child: GoogleMap(
                mapType: MapType.normal,
                markers: Set<Marker>.of(widget.reportMarker),
                initialCameraPosition: widget.reportPosition,
                rotateGesturesEnabled: false,
                scrollGesturesEnabled: false,
                tiltGesturesEnabled: false,
                zoomGesturesEnabled: false,    
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue,
                  width: 4,
                ),
              ),
              padding: EdgeInsets.all(5),
            ),
            Container(
              padding: EdgeInsets.all(5),
              child: TextField(
                focusNode: _headlineFocus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  labelText: "Headline",
                  labelStyle: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                controller: _headlineController,
                onChanged: (String text) {
                  setState(() {
                    _headline = text;
                  });
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                focusNode: _descriptionFocus,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  labelText: "Description",
                  labelStyle: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                controller: _descriptionController,
                onChanged: (String text) {
                  setState(() {
                    _description = text;
                  });
                },
              ),
            ),
            Visibility(
              visible: _image == null,
              child: Container(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FlatButton(
                      child: Icon(
                        Icons.camera,
                        color: Colors.white,
                      ),
                      color: Colors.blue,
                      onPressed: _getImageFromCamera,
                    ),
                    FlatButton(
                      child: Icon(
                        Icons.photo,
                        color: Colors.white,
                      ),
                      color: Colors.blue,
                      onPressed: _getImageFromGallery,
                    ),
                  ],
                )
              ),
            ),
            Visibility(
              visible: _image != null,
              child: Container(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FlatButton(
                      child: Text(
                        'Image Selected\nClick to Choose Another Image',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      color: Colors.blue,
                      onPressed: _resetImage,
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    ),
                  ],
                )
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(
            Icons.play_arrow,
            color: Colors.white,
          ),
          backgroundColor: Colors.blue,
          onPressed: () async {
            final int result = await _submitToDatabase();
            if(result == 0)
              Navigator.of(context).pop();
          },
        ),
      );
  }
}
