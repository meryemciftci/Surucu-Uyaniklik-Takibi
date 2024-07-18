import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uyaniklik_takibi/ekranlar/uyanikliktakibi//yuz_tespiti.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class Detection extends StatefulWidget {
  const Detection({super.key});
  @override
  _DetectionState createState() => _DetectionState();
}

final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

class _DetectionState extends State<Detection> {
  late bool _loading;
  List _outputs = [];
  File? _image;



  void initState() {
    super.initState();
    _loading = true;
    try {
      loadModel().then((value) {
        setState(() {
          _loading = false;
        });
        Navigator.push(context,
            MaterialPageRoute(builder: (BuildContext context) {
          return FaceDetectionFromLiveCamera();
        }));
      });
    } catch (err) {
      print("Error occured $err");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant_drow.tflite",
      labels: "assets/label.txt",
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _loading
            ? Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              )
            : Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _image == null
                        ? Container()
                        : Image.file(_image!,
                            fit: BoxFit.cover,
                            height: MediaQuery.of(context).size.height * 0.6),
                    SizedBox(
                      height: 10,
                    ),
                    _outputs != null && _outputs.isNotEmpty  //ekledim
                        ? Column(
                            children: <Widget>[
                              Text(
                                _outputs[0]["label"] == '0 Closed'
                                    ? "Gözler Kapalı"
                                    : "Gözler Açık",
                                style: TextStyle(
                                  color: _outputs[0]["label"] == '0 Closed'
                                      ? Colors.red
                                      : Colors.green,
                                  fontSize: 25.0,
                                ),
                              ),
                              Text(
                                "${(_outputs[0]["confidence"] * 100).toStringAsFixed(0)}%",
                                style: TextStyle(
                                    color: Colors.purpleAccent, fontSize: 20
                                ),
                              ),

                            ],

                          )
                        : Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                // here
                              ],
                            ),
                          )
                  ],
                ),
              ));
  }
}
