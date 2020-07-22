import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gaofan/style.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {

  final ImagePicker _picker = ImagePicker();

  Future getImgByGallery(BuildContext context) async {
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    croppedFile(context, file);
  }

  Future getImgByCamera(BuildContext context) async {
    PickedFile file = await _picker.getImage(source: ImageSource.camera);
    croppedFile(context, File(file.path));
  }

  Future croppedFile(BuildContext context, File file) async {
    if (file != null) {
      File croppedFile = await ImageCropper.cropImage(
          sourcePath: file.path,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          androidUiSettings: AndroidUiSettings(
              toolbarTitle: '裁剪',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: true),
          iosUiSettings: IOSUiSettings(
            title: '裁剪',
          ));
      if (croppedFile != null) {
        Navigator.push(context, new MaterialPageRoute(builder: (context) {
          return new StyleWidget(croppedFile);
        }));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: Colors.black45,
            body: Column(mainAxisSize: MainAxisSize.min, children: [
//      Image.asset("assets/banner.jpg"),
          SizedBox(height: 120.0),
          Row(
            children: <Widget>[
              Expanded(
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                IconButton(
                    icon: Icon(Icons.photo_camera),
                    iconSize: 48,
                    onPressed: () {
                      getImgByCamera(context);
                    }),
                Text('相机')
              ])),
              Expanded(
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                IconButton(
                    icon: Icon(Icons.photo_album),
                    iconSize: 48,
                    onPressed: () {
                      getImgByGallery(context);
                    }),
                Text('相册')
              ])),
            ],
          )
        ]));
  }
}
