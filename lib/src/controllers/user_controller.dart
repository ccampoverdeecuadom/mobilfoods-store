import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:markets_owner/src/helpers/custom_trace.dart';
import 'package:markets_owner/src/models/route_argument.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../helpers/helper.dart';
import '../models/user.dart';
import '../repository/user_repository.dart' as repository;
import '../repository/settings_repository.dart' as settingRepo;


class UserController extends ControllerMVC {
  User user = new User();
  bool hidePassword = true;
  bool loading = false;
  GlobalKey<FormState> loginFormKey;
  GlobalKey<ScaffoldState> scaffoldKey;
  FirebaseMessaging _firebaseMessaging;
  OverlayEntry loader;

  UserController() {
    loader = Helper.overlayLoader(context);
    loginFormKey = new GlobalKey<FormState>();
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    _firebaseMessaging = FirebaseMessaging();
    _firebaseMessaging.getToken().then((String _deviceToken) {
      print(_deviceToken);
      user.deviceToken = _deviceToken;
    }).catchError((e) {
      print('Notification not configured');
    });
  }

  void login() async {
    FocusScope.of(context).unfocus();
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      Overlay.of(context).insert(loader);
      repository.login(user).then((value) {
        if (value != null && value.apiToken != null) {

          /****************Start FIREBASE******************/

          _firebaseMessaging = FirebaseMessaging();


          _firebaseMessaging.configure(
            onMessage: (Map<String, dynamic> message) async {
              print("onMessage: $message");
              if (message['data']['id'] == "orders") {
                var order_id = message['data']['order_id'];
                print(order_id);
                settingRepo.navigatorKey.currentState.pushNamed('/OrderDetails', arguments: RouteArgument(id: order_id));
                //settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments: 2);
              }
            },
            onLaunch: (Map<String, dynamic> message) async {
              print("onLaunch: $message");
              if (message['data']['id'] == "orders") {
                var order_id = message['data']['order_id'];
                print(order_id);
                settingRepo.navigatorKey.currentState.pushNamed('/OrderDetails', arguments: RouteArgument(id: order_id));
                //settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments: 2);
              }
            },
            onResume: (Map<String, dynamic> message) async {
              print("onResume: $message");
              try {
                if (message['data']['id'] == "orders") {
                  var order_id = message['data']['order_id'];
                  print(order_id);
                  settingRepo.navigatorKey.currentState.pushNamed('/OrderDetails', arguments: RouteArgument(id: order_id));
                  //settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments: 2);
                } else if (message['data']['id'] == "messages") {
                  settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments: 3);
                }
              } catch (e) {
                print(CustomTrace(StackTrace.current, message: e));
              }
            },
          );

          _firebaseMessaging.requestNotificationPermissions(
              const IosNotificationSettings(
                  sound: true, badge: true, alert: true, provisional: true));
          _firebaseMessaging.onIosSettingsRegistered
              .listen((IosNotificationSettings settings) {
            print("Settings registered: $settings");
          });



          _firebaseMessaging.getToken().then((String _deviceToken) {
            print('Toke: ' + _deviceToken);
            print(_deviceToken);
            user.deviceToken = _deviceToken;
          }).catchError((e) {
            print('Notification not configured');
          });

          /******************END FIREBASE*****************/

          Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Pages', arguments: 2);
        } else {

          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).wrong_email_or_password),
          ));
        }
      }).catchError((e) {
        loader.remove();
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(S.of(context).thisAccountNotExist),
        ));
      }).whenComplete(() {
        Helper.hideLoader(loader);
      });
    }
  }



  Widget _buildDialog(BuildContext context, Map<String, dynamic> message) {
    return AlertDialog(
      content: Text("Item  has been updated"),
      actions: <Widget>[
        FlatButton(
          child: const Text('CLOSE'),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        FlatButton(
          child: const Text('SHOW'),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }

  void register() async {
    FocusScope.of(context).unfocus();
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      Overlay.of(context).insert(loader);
      repository.register(user).then((value) {
        if (value != null && value.apiToken != null) {
          Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Pages', arguments: 2);
        } else {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).wrong_email_or_password),
          ));
        }
      }).catchError((e) {
        loader.remove();
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(S.of(context).thisAccountNotExist),
        ));
      }).whenComplete(() {
        Helper.hideLoader(loader);
      });
    }
  }

  void resetPassword() {
    FocusScope.of(context).unfocus();
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      Overlay.of(context).insert(loader);
      repository.resetPassword(user).then((value) {
        if (value != null && value == true) {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).your_reset_link_has_been_sent_to_your_email),
            action: SnackBarAction(
              label: S.of(context).login,
              onPressed: () {
                Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Login');
              },
            ),
            duration: Duration(seconds: 10),
          ));
        } else {
          loader.remove();
          scaffoldKey.currentState.showSnackBar(SnackBar(
            content: Text(S.of(context).error_verify_email_settings),
          ));
        }
      }).whenComplete(() {
        Helper.hideLoader(loader);
      });
    }
  }
}
