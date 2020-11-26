import 'dart:ui';
import 'package:app/image_cache/cached_network_image.dart';
import 'package:app/lang/lang.dart';
import 'package:app/model/home_video_resp.dart';
import 'package:app/player/helper/video_helper.dart';
import 'package:app/utils/utils.dart';
import 'package:app/widget/gridViewController.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:app/net/net.dart';

class ShortVideoListPage extends StatefulWidget {
  @override
  _ShortVideoListPageState createState() => _ShortVideoListPageState();
}

class _ShortVideoListPageState extends State<ShortVideoListPage> {
  List<VideoResp> items = List<VideoResp>();
  String domain;
  GridViewController gridViewController;
  @override
  void initState() {
    super.initState();
    gridViewController = GridViewController(null, null, 0);
    loadData(true);
  }

  //MARK:加载数据
  void loadData(bool isInitData) async {
    var resp =
        await net.request(Routers.SHORT_VIDEO_LIST, method: "POST", args: {
      "pageSize": 20,
      "ids": this.items.map((item) {
        return item.id;
      }).toList(),
      "lastCreatedAt": this.items.length == 0 ? "" : this.items.last.createdAt,
    });
    if (resp.code == 200) {
      setState(() {
        var data = resp.data as Map;
        var itemList = data["videos"];
        domain = data["domain"];
        List<VideoResp> results = List<VideoResp>();
        if (itemList.length > 0) {
          itemList.forEach((item) {
            results.add(VideoResp.fromJson(item));
          });
        }
        if (isInitData) {
          this.items = results;
          this.gridViewController.onRefreshCancle();
        } else {
          this.gridViewController.onLoadCancle();
          this.items = this.items + results;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return items.length == 0
        ? Container()
        : Stack(
            children: <Widget>[
              SmartRefresher(
                enablePullDown: true,
                enablePullUp: true,
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
                controller: this.gridViewController.refreshController,
                onRefresh: () {
                  loadData(true);
                },
                onLoading: () {
                  loadData(false);
                },
                child: StaggeredGridView.countBuilder(
                  padding: EdgeInsets.all(2.0),
                  crossAxisCount: 4,
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    return shortVideoItem(items[index]);
                  },
                  staggeredTileBuilder: (int index) {
                    var item = items[index];
                    var percent = (item.width / item.height * 1.0) >= 1.0
                        ? (item.width / item.height * 1.0)
                        : 1.3;
                    return StaggeredTile.count(2, 2.0 * percent);
                  },
                  mainAxisSpacing: 2.0,
                  crossAxisSpacing: 2.0,
                ),
              ),
              Positioned(
                top: 60,
                right: 0,
                width: 50,
                height: 32,
                child: Container(
                  width: 50,
                  height: 32,
                  margin: EdgeInsets.only(right: 0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(16.0),
                      ),
                      color: Color.fromRGBO(255, 255, 255, 0.4)),
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Image.asset("assets/common/short_video_search.png"),
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed('searchMain', arguments: {"type": 2});
                    },
                  ),
                ),
              )
            ],
          );
  }

//MARK:--单个视频
  Widget shortVideoItem(VideoResp video) {
    final itemW = (MediaQuery.of(context).size.width - 6.0) / 2.0;
    return Container(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CachedNetworkImage(
              cacheManager: ImgCacheMgr(),
              imageUrl: domain + video.coverImg[0],
              fit: BoxFit.cover,
            ),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                color: Colors.white10,
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                //MARK:跳转视频播放
                selectVideo(context, video.id);
              },
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        height: video.width / video.height >= 1.0
                            ? itemW
                            : itemW * 1.3,
                        width: itemW,
                        child: CachedNetworkImage(
                            alignment: Alignment.center,
                            cacheManager: ImgCacheMgr(),
                            imageUrl: domain + video.coverImg[0],
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: Container(
                      color: Color.fromRGBO(0, 0, 0, 0.4),
                      margin: EdgeInsets.symmetric(horizontal: 0),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 3.0),
                          ),
                          Text(
                            "  ${secFmt(video.playTime)}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 2.0),
                          ),
                          Expanded(
                            child: Text(
                              "  ${video.title}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
