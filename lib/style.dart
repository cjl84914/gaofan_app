import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_extend/share_extend.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'tflite.dart';

var _image;
class StyleWidget extends StatefulWidget {
  StyleWidget(image) {
    _image = image;
  }

  @override
  _StyleState createState() => new _StyleState();
}

class _StyleState extends State<StyleWidget> {
  Map _recognitions;
  bool _busy = false;
  int _slider = 100;
  bool _setting = true;
  double _ratio = 1;
  int _index;

  Future styleNet() async {
    var recognitions = await Tflite.runStyleOnImage(
        path: _image.path, ratio: _ratio, style: _index);
//    print(recognitions);
    setState(() {
      _recognitions = recognitions;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];
    if (_recognitions != null) {
      stackChildren.add(Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          child: Image.memory(_recognitions["img"])));
      stackChildren.add(Positioned(
          bottom: 150,
          height: 100,
          width: size.width,
          child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Expanded(
                child: Offstage(
                    offstage: _setting,
                    child: IconButton(
                        icon: Icon(Icons.close),
                        iconSize: 36,
                        onPressed: () {
                          setState(() {
                            _setting = !_setting;
                          });
                        }))),
            Expanded(
                child: IconButton(
                    icon: Icon(Icons.tune),
                    iconSize: 48,
                    onPressed: () {
                      setState(() {
                        _setting = !_setting;
                      });
                    })),
            Expanded(
                child: Offstage(
                    offstage: _setting,
                    child: IconButton(
                        icon: Icon(Icons.check),
                        iconSize: 35,
                        onPressed: () {
                          setState(() {
                            _busy = true;
                            _ratio =  _slider * 0.01;
                          });
                          styleNet();
                        })))
          ])));
    } else if (_image != null) {
      stackChildren.add(Positioned(
          top: 0.0, left: 0.0, width: size.width, child: Image.file(_image)));
    }
    stackChildren.add(Positioned(
        bottom: 0,
        width: size.width,
        height: 150,
        child: Offstage(
            offstage: _setting,
            child: Slider(
                value: _slider.toDouble(),
                min: 0,
                max: 100,
                onChanged: (double value) {
                  setState(() {
                    _slider = value.toInt();
                  });
                }))));
    stackChildren.add(Positioned(
        bottom: 0.0,
        height: 150,
        width: size.width,
        child: Offstage(
            offstage: !_setting,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
//                padding: EdgeInsets.all(5),
                itemCount: 34,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child:            ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.asset(
                              'assets/thumbnails/gstyle$index.jpg')),
                    ),
                    onTap: () {
                      setState(() {
                        _busy = true;
                        _index = index;
                      });
                      styleNet();
                    },
                  );
                }))));
    if (_busy) {
      stackChildren.add(const Opacity(
        child: ModalBarrier(dismissible: false, color: Colors.grey),
        opacity: 0.3,
      ));
      stackChildren.add(const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('高梵'),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.share),
                onPressed: () async {
                  if (_recognitions != null) {
                    Directory tempDir = await getTemporaryDirectory();
                    Directory directory = new Directory('${tempDir.path}/tmp');
                    if (!directory.existsSync()) {
                      directory.createSync();
                    }
                    File file = new File('${tempDir.path}/style.jpg');
                    file.writeAsBytes(_recognitions["img"]);
                    print(file.path);
                    ShareExtend.share(file.path, "image",
                        sharePanelTitle: "share image title",
                        subject: "share image subject");
                  }
                })
          ],
        ),
        body: Stack(children: stackChildren));
  }

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();

    final info = statuses[Permission.storage].toString();
    print(info);
  }
}