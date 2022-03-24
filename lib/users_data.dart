import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class UserDataItem{
  String login='';
  String name='';
  String pass='';
  String registrationDateTime;

  UserDataItem(this.login, this.name, this.pass, this.registrationDateTime);

  factory UserDataItem.fromJson(Map<String, dynamic> jsonData) {
    return UserDataItem(
      jsonData['login'],
      jsonData['name'],
      jsonData['pass'],
      jsonData['registrationDateTime'],
    );
  }

  static Map<String, dynamic> toMap(UserDataItem userDataItem) => {
    'login': userDataItem.login,
    'name': userDataItem.name,
    'pass': userDataItem.pass,
    'registrationDateTime': userDataItem.registrationDateTime,
  };

  static String encode(List<UserDataItem> userDataItems) => json.encode(
    userDataItems.map<Map<String, dynamic>>((userDataItem) => UserDataItem.toMap(userDataItem)).toList(),
  );

  static String encodeSingle(UserDataItem userDataItem) => json.encode(
    UserDataItem.toMap(userDataItem)
  );

  static List<UserDataItem> decode(String userDataItems) => (json.decode(
      userDataItems) as List<dynamic>).map<UserDataItem>((item) => UserDataItem.fromJson(item)).toList();

  static UserDataItem decodeSingle(String userDataItem) {
    return UserDataItem.fromJson(json.decode(userDataItem));
  }
}

class Auth{
  bool isLogIn = false;

  List<UserDataItem> userDataList = List.empty(growable: true);
  UserDataItem currentUser = UserDataItem('?', '?', '?', '?');
  SharedPreferences? prefs;

  readData() async{
    prefs = await SharedPreferences.getInstance();
    String? userDataString = await prefs?.getString('users');
    if(userDataString!=null) {
      userDataList = UserDataItem.decode(userDataString);
    }

    String? currentUserDataString = await prefs?.getString('current user');
    if(currentUserDataString!=null) {
      currentUser = UserDataItem.decodeSingle(currentUserDataString);
      isLogIn = true;
    }
  }

  saveUser(String login, String name, String pass) async {
    userDataList.add(UserDataItem(login, name, pass, DateTime.now().toString()));
    String newUsersString = UserDataItem.encode(userDataList);
    await prefs?.setString('users', newUsersString);
  }

  bool checkUserLoginIsReady(String login){
    bool compareResult = false;
    if(userDataList.isNotEmpty) {
      userDataList.forEach((element) {
        if (element.name == login) {
          compareResult = true;
        }
      });
      if(compareResult) return false;
    }
    return true;
  }

  bool validateUser(String login, String pass){
    bool validateResult = false;
    if(userDataList.isNotEmpty) {
      userDataList.forEach((element) {
        if ((element.login == login)&&(element.pass==pass)) {
          validateResult = true;
          currentUser = element;

          String currentUserString = UserDataItem.encodeSingle(currentUser);
          prefs?.setString('current user', currentUserString);
        }
      });
    }
    return validateResult;
  }

  logOut(){
    isLogIn = false;
    prefs?.remove('current user');
  }

  clear(){
    prefs?.clear();
  }
}

Auth  auth = Auth();
