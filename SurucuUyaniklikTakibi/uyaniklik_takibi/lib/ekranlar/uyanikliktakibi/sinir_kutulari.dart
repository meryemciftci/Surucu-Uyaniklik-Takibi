import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:background_sms/background_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class BoundaryBox extends StatefulWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;

  BoundaryBox(
      this.results, this.previewH, this.previewW, this.screenH, this.screenW);

  @override
  _BoundaryBoxState createState() => _BoundaryBoxState();
}

class _BoundaryBoxState extends State<BoundaryBox> {
  late Timer _timer;
  bool isPlaying = false;
  bool _isSMSsent = false;
  int _closedEyesDuration = 0;
  int _openEyesDuration = 0;
  int _thresholdDuration = 2; // Gözlerin kapalı olduğu kabul edilen süre (saniye)
  int _openEyesThresholdDuration = 2; // Gözlerin açık olduğu kabul edilen süre (saniye)
  //double speedThresholdKmh = 20; // Hız eşiği (km/h)

  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  late StreamSubscription<Position> _positionStreamSubscription;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initPermissions(); // İzinleri kontrol etmek için fonksiyonu çağırma
    _startLocationUpdates(); // Konum güncellemelerini başlatma
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_currentPosition != null){//(_currentPosition!.speed * 3.6) > speedThresholdKmh) {
        if (widget.results.isNotEmpty &&
            widget.results[0]["label"] == '0 Closed' &&
            (widget.results[0]["confidence"] * 100 > 85)) {
          _closedEyesDuration++;
          _openEyesDuration = 0; // Gözler açık süresini sıfırlama
          if (!isPlaying &&
              _closedEyesDuration >= _thresholdDuration &&
              !_isSMSsent) {
            _ringtonePlayer.play(fromAsset: "assets/alarm.wav");
            // Belirli süre boyunca gözler kapalıysa ve SMS daha önce gönderilmediyse, alarmı çal ve belirli bir süre sonra SMS gönder
            Future.delayed(Duration(seconds: 3), () {
              if (!isPlaying) return; // Alarm durdurulmuşsa SMS gönderme
              sendSMSWithLocation();
            });
            isPlaying = true;
          }
        } else {
          _openEyesDuration++;
          if (_openEyesDuration >= _openEyesThresholdDuration) {
            if (isPlaying) {
              // Gözler belirli süre açıksa ve bildirim sesi çalıyorsa, durdur
              _ringtonePlayer.stop();
              isPlaying = false;
            }
          }
          _closedEyesDuration = 0; // Gözler açıksa, kapalı süreyi sıfırla
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
    _ringtonePlayer.stop(); // Bildirim sesini durdur
    isPlaying = false;
    _positionStreamSubscription.cancel(); // Konum güncellemelerini durdur
  }

  void _initPermissions() async {
    // İzinleri isteme
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.location,
    ].request();
    // İzin durumlarını kontrol etme
    if (!statuses.containsValue(PermissionStatus.granted)) {
      // Kullanıcı izin vermediyse, bir uyarı gösterme
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gerekli izinler verilmedi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startLocationUpdates() {
    // Platforma özel konum ayarlarını belirleme
    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,  // Konum güncellemeleri arasındaki minimum mesafe
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 1),  // Güncelleme aralığı
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Uygulama konumunuzu arka planda almaya devam edecek",
          notificationTitle: "Arka Planda Çalışıyor",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 10,  // Konum güncellemeleri arasındaki minimum mesafe
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,  // Konum güncellemeleri arasındaki minimum mesafe
      );
    }

    // Konum güncellemeleri
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(
              (Position? position) {
            setState(() {
              _currentPosition = position;
            });
            if (position != null) {
              print("Güncellenen hız: ${position.speed} m/s");
              print("Güncellenen hız: ${position.speed * 3.6} km/h");
            }
          },
        );
  }

  void sendSMSWithLocation() async {
    if (_currentPosition == null) return;

    try {
      // Adresi alma
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // İlk adresi alma
      Placemark placemark = placemarks.first;
      String address =
          "${placemark.street}, ${placemark.subThoroughfare}, ${placemark.subLocality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea}, ${placemark.country}";

      // Hızı km/s cinsine çevirme
      String speedKmh = (_currentPosition!.speed * 3.6).toStringAsFixed(2);

      // Enlem ve boylam bilgilerini ekleme
      String latitude = _currentPosition!.latitude.toStringAsFixed(6);
      String longitude = _currentPosition!.longitude.toStringAsFixed(6);

      // SMS metnini oluşturma
      String message =
          "Tehlikeli durum ve şu anki konum: $address, Enlem: $latitude, Boylam: $longitude, Hız: $speedKmh km/h";

      // SMS gönderme fonksiyonunu çağırma
      sendSMS(message);

      // SMS gönderildiğinde, SMS gönderme durumunu güncelleme
      setState(() {
        _isSMSsent = true;
      });
    } catch (e) {
      print("Konum alınırken hata oluştu: $e");
    }
  }

  void sendSMS(String message) async {
    try {
      SmsStatus status = await BackgroundSms.sendMessage(
        phoneNumber: "+905469679687",
        message: message,
      );
      if (status == SmsStatus.sent) {
        print("Gönderildi");
        // Başarılı gönderim durumunda ekrana mesaj yazdırma
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMS başarıyla gönderildi.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print("Gönderilemedi");
        // Başarısız gönderim durumunda ekrana mesajı yazdırma
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMS gönderimi başarısız oldu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("SMS gönderilirken bir hata oluştu: $e");
      // Hata durumunda ekrana bir hata mesajı yazdır
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SMS gönderilirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.results.map<Widget>((re) {
        return Positioned(
          left: (widget.screenW / 4),
          bottom: -(widget.screenH - 80),
          width: widget.screenW,
          height: widget.screenH,
          child: Text(
            "${re["label"] == '0 Closed' ? "Gözler Kapalı" : "Gözler Açık"} ${(re["confidence"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              backgroundColor: Colors.white,
              color: re["label"] == '0 Closed' ? Colors.red : Colors.green,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}
