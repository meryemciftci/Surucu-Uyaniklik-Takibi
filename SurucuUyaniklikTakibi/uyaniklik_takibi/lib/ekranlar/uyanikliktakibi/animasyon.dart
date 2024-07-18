import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uyaniklik_takibi/main.dart';
import 'tespit.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Position _konum;
  String? _sokak;
  String? _mahalle;
  String? _ilce;
  String? _il;
  String? _ulke;
  String? _kapiNo;
  String? _enlem;
  String? _boylam;




  void _konumAl() async {
    try{
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _konum = position;
      });
      // Koordinatları kullanarak adresi alma
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // İlk adresi alma
      Placemark placemark = placemarks.first;
      setState(() {
        _sokak = placemark.street;
        _mahalle = placemark.subLocality;
        _ilce = placemark.subAdministrativeArea;
        _il = placemark.administrativeArea;
        _ulke = placemark.country;
        _kapiNo = placemark.subThoroughfare;
        _enlem = position.latitude.toStringAsFixed(6);
        _boylam = position.longitude.toStringAsFixed(6);
      });

      showDialog(context: context,
          builder: (BuildContext context){
        return AlertDialog(
          title: Text('Konum Bilgisi'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Adres: $_sokak'),
                Text('Mahalle: $_mahalle'),
                Text('Kapı No: $_kapiNo'),
                Text('İlçe: $_ilce'),
                Text('İl: $_il'),
                Text('Ülke: $_ulke'),
                Text('Enlem: $_enlem'),
                Text('Boylam: $_boylam'),
                
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tamam'),
              onPressed: (){
                Navigator.of(context).pop();
              },
            )
          ],
          
        );
        
          });
    } catch (e) {
      print("Konum alınırken bir hata oluştu: $e");
    }
    }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1DB8EF),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 15.0, left: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                    alignment: Alignment.centerLeft,
                    child: CircleAvatar(
                      backgroundImage: AssetImage("assets/SürücüGözü.png"),
                    )),
                Container(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.logout),
                    color: Colors.white,
                    onPressed: () {
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      auth
                          .signOut()
                          .then((value) => Navigator.of(context)
                              .pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) => MyApp()),
                                  (route) => false))
                          .catchError((err) {
                        print("Error occured $err");
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.0),
          Padding(
            padding: EdgeInsets.only(left: 40.0),
            child: Row(
              children: <Widget>[
                Text('Uyanıklık',
                    style: TextStyle(
                        fontFamily: 'LexendDeca',
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 30.0)),
                SizedBox(width: 10.0),
                Text('Takibi',
                    style: TextStyle(
                        fontFamily: 'LexendDeca',
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontSize: 30.0))
              ],
            ),
          ),
          SizedBox(height: 40.0),
          Container(
            height: MediaQuery.of(context).size.height - 185.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(75.0)),
            ),
            child: ListView(
              primary: false,
              padding: EdgeInsets.only(left: 25.0, right: 20.0),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Center(
                    child: Text(
                      "Takibe başlayın...",
                      style: TextStyle(
                        fontFamily: "LexendDeca",
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Container(
                      height: MediaQuery.of(context).size.height - 350.0,
                      child: Lottie.asset("assets/lottie/meditation.json"),
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const Detection()));
                      },
                      child: Container(
                          height: 65.0,
                          width: 120.0,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey,
                                  style: BorderStyle.solid,
                                  width: 1.0),
                              borderRadius: BorderRadius.circular(10.0),
                              color: Color(0xFF1C1428)),
                          child: Center(
                              child: Icon(
                            Icons.camera,
                            size: 35.0,
                            color: Colors.white,
                          ))),
                    ),
                    InkWell(
                      onTap:_konumAl,
                      child:Container(
                        height: 65.0,
                        width:120.0,
                        decoration: BoxDecoration(
                          border:Border.all(
                            color: Colors.grey,
                            style: BorderStyle.solid,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                          color:Color(0xFF1C1428),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.location_on,
                            size:35.0,
                            color: Colors.white,
                          ),
                        ),
                      )

                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
