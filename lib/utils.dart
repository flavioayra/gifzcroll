import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

const BACKEND_DEV = "http://192.168.15.13:5000/gifzcroll/us-central1";
const BACKEND_PROD = "https://us-central1-gifzcroll.cloudfunctions.net";
const BACKEND = BACKEND_PROD;

class Gif {
  String url;
  bool isFav;
  String favId;

  Gif(String url, bool isFav, String favId) {
    this.url = url;
    this.isFav = isFav;
    this.favId = favId;
  }
}

Future<List<Gif>> fetchGifs(String mood) async {
  List<Gif> gifs = [];

  print("Getting $mood");
  final response = await http.get("$BACKEND/gifzMood?mood=$mood");

  if (response.statusCode == 200) {
    json.decode(response.body).forEach((r) {
      gifs.add(new Gif(r, false, null));
    });

    return gifs;
  }

  return [];
}

Future<List<Gif>> fetchFavs() async {
  List<Gif> gifs = [];

  print("Getting favs");
  final response = await http.get("$BACKEND_PROD/favs");

  if (response.statusCode == 200) {
    json.decode(response.body).forEach((r) {
      gifs.add(new Gif(r['url'], true, r['id']));
    });

    return gifs;
  }

  return [];
}

Future<void> shareGif(BuildContext context, url, isSharing) async {
  if (!isSharing) {
    //setState(() => isSharing = true);
    isSharing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => new Center(
            child: new CircularProgressIndicator(),
          ),
    );

    var request = await HttpClient().getUrl(Uri.parse(url));
    var response = await request.close();
    Uint8List bytes = await consolidateHttpClientResponseBytes(response);

    Navigator.pop(context); //pop dialog

    await Share.file('gifz', 'gifzcroll.gif', bytes, 'image/gif');

    // setState(() => isSharing = false);
    isSharing = false;
  }
}

Future<void> unfavGif(BuildContext context, id) async {
  showGeneralDialog(
      // barrierColor: Colors.black.withOpacity(0.5),
      transitionBuilder: (context, a1, a2, widget) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(
            opacity: a1.value,
            child: new Center(
              child:
                  Icon(Icons.favorite_border, size: 100.0, color: Colors.red),
            ),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 100),
      barrierDismissible: false,
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) {});

  await http.get("$BACKEND_PROD/unfav?id=$id");

  Navigator.pop(context); //pop dialog
}

Future<String> favGif(BuildContext context, url) async {
  showGeneralDialog(
      // barrierColor: Colors.black.withOpacity(0.5),
      transitionBuilder: (context, a1, a2, widget) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(
            opacity: a1.value,
            child: new Center(
              child: Icon(Icons.favorite, size: 100.0, color: Colors.red),
            ),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 100),
      barrierDismissible: false,
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) {});

  final response = await http.get("$BACKEND_PROD/fav?url=$url");

  Navigator.pop(context); //pop dialog

  String docId;
  if (response.statusCode == 200) {
    docId = response.body;
  }

  print(docId);
  return docId;
}
