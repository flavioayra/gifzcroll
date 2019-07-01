import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:my_app/custom_icons_icons.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:rect_getter/rect_getter.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:giphy_client/giphy_client.dart';




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

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> imgs = new List();
  ScrollController _scrollController = new ScrollController();
  bool isPerformingRequest = false;
  bool isSharing = false;
  String mood = "funny";
  var listViewKey = RectGetter.createGlobalKey();
  var _keys = {};
//  final client = new GiphyClient(apiKey: '92BHZL1aODZwWOtLQRAdkYVq8aO6V0dj');
  final client = new GiphyClient(apiKey: 'dc6zaTOxFJmzC');


  @override
  void initState() {
    super.initState();
    fetchGifs();

    _scrollController.addListener(() {
      // Fetch more if in the middle of the shit
      if ((_scrollController.position.maxScrollExtent-_scrollController.position.pixels) < 1000) {
        fetchGifs();
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
                    shareImage(imgs[index]);
                  },
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: imgs[index], fit: BoxFit.fitWidth
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget buildSpeedDial() {
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
            child: Icon(Icons.accessibility_new, color: Colors.white),
            backgroundColor: Colors.black,
            onTap: () => setMood("excited+funny"),
          ),
          SpeedDialChild(
            child: Icon(CustomIcons.iconfinder_middle_finger_gesture_fuck_339875, color: Colors.white),
            backgroundColor: Colors.black,
            onTap: () => setMood("fuck+funny"),
          ),
          SpeedDialChild(
            child: Icon(Icons.beach_access, color: Colors.white),
            backgroundColor: Colors.black,
            onTap: () => setMood("beach+funny")
          ),
          SpeedDialChild(
            child: Icon(Icons.audiotrack, color: Colors.white),
            backgroundColor: Colors.black,
            onTap: () => setMood("dance+funny"),
          ),
          SpeedDialChild(
            child: Icon(Icons.child_care, color: Colors.white),
            backgroundColor: Colors.black,
            onTap: () => setMood("kids+funny"),
          ),
          SpeedDialChild(
            child: Icon(Icons.directions_bike, color: Colors.white),
            backgroundColor: Colors.black,
            onTap: () => setMood("bikes+funny"),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: buildBody(),
      floatingActionButton: buildSpeedDial(),
    );
  }

  shareImage(url) async {
    if (!isSharing) {
      setState(() => isPerformingRequest = true);
      var request = await HttpClient().getUrl(Uri.parse(url));
      var response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      await Share.file('gifz', 'gifzcroll.gif', bytes, 'image/gif');
      setState(() => isPerformingRequest = false);
    }
  }

  setMood(newMood) {
    setState(() => mood = newMood);

    // Get last visible listItem (clean array after)
    var rect = RectGetter.getRectFromKey(listViewKey);
    int lastItem = 0;
    _keys.forEach((index, key) {
      var itemRect = RectGetter.getRectFromKey(key);
      if (itemRect != null && !(itemRect.top > rect.bottom || itemRect.bottom < rect.top) && index > lastItem) lastItem = index;
    });

    // Remove last visible +2 itens em fetch again
    imgs.removeRange(lastItem+2, imgs.length);
    fetchGifs();
  }

  fetchGifs() async {

    if (!isPerformingRequest) {
      setState(() => isPerformingRequest = true);
      mood = mood.split('+')[0];
      var endpoint = 'https://api.tenor.com/v1/random?q=${mood}&key=LIVDSRZULELA&limit=0&media_filter=minimal&contentfilter=off&anon_id=3a76e56901d740da9e59ffb22b988242';
      print(endpoint);
      final response = await http.get(endpoint);
      if (response.statusCode == 200) {
        List results = json.decode(response.body)['results'];

        for (var i = 0; i < results.length; i++) {
          print(results[i]['media'][0]['gif']['url']);
          setState(() => imgs.add(results[i]['media'][0]['gif']['url']));
        }
        setState(() => isPerformingRequest = false);
      } else {
        setState(() => isPerformingRequest = false);
        throw Exception('Ooops. no imgs');
      }
    }

    // if (!isPerformingRequest) {
    //   setState(() => isPerformingRequest = true);

    //   final gifs = await client.search(mood,
    //     offset: 0,
    //     limit: 50,
    //     rating: GiphyRating.r,
    //   );

    //   if (gifs != null) {
    //     for (var i = 0; i < gifs.data.length; i++) {
    //       var url = gifs.data[i].images.original.url;
    //       print(url);

    //       setState(() => imgs.add(url));
    //     }
    //   }
      
    //   setState(() => isPerformingRequest = false);
    // } 
  }
}
