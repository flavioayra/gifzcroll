import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:my_app/custom_icons_icons.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:rect_getter/rect_getter.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:giphy_client/giphy_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:transparent_image/transparent_image.dart';

const BACKEND_DEV = "http://192.168.15.13:5000/gifzcroll/us-central1";
const BACKEND_PROD = "https://us-central1-gifzcroll.cloudfunctions.net";
const BACKEND = BACKEND_PROD;

void main() => runApp(Gifzcroll());

class Gifzcroll extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // hide status bar
    SystemChrome.setEnabledSystemUIOverlays([]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

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

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Gif> imgs = new List();
  ScrollController _scrollController;
  bool isPerformingRequest = false;
  bool isSharing = false;
  String mood = "funny";
  var listViewKey = RectGetter.createGlobalKey();
  var _keys = {};
  final client = new GiphyClient(apiKey: 'dc6zaTOxFJmzC');
  final FocusScopeNode _focusScopeNode = new FocusScopeNode();
  OverlayEntry moodTextBox;

  @override
  void initState() {
    super.initState();
    _scrollController = new ScrollController();

    fetchGifs();

    _scrollController.addListener(() {
      if (!isPerformingRequest) {
        // // Get last visible listItem
        var rect = RectGetter.getRectFromKey(listViewKey);
        int lastItem = 0;
        _keys.forEach((index, key) {
          var itemRect = RectGetter.getRectFromKey(key);
          if (itemRect != null &&
              !(itemRect.top > rect.bottom || itemRect.bottom < rect.top) &&
              index > lastItem) lastItem = index;
        });

        if ((imgs.length - lastItem) < 10) {
          var diff = imgs.length - lastItem;
          print("Pegando mais $diff");
          fetchGifs();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Widget _buildProgressIndicator() {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Center(
        child: new Opacity(
          opacity: isPerformingRequest ? 1.0 : 0.0,
          child: new CircularProgressIndicator(),
        ),
      ),
    );
  }
  
  bool notNull(Object o) => o != null;
  Widget buildBody() {
    return RectGetter(
      key: listViewKey,
      child: ListView.builder(
        // FUCK YOU STATUS BAR
        padding: EdgeInsets.zero,

        controller: _scrollController,
        itemCount: imgs.length,
        itemBuilder: (BuildContext context, int index) {
          _keys[index] = RectGetter.createGlobalKey();

          if (index == imgs.length) {
            return _buildProgressIndicator();
          } else {
            return RectGetter(
              key: _keys[index],
              child: Container(
                child: GestureDetector(
                  onTap: () {
                    print('tap');
                    shareGif(imgs[index].url);
                  },
                  onDoubleTap: () {
                    print('double tap');
                    if (imgs[index].isFav) {
                      print('unfaving '+imgs[index].favId);
                      unfavGif(imgs[index].favId);
                    } else {
                      print('faving '+imgs[index].url);
                      favGif(imgs[index].url);
                    }
                  },
                  child: new Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                  
                      // new FadeInImage.memoryNetwork(
                      //   fadeInDuration: Duration(milliseconds: 0),
                      //   placeholder: kTransparentImage,
                      //   image: imgs[index].url, fit: BoxFit.fitWidth
                      // ),
                  
                      new CachedNetworkImage(
                        imageUrl: imgs[index].url,
                        fit: BoxFit.fitWidth,
                      ),
                  
                      imgs[index].isFav ? new Positioned(
                        right: -1.0,
                        top: 2.0,
                        child: new Icon(Icons.favorite, color: Colors.red),
                      ) : new Container()     
                    ]
                ),
              ),
            ),
            );
          }
        },
      ),
    );
  }

  Widget buildSpeedDialMood() {
    return Opacity(
        opacity: 0.8,
        child: new SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          overlayColor: Colors.black,
          overlayOpacity: 0.3,
          backgroundColor: Colors.black,
          visible: true,
          curve: Curves.bounceIn,
          children: [
            SpeedDialChild(
              child: Icon(Icons.favorite, color: Colors.white),
              backgroundColor: Colors.black,
              onTap: () => fetchFavs()
            ),
            SpeedDialChild(
              child: Icon(Icons.accessibility_new, color: Colors.white),
              backgroundColor: Colors.black,
              onTap: () => setMood("excited"),
            ),
            SpeedDialChild(
              child: Icon(
                  CustomIcons.iconfinder_middle_finger_gesture_fuck_339875,
                  color: Colors.white),
              backgroundColor: Colors.black,
              onTap: () => setMood("fuck"),
            ),
            SpeedDialChild(
                child: Icon(Icons.beach_access, color: Colors.white),
                backgroundColor: Colors.black,
                onTap: () => setMood("beach")),
            SpeedDialChild(
              child: Icon(Icons.audiotrack, color: Colors.white),
              backgroundColor: Colors.black,
              onTap: () => setMood("dance"),
            ),
            SpeedDialChild(
              child: Icon(Icons.child_care, color: Colors.white),
              backgroundColor: Colors.black,
              onTap: () => setMood("kids"),
            ),
            SpeedDialChild(
              child: Icon(Icons.directions_bike, color: Colors.white),
              backgroundColor: Colors.black,
              onTap: () => setMood("bikes"),
            ),
            SpeedDialChild(
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: Colors.black,
              onTap: () => showMoodText(),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: buildBody(),
        floatingActionButton: buildSpeedDialMood(),
    );
  }

  Widget textOverlay() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 200, maxHeight: 200),
        child: FocusScope(
          node: _focusScopeNode,
          child: Builder(
            builder: (BuildContext context) {
              return Material(
                type: MaterialType.canvas,
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'What do you wanna see?',
                    fillColor: Colors.black,
                    filled: true,
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(),
                    ),
                  ),
                  style: new TextStyle(
                    color: Colors.white,
                  ),
                  onSubmitted: setMoodFromText,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void showMoodText() {
    if (moodTextBox == null) {
      moodTextBox =
          new OverlayEntry(builder: (BuildContext context) => textOverlay());
      Overlay.of(context).insert(moodTextBox);
    }
  }

  void setMoodFromText(mood) {
    moodTextBox.remove();
    moodTextBox = null;

    setMood(mood);
  }

  Future<void> shareGif(url) async {
    if (!isSharing) {
      setState(() => isSharing = true);

      showDialog (
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
      
      setState(() => isSharing = false);
    }
  }

  Future<void> favGif(url) async {
    if (!isSharing) {
      setState(() => isSharing = true);

      showDialog (
        context: context,
        barrierDismissible: false,
        builder: (_) => new Center(
          child: Icon(
                  Icons.favorite,
                  size: 100.0,
                  color: Colors.red),
          ),
      );
  
      await http.get("$BACKEND_PROD/fav?url=$url");

      Navigator.pop(context); //pop dialog

      // await Share.file('gifz', 'gifzcroll.gif', bytes, 'image/gif');
      
      setState(() => isSharing = false);
    }
  }

    Future<void> unfavGif(id) async {
    if (!isSharing) {
      setState(() => isSharing = true);

      showDialog (
        context: context,
        barrierDismissible: false,
        builder: (_) => new Center(
          child: Icon(
                  Icons.favorite_border,
                  size: 100.0,
                  color: Colors.red),
          ),
      );
  
      await http.get("$BACKEND_PROD/unfav?id=$id");

      Navigator.pop(context); //pop dialog
      
      setState(() => isSharing = false);
    }
  }

  void setMood(newMood) {
    setState(() => mood = newMood);

    // // Get last visible listItem (clean array after)
    // var rect = RectGetter.getRectFromKey(listViewKey);
    // int lastItem = 0;
    // _keys.forEach((index, key) {
    //   var itemRect = RectGetter.getRectFromKey(key);
    //   if (itemRect != null &&
    //       !(itemRect.top > rect.bottom || itemRect.bottom < rect.top) &&
    //       index > lastItem) lastItem = index;
    // });

    // Remove last visible+10 itens em fetch again
    // if (imgs != null && imgs.length != null && imgs.length > lastItem + 10) {
    //   imgs.removeRange(lastItem + 10, imgs.length);
    // }
    // fetchGifs();
  }

  Future<void> fetchFavs() async {
    
    if (!isPerformingRequest) {
      setState(() => isPerformingRequest = true);
      
      imgs.removeRange(0, imgs.length);
      
      // mood = mood.split('+')[0];
      print("Getting favs");
      final response = await http.get("$BACKEND_PROD/favs");

      if (response.statusCode == 200) {
        print(response.body);
        List results = json.decode(response.body);
        for (var i = 0; i < results.length; i++) {
          Gif gif = new Gif(results[i]['url'], true, results[i]['id']);
          imgs.add(gif);
        }
      }

      setState(() => isPerformingRequest = false);
    }
  }

  Future<void> fetchGifs() async {
    
    if (!isPerformingRequest) {
      setState(() => isPerformingRequest = true);
      
      // mood = mood.split('+')[0];
      print("Getting $mood");
      final response = await http.get("$BACKEND/gifzMood?mood=$mood");

      if (response.statusCode == 200) {
        print(response.body);
        List results = json.decode(response.body);
        for (var i = 0; i < results.length; i++) {
          // setState(() => imgs.add(results[i]));
          Gif gif = new Gif(results[i], false, null);
          imgs.add(gif);
        }
      }

      setState(() => isPerformingRequest = false);
    }
  }
}
