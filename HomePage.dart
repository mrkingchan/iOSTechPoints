import 'dart:math';

import 'package:app/image_cache/cached_network_image.dart';
import 'package:app/lang/lang.dart';
import 'package:app/model/carouse.dart';
import 'package:app/net/net.dart';
import 'package:app/page/main_home_page/components/short_video.dart';
import 'package:app/player/helper/video_helper.dart';
import 'package:app/utils/utils.dart';
import 'package:app/widget/common/vedioItems/recommendItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Carouse> bannerItems = [];
  List shortItems = [];
  List avItems = [];
  String domain = "";
  String spDomain = "";

  List<List> shorts = [];
  List<List> avs = [];

  RefreshController refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    loadData(false);
  }

  void loadData(refresh) async {
    //轮播图数据
    var resp1 = await net.request(Routers.CAROUSE_LIST_POST, args: {"type": 1});
    if (resp1.code != 200 || resp1.data == null) {
      return;
    }
    //av
    var resp2 = await net.request(Routers.THEMATIC_AV_VIDEO_LIST_POST,
        method: "POST", args: {'id': 1, 'page': 1, 'pageSize': 30});
    if (resp2.code == 200 && resp2.data != null) {
      List items = resp2.data['videos'];
      domain = resp2.data['domain'];
      avItems = items.map((item) {
        return item;
      }).toList();
    }

    //短视频
    var resp3 = await net.request(Routers.THEMATIC_SHORT_VIDEO_LIST_POST,
        method: "POST", args: {'id': 1, 'page': 1, 'pageSize': 30});
    if (!(resp3.code == 200 && resp3.data != null)) {
      return;
    }
    List items = resp3.data['videos'];
    shortItems = items.map((f) {
      return f;
    }).toList();

    setState(() {
      List banners = resp1.data;
      bannerItems = banners.map((value) {
        return Carouse.fromJson(value);
      }).toList();

      var A = avItems.length / 5;
      var Ax = avItems.length % 5;

      var B = shortItems.length / 10;
      var Bx = shortItems.length % 10;
      if (refresh) {
        refreshController.refreshCompleted();
      }
      avs.clear();
      shorts.clear();
      if (A > 0) {
        for (int i = 0; i < A.toInt(); i++) {
          List subItems = avItems.sublist(i * 5, (i + 1) * 5);
          avs.add(subItems);
        }
      }
      if (Ax > 0) {
        avs.add(avItems.sublist(avItems.length - Ax, avItems.length));
      }

      if (B > 0) {
        for (int i = 0; i < B.toInt(); i++) {
          List subItems = shortItems.sublist(i * 10, (i + 1) * 10);
          shorts.add(subItems);
        }
      }
      if (Bx > 0) {
        shorts
            .add(shortItems.sublist(shortItems.length - Bx, shortItems.length));
      }
    });
  }

  List<Widget> buildItems() {
    List<Widget> items = [];
    if (bannerItems.length > 0) {
      items.add(SliverToBoxAdapter(
        child: Container(
          height: 300,
          child: Swiper(
            layout: SwiperLayout.DEFAULT,
            pagination: SwiperPagination(
              alignment: Alignment.bottomRight,
              margin: EdgeInsets.only(bottom: 10, right: 10),
            ),
            control: SwiperControl(
              iconPrevious: null,
              iconNext: null,
              color: Colors.red,
            ),
            onTap: (index) {},
            index: 0,
            autoplay: true,
            autoplayDelay: 4000,
            itemCount: bannerItems.length,
            onIndexChanged: (index) {
              print('>>>>>>>>' + index.toString());
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                cacheManager: ImgCacheMgr(),
                imageUrl: bannerItems[index].linkImg,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ));
    }

    var maxValue = max(avs.length, shorts.length);
    var minValue = min(avs.length, shorts.length);

    for (int i = 0; i < maxValue; i++) {
      if (avs.length > 0) {
        //AV
        Widget A = buildAVItems(avs[i]);
        items.add(A);
      }
      if (i <= minValue - 1) {
        //短视频
        Widget B = buildShortItems(shorts[i]);
        items.add(B);
      }
    }
    return items;
  }

  //构建短视频列表
  Widget buildShortItems(List items) {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        alignment: Alignment.center,
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            Map item = items[index];
            return shortVideoItem(items[index], this.context, this.domain,
                isVipVideo: item['attributes']['isVip'],
                isBuyVideo: item['attributes']['needPay'],
                tapVideo: () {});
          },
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, childAspectRatio: 1.5, mainAxisSpacing: 10.0),
        ),
      ),
    );
  }

  //构建长视频列表
  Widget buildAVItems(List items) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 0.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final currentItem = items[index];
          return reCommendItem(
              index: currentItem['star'],
              title: currentItem['title'],
              reason: currentItem['reason'],
              tags: currentItem['recTags'] != null
                  ? List<String>.from(currentItem['recTags'])
                  : [],
              imgUrl: this.domain +
                  ((currentItem['coverImg'] as List).isNotEmpty
                      ? currentItem['coverImg'][0]
                      : ''),
              actors: (currentItem['actors'] as List).isNotEmpty
                  ? currentItem['actors'][0]['name']
                  : '',
              isVipVideo: currentItem['attributes']['isVip'],
              tapVideo: () {
                selectVideo(this.context, currentItem['id']);
              });
        },
        childCount: items.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SmartRefresher(
            enablePullDown: true,
            header: WaterDropHeader(
              complete: Text(
                Lang.SHUAXINWANCHENG,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            footer: ClassicFooter(
                loadingText: Lang.JIAZAIZHONG,
                canLoadingText: Lang.SONGKAIJIAZAIGENGDUO,
                noDataText: Lang.MEIYOUGENGDUOSHUJU,
                idleText: Lang.SHANGLAJIAZAIGENGDUO),
            controller: refreshController,
            onRefresh: () {
              loadData(true);
              vibrate();
            },
            child: CustomScrollView(
              slivers: buildItems(),
            ),
          ),
        )
      ],
    );
  }
}
