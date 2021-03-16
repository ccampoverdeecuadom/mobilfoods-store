import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../models/statistic.dart';
import '../models/user.dart';
import '../repository/dashboard_repository.dart';
import '../repository/user_repository.dart';

class ProfileController extends ControllerMVC {
  User user = new User();
  GlobalKey<ScaffoldState> scaffoldKey;
  List<Statistic> statistics = <Statistic>[];
  String imageUri;
  bool isUploadingImage;

  ProfileController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    listenForUser();
  }

  void listenForUser() {
    getCurrentUser().then((_user) {
      setState(() {
        user = _user;
      });
    });
  }

  void listenForStatistics({String message}) async {
    final Stream<Statistic> stream = await getStatistics();
    stream.listen((Statistic _stat) {
      setState(() {
        statistics.add(_stat);
      });
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {});
  }

  Future<void> refreshProfile() async {
    statistics.clear();
    user = new User();
    listenForStatistics();
    listenForUser();
  }


  updateProfileImage(File image) async{
    String uuid = await uploadImage(image);
    if(uuid == null) {
      setState(() => isUploadingImage = false);
      return;
    }
    currentUser.value.avatar = uuid;
    update(currentUser.value).then((value) =>
        setState(() => {
          imageUri = value.image.url,
          isUploadingImage = false
        })
    );
  }
}
