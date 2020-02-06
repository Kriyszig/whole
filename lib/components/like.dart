import 'package:flutter/material.dart';

class Like extends StatefulWidget {
  @override
  State<Like> createState() => LikeState();
}

class LikeState extends State<Like> {
  Color _buttonColor = Colors.blue;
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            child: Icon(
              Icons.favorite,
              color: _buttonColor
            ),
            onTap: () {
              setState(() {
                if(_enabled)
                  _buttonColor = Colors.blue;
                else
                  _buttonColor = Colors.pink;

                _enabled = !_enabled;
              });
            },
          )
        ]
      ),
    );
  }
}