import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_app/custom_icons_icons.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_app/utils.dart';

void main() => runApp(Gifzcroll());

class Gifzcroll extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (BuildContext context) => HomePage(),
          '/favs': (BuildContext context) => FavsPage(),
        });
  }
}

//////////////////////// FAVS PAGE ////////////////////////
class FavsPage extends StatefulWidget {
  FavsPage({Key key}) : super(key: key);

  @override
  _FavsPageState createState() => _FavsPageState();
}

class _FavsPageState extends State<FavsPage> {
  List<Gif> imgs = [];
  bool isPerformingRequest = false;

  _getMoreData() async {
    if (!isPerformingRequest) {
      setState(() => isPerformingRequest = true);

      List<Gif> newEntries = await fetchFavs();
      setState(() {
        imgs.addAll(newEntries);
        isPerformingRequest = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getMoreData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: new GridView.builder(
        gridDelegate:
            new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: imgs.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              print('sharing ' + imgs[index].url);
              shareGif(context, imgs[index].url, isPerformingRequest);
            },
            onDoubleTap: () async {
              if (imgs[index].isFav) {
                print('unfaving ' + imgs[index].favId);
                unfavGif(context, imgs[index].favId);
                setState(() {
                  imgs[index].favId = null;
                  imgs[index].isFav = false;
                  imgs.removeAt(index);
                });
              } else {
                print('faving ' + imgs[index].url);

                String docId = await favGif(context, imgs[index].url);
                setState(() {
                  imgs[index].favId = docId;
                  imgs[index].isFav = true;
                });
              }
            },
            child: Card(
              color: Colors.black,
              margin: EdgeInsets.fromLTRB(6, 6, 6, 6),
              borderOnForeground: false,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              child: new CachedNetworkImage(
                imageUrl: imgs[index].url,
                placeholder: (context, url) => new CircularProgressIndicator(),
                errorWidget: (context, url, error) => new Icon(Icons.error),
              ),
            ),
          );
        },
      ),
    );
  }
}

//////////////////////// HOME PAGE ////////////////////////
class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Gif> imgs = [];
  ScrollController _scrollController;
  bool isPerformingRequest = false;
  String mood = "funny";
  OverlayEntry moodTextBox;

  _getMoreData() async {
    if (!isPerformingRequest) {
      setState(() => isPerformingRequest = true);

      List<Gif> newEntries = await fetchGifs(mood);
      setState(() {
        imgs.addAll(newEntries);
        isPerformingRequest = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = new ScrollController();

    _getMoreData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _getMoreData();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Gifzcroll"),
        backgroundColor: Colors.black,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: Colors.red,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavsPage()),
              );
            },
          )
        ],
      ),
      floatingActionButton: _buildSpeedDialMood(),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: imgs.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == imgs.length - 1) {
            return _buildProgressIndicator();
          } else {
            return GestureDetector(
              onTap: () {
                print('sharing ' + imgs[index].url);
                shareGif(context, imgs[index].url, isPerformingRequest);
              },
              onDoubleTap: () async {
                if (imgs[index].isFav) {
                  print('unfaving ' + imgs[index].favId);
                  unfavGif(context, imgs[index].favId);
                  setState(() {
                    imgs[index].favId = null;
                    imgs[index].isFav = false;
                  });
                } else {
                  print('faving ' + imgs[index].url);

                  String docId = await favGif(context, imgs[index].url);
                  setState(() {
                    imgs[index].favId = docId;
                    imgs[index].isFav = true;
                  });
                }
              },
              child: new Card(
                margin: EdgeInsets.fromLTRB(0, 6, 0, 0),
                color: Colors.black,
                borderOnForeground: false,
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                child: new Stack(
                  fit: StackFit.passthrough,
                  children: <Widget>[
                    new FadeInImage.memoryNetwork(
                        fadeInDuration: Duration(milliseconds: 0),
                        placeholder: kTransparentImage,
                        image: imgs[index].url,
                        fit: BoxFit.fitWidth),
                    imgs[index].isFav
                        ? new Positioned(
                            left: 3.0,
                            top: 3.0,
                            child: new Icon(Icons.favorite, color: Colors.red),
                          )
                        : new Container()
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

//////////////////////// UTILS WIDGETS ////////////////////////
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

  Widget _buildSpeedDialMood() {
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
              onTap: () => _buildMoodText(),
            ),
          ],
        ));
  }

  Widget _textOverlay() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 200, maxHeight: 200),
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
    );
  }

  void _buildMoodText() {
    if (moodTextBox == null) {
      moodTextBox =
          new OverlayEntry(builder: (BuildContext context) => _textOverlay());
      Overlay.of(context).insert(moodTextBox);
    }
  }

  void setMoodFromText(mood) {
    moodTextBox.remove();
    moodTextBox = null;

    setMood(mood);
  }

  void setMood(newMood) {
    mood = newMood;
  }
}
