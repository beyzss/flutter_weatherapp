import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hava_durumu/models/weather_model.dart';

class WeatherService {
  Future<String?> _getLocation() async {
    //Kullanıcının konumu açık mı kontrol ettik
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Konum servisiniz kapalı");
    }

    //Kullanıcı konum izni vermiş mi kontrol ettik
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      //Konum izni verilmemişse tekrar izin istedik.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        //Yiner vermemişse hata döndürdük.
        throw Exception("Konum izni vermelisiniz");
      }
    }
    //Kullanıcının pozisyonunu alalım /high: kesin konum
    // ignore: deprecated_member_use
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // ignore: unused_local_variable
    //Kullanıcı pozisyonundan yerleşim noktasını bulduk.
    final List<Placemark> placemark =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    //Şehrimizi yerleşim noktasından kaydettik.
    final String? city = placemark[0].administrativeArea;

    if (city == null) throw Exception("Bir sorun oluştu");

    return city;
  }

  Future<List<WeatherModel>> getWeatherData() async {
    final String? city = await _getLocation();

    final String url =
        "https://api.collectapi.com/weather/getWeather?data.lang=tr&data.city=$city";

    const Map<String, dynamic> headers = {
      "authorization": "apikey 2XmxTOdBRrzJ8t1fUZFvRg:6aZbFG0XMkubUN5dYyuiju",
      "content-type": "application/json"
    };

    final dio = Dio();

    final response = await dio.get(url, options: Options(headers: headers));

    if (response.statusCode != 200) return Future.error("Bir sorun oluştu");

    final List list = response.data['result'];

    final List<WeatherModel> weatherList =
        list.map((e) => WeatherModel.fromJson(e)).toList();

    return weatherList;
  }
}
