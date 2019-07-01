import 'dart:convert';
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
  ScrollController _scrollController;
  bool isPerformingRequest = false;
  bool isSharing = false;
  String mood = "funny";
  String source = "tenor";
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
      if ((_scrollController.position.maxScrollExtent-_scrollController.position.pixels) < 1500) {
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
                  // child: FadeInImage.memoryNetwork(
                  //   fadeInDuration: Duration(milliseconds: 0),
                  //   placeholder: kTransparentImage,
                  //   image: imgs[index], fit: BoxFit.fitWidth
                  // ),
                  child: CachedNetworkImage(
                    // placeholder: (context, url) => new Placeholder(),
                    imageUrl: imgs[index], fit: BoxFit.fitWidth
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
          SpeedDialChild(
            child: Icon(Icons.add, color: Colors.white),
            backgroundColor: Colors.black,
            onTap: () => showMoodText(),
          ),
        ],
      )
    );
  }

  Widget buildSpeedDialSource() {
    return Opacity(
      opacity: 0.8,
      child: new SpeedDial(
        animatedIcon: AnimatedIcons.view_list,
        overlayColor: Colors.black,
        overlayOpacity: 0.3,
        marginRight: 80,
        backgroundColor: Colors.black,
        visible: true,
        curve: Curves.bounceIn,
        children: [
          SpeedDialChild(
            label: "giphy",
            backgroundColor: Colors.black,
            onTap: () => setSource("giphy"),
          ),
          SpeedDialChild(
            label: "tenor",
            backgroundColor: Colors.black,
            onTap: () => setSource("tenor"),
          ),
        ],
      )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: buildBody(),
      floatingActionButton: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomLeft,
            child: buildSpeedDialMood(),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: buildSpeedDialSource(),
          ),
        ],
      )
    );
  }

  textOverlay() {

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

  showMoodText() {
    if (moodTextBox == null) {
      moodTextBox = new OverlayEntry(builder: (BuildContext context) => textOverlay());
      Overlay.of(context).insert(moodTextBox);
    }
  }

  setMoodFromText(mood) {
    moodTextBox.remove();
    moodTextBox = null;

    setMood(mood);
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

    // Remove last visible+10 itens em fetch again
    if (imgs != null && imgs.length > lastItem+10) {
      imgs.removeRange(lastItem+10, imgs.length);
    }
    fetchGifs();
  }

  setSource(newSource) {
    setState(() => source = newSource);
    fetchGifs();
  }

  fetchGifs() async {

    if (!isPerformingRequest) {
      setState(() => isPerformingRequest = true);

      if (source == "tenor") {
        
        mood = mood.split('+')[0];
        var endpoint = 'https://api.tenor.com/v1/random?q=${mood}&key=LIVDSRZULELA&limit=20&media_filter=minimal&contentfilter=off&anon_id=3a76e56901d740da9e59ffb22b988242';
        final response = await http.get(endpoint);
        if (response.statusCode == 200) {
          List results = json.decode(response.body)['results'];

          for (var i = 0; i < results.length; i++) {
            setState(() => imgs.add(results[i]['media'][0]['gif']['url']));
          }

        } 

      } else {
        final gifs = await client.search(mood,
          offset: 0,
          limit: 100,
          rating: GiphyRating.r,
        );

        if (gifs != null) {
          for (var i = 0; i < gifs.data.length; i++) {
            var url = gifs.data[i].images.original.url;

            setState(() => imgs.add(url));
          }
        }
      }

       setState(() => isPerformingRequest = false);
    }

  }
}
