class Styles {
//  _list.add(new Style(name: "抽象主义",file: "gstyle1.jpg"));

  static List<Style> get list => [

        new Style(
          name: "立体主义",
          file: "gstyle0.jpg",
        ),
        new Style(
          name: "立体主义2",
          file: "gstyle2.jpg",
        ),
    new Style(
      name: "抽象主义",
      file: "gstyle1.jpg",
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
          name: "油画静物",
          file: "yhjw1.jpg",
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
        ),
        new Style(
          name: "裁剪",
          file: "VCG41N1158454070.jpg",
        ),
        new Style(
          name: "颜色彩带",
          file: "gstyle22.jpg",
        ),
        new Style(
          name: "颜色果冻",
          file: "gstyle23.jpg",
        ),
        new Style(
          name: "粉红万柳",
          file: "gstyle31.jpg",
        ),
        new Style(
          name: "彩色心心",
          file: "gstyle32.jpg",
        ),
        new Style(
          name: "螺旋之窗",
          file: "gstyle33.jpg",
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
