import 'dart:async';

import 'package:app/event/index.dart';
import 'package:dio/dio.dart';
import 'address.dart';
import 'package:app/storage/index.dart';
import 'package:app/utils/native.dart';
import 'package:app/utils/lines.dart';

final http = new _HttpManager();

///http请求
class _HttpManager {
  /// 当前域名
  /// ##################测试地址#####################
  String BaseURL = "http://192.168.1.9:8019/api";
  List<String> expireTokens = List();
  Dio dio = new Dio();
  _HttpManager() {
    // BaseURL = line.fastest;
    handelInterceptors();
  }

  //MARK:--统一请求
  Future<ReseponseData> request(url, params, isGet) async {
    var option = await buildRequest(url, params, isGet);
    Response response;
    try {
      response =
          await dio.request(BaseURL + url, data: params, options: option);
      if (url == Address.USER_TRAVELER) {
        //存储token到本地
        if (response.data["token"] != null) {
          await Storage.save(StorageKeys.TOKEN, response.data['token']);
        }
      }
      bool isValite = response.data is Map;
      if (isValite) {
        //具体的业务错误在data里的code进行判断 200之外的都属于业务错误
        return Future.value(ReseponseData(response.data["data"],
            response.data["code"], response.data["msg"]));
      } else {
        //这里主要处理 请求成功了，但是responsebody中没有数据的情况
        return Future.value(ReseponseData(response.data, 200, "ok"));
      }
    } on DioError catch (e) {
      // 响应状态码200之外的请求
      if (e.response != null) {
        return Future.value(
            ReseponseData(null, e.response.statusCode, "接口请求失败"));
      } else {
        return Future.value(null);
      }
    }
  }

  //MARK:--处理拦截器,主要是方便log打印
  handelInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options) {
        var paramters =
            options.method == "GET" ? options.queryParameters : options.data;
        print("发起网络请求>>>>>${options.path}==$paramters==${options.headers}");
      },
      onResponse: (Response response) {
        print("收到正常响应<<<<<<<${response.request.path}\n${response.toString()}");
        //处理响应头里的token信息
        if (response.headers.map.containsKey("refresh-authorization")) {
          Storage.save(StorageKeys.TOKEN,
              response.headers.map["refresh-authorization"][0]);
        }
      },
      onError: (DioError e) {
        if (e.response != null) {
          print("收到错误响应<<<<<<<${e.response.headers}==<<<${e.response.data}");
          if (e.response.statusCode == 301) {
            //处理多次接受到301 这里值处理一次
            String token = e.request.headers["Authorization"];
            if (!expireTokens.contains(token)) {
              reLoginEventBus.fire(null);
              expireTokens.add(token);
            }
          }
        }
      },
    ));
  }

  //MARK:--构建请求
  buildRequest(url, params, isGet) async {
    var option = new Options(contentType: "application/json;charset=utf-8");
    Map<String, dynamic> headers = new Map();
    headers["User-Agent"] =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 11_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15F79";
    option.method = isGet == true ? "GET" : "POST";
    var authorization = await Storage.get(StorageKeys.TOKEN);
    if (authorization != null) {
      headers["Authorization"] = authorization;
    }
    option.headers = headers;
    return option;
  }

  String getLineUrl(url) {
    return BaseURL + url;
  }

  //MARK:--游客登陆
  Future<String> travelerLogin() async {
    await Storage.remove(StorageKeys.TOKEN);
    var devId = await n.getUUID();
    var msg = {'devId': devId, 'coat': 'Puff'};
    var reponse = await request(Address.USER_TRAVELER, msg, false);
    print('rtn:' + reponse.toString());
    if (reponse.code == 200) {
      await Storage.save(StorageKeys.TOKEN, reponse.data['token']);
      return reponse.data['token'];
    }
    return "";
  }

  //MARK:--刷新token
  refreshToken() async {
    await request("/user/refreshToken", null, false);
  }
}

//MARK:--新的响应
class ReseponseData {
  var data;
  int code;
  String message;
  ReseponseData(this.data, this.code, this.message);
}
