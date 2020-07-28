import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.black, title: Text("关于高梵")),
        body: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset("assets/logo.png",
                    height: 100, width: 100)),
            SizedBox(height: 50),
            Text("广州极迅客信息科技有限公司",
                style: TextStyle(color: Colors.black54, fontSize: 14)),
            SizedBox(height: 10),
            Text("@2020", style: TextStyle(color: Colors.black54)),
            SizedBox(height: 10),
            Text("保留所有权利", style: TextStyle(color: Colors.black54)),
            SizedBox(height: 10),
            Text("版本: 1.0beta", style: TextStyle(color: Colors.black54)),
            SizedBox(height: 50),
            Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
              Text("联系我们", style: TextStyle(color: Colors.black54)),
              FlatButton(
                child: Text("alex@geetion.com",
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.black)),
                onPressed: () {
                  launch("mailto:alex@geetion.com");
                },
              )
            ])
          ],
        )));
  }
}
