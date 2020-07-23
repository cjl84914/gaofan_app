import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'backdrop.dart';
import 'menu_page.dart';
import 'home.dart';

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  _ShrineAppState createState() => _ShrineAppState();
}

class _ShrineAppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "高梵",
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.black,
          accentColor: Colors.amber,
          buttonColor: Colors.amber,
//          scaffoldBackgroundColor: Colors.blue
        ),
        home:
        Backdrop(
          frontLayer:  HomePage(),
          backLayer: CategoryMenuPage(
          ),
          frontTitle: Text('高梵'),
          backTitle: Text('更多'),
        )

    );
  }
}