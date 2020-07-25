class Styles {
  static List<Style> get list => [
        new Style(
          name: "抽象主义",
          file: "gstyle1.jpg",
        ),
        new Style(
          name: "立体主义",
          file: "gstyle0.jpg",
        ),
        new Style(
          name: "立体主义2",
          file: "gstyle2.jpg",
        ),
        new Style(
          name: "多维空间",
          file: "gstyle3.jpg",
        ),
        new Style(
          name: "达达主义",
          file: "gstyle4.jpg",
        ),
        new Style(
          name: "立体主义3",
          file: "gstyle5.jpg",
        ),
        new Style(
          name: "油画风景",
          file: "yhfj.jpg",
        ),
        new Style(
          name: "油画静物",
          file: "yhjw.jpg",
        ),
        new Style(
          name: "扫描人像",
          file: "gstyle18.jpg",
        ),
        new Style(
          name: "水墨山水",
          file: "gstyle17.jpg",
        ),
        new Style(
          name: "火焰效果",
          file: "gstyle27.jpg",
        )
      ];
}

class Style {
  const Style({this.name, this.file});

  final String file;
  final String name;

  String get getPath => 'assets/thumbnails/$file';

  String get getName => name;
}
