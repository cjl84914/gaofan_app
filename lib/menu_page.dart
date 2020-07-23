import 'package:flutter/material.dart';
import 'package:gaofan/privacy_policy.dart';
import 'about.dart';

class CategoryMenuPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Container(
          padding: EdgeInsets.only(top: 40.0),
          color: Colors.black12,
          child: ListView(
            children: [
              SizedBox(height: 16.0),
              ListTile(
                  title: Text("隐私政策",
                      style: theme.textTheme.body2,
                      textAlign: TextAlign.center),
                  onTap: () {
                    Navigator.push(context,
                        new MaterialPageRoute(builder: (context) {
                      return new PrivacyPage();
                    }));
                  }),
              SizedBox(height: 14.0),
              ListTile(
                title: Text("关于我们",
                    style: theme.textTheme.body2, textAlign: TextAlign.center),
                onTap: () {
                  Navigator.push(context,
                      new MaterialPageRoute(builder: (context) {
                    return new AboutPage();
                  }));
                },
              ),
              SizedBox(height: 14.0),
            ],
          )),
    );
  }
}
