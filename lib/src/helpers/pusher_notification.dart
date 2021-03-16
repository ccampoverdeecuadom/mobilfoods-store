import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:markets_owner/src/models/order.dart';
import 'package:markets_owner/src/models/route_argument.dart';
import 'package:markets_owner/src/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../elements/notification_plugin.dart';
import 'package:pusher_websocket_flutter/pusher.dart';


class PusherNotification {

  Channel channel;
  NotificationPlugin notificationPlugin;

  PusherNotification() {
    notificationPlugin = new NotificationPlugin();
  }


  Future<void> initPusher() async {
    try {
      await Pusher.init("748edca4f57534084863", PusherOptions(cluster: "mt1"),
      // await Pusher.init("dd1f605388a449d95737", PusherOptions(cluster: "mt1"),
          enableLogging: true);
    } on PlatformException catch (e) {
      print(e.message);
    }

    //Connected
    Pusher.connect(onConnectionStateChange: (x) async {
      print('***********Conected***********');
      print(x.currentState);
    }, onError: (x) {
      print('***********Error***********');
      print(x.message);
    });

    //subscribe
    channel = await Pusher.subscribe('orders');

    //bind
    channel.bind('App\\Events\\OrderCreated', (e) async {
      NotificationPlugin.init();
        SharedPreferences prefs = await SharedPreferences.getInstance();
      //prefs.clear();
      User _user;
      if (prefs.containsKey('current_user')) {
        _user = User.fromJSON(json.decode(await prefs.get('current_user')));
      }
      Order _order = Order.fromJSON(jsonDecode(e.data)['order']);
      Iterable usersIterable = json.decode(e.data)['users'];
      List<User> users = List<User>.from(usersIterable.map((model)=> User.fromJSON((model))));

      if(_user != null)
        users.forEach((element) {
          if(element.id == _user.id)
            notificationPlugin.showNotificationWithAttachment(_order);
        });
    });
  }
}