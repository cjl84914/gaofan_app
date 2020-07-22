import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'backdrop.dart';
import 'menu_page.dart';
import 'home.dart';
import 'model/product.dart';

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  _ShrineAppState createState() => _ShrineAppState();
}

class _ShrineAppState extends State<App> {
  Category _currentCategory = Category.all;
  void _onCategoryTap(Category category) {
    setState(() {
      _currentCategory = category;
    });
  }
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
          currentCategory: _currentCategory,
          frontLayer:  HomePage(),
          backLayer: CategoryMenuPage(
            currentCategory: _currentCategory,
            onCategoryTap: _onCategoryTap,
          ),
          frontTitle: Text('高梵'),
          backTitle: Text('更多'),
        )

    );
  }
}