import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'users_data.dart';
import 'auth_screen.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'stream_builder_with_listener.dart';

class CoinDeskData{
  String updated;
  String usdBTC;
  String eurBTC;
  CoinDeskData([this.updated = '-', this.usdBTC = '-', this.eurBTC = '-', ]);

  factory CoinDeskData.fromJson(Map<String, dynamic> json) {
    String updated='', usd, eur;
    Map<String, dynamic> tmpMap =json['time'];
    updated = tmpMap['updated'];

    tmpMap = json['bpi'];
    tmpMap = tmpMap['USD'];
    usd = tmpMap['rate'];

    tmpMap = json['bpi'];
    tmpMap = tmpMap['EUR'];
    eur = tmpMap['rate'];

    return CoinDeskData(updated, usd, eur,);
  }
}

enum MainEvent{logout}

class MainState{
  bool logout;
  CoinDeskData coinData = CoinDeskData();
  MainState([this.logout = false]);
}

class MainBloc extends Bloc<MainEvent, MainState> {
  Timer? dataSync;

  MainState state = MainState();
  final StreamController<MainState> stateController = StreamController<MainState>.broadcast();

  @override
  MainBloc() : super(MainState()) {
    httpGetData();
    on<MainEvent>((MainEvent event, Emitter<MainState> emit) {
      if(event == MainEvent.logout) {
        auth.logOut();
        state.logout = true;
      }
      stateController.sink.add(state);
    },
    );
  }

  void httpGetData() async{
    var response = await http.get(Uri.parse('https://api.coindesk.com/v1/bpi/currentprice.json'));
    if (response.statusCode == 200) {
      state.coinData = CoinDeskData.fromJson(jsonDecode(response.body));
    }

    if(dataSync==null) {
      dataSync = Timer.periodic(Duration(milliseconds: 3000), (Timer t) {httpGetData();});
    }

    if(!stateController.isClosed) {
      stateController.sink.add(state);
    }
  }

  @override
  Future<void> close() async {
    dataSync?.cancel();
    stateController.close();
    return super.close();
  }

}

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  Widget getBody( ) {
    MainBloc _bloc = BlocProvider.of(context, listen: true);
      return StreamListenableBuilder<MainState>(
         listener: (value) {
          if(_bloc.state.logout) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(), child: AuthScreen(), )), (Route<dynamic> route) => false);
            }
          },
        stream: _bloc.stateController.stream,
        builder: (BuildContext context, AsyncSnapshot<MainState>snapshot){
          return selectedIndex == 0? Center(
            child: Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(0, 40, 0, 20),
                child: Row(children: [const Expanded(child: Text('Биткойн:', textAlign: TextAlign.right), flex: 27),Expanded(child: Container(), flex:6), Expanded(child: Container(),flex:47)]),),
              Padding(padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Row(children: [const Expanded(child: Text('Updated:', textAlign: TextAlign.right), flex: 27),Expanded(child: Container(), flex:6), Expanded(child: Text(_bloc.state.coinData.updated),flex:47)]),),
              Padding(padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Row(children: [const Expanded(child: Text('USD:', textAlign: TextAlign.right), flex: 27),Expanded(child: Container(), flex:6), Expanded(child: Text(_bloc.state.coinData.usdBTC),flex:47)]),),
              Padding(padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                child: Row(children: [const Expanded(child: Text('EUR:',textAlign: TextAlign.right), flex: 27),Expanded(child: Container(), flex:6), Expanded(child: Text(_bloc.state.coinData.eurBTC),flex:47)]),),
            ]),
          ):Center(
            child: Column(children: [
              const Padding(padding: EdgeInsets.fromLTRB(0, 40, 0, 20), child: Text('Данные пользователя'),),
              Padding(padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Row(children: [const Expanded(child: Text('Логин:', textAlign: TextAlign.right), flex: 47),Expanded(child: Container(), flex:6), Expanded(child: Text(auth.currentUser.login),flex:47)]),),
              Padding(padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Row(children: [const Expanded(child: Text('Имя:', textAlign: TextAlign.right), flex: 47),Expanded(child: Container(), flex:6), Expanded(child: Text(auth.currentUser.name),flex:47)]),),
              Padding(padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                child: Row(children: [const Expanded(child: Text('Время регистрации:',textAlign: TextAlign.right), flex: 47),Expanded(child: Container(), flex:6), Expanded(child: Text(auth.currentUser.registrationDateTime.substring(0,19)),flex:47)]),),

              Padding(padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
                child: Row( children: [
                  Expanded(child: Container(),flex: 30),
                  Expanded(child: ElevatedButton(onPressed: (){
                    _bloc.add(MainEvent.logout);
                  },
                      child: const Text('Выйти', maxLines: 1, textScaleFactor: 1.0)),flex: 30),
                  Expanded(child: Container(),flex: 30),
                ]),),
            ]),
          );
      },);
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          title: const Text('Информация')),
      body:  getBody(),
      bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Coin",),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile",)
      ],
      onTap: (int index) {
        setState(() {selectedIndex = index;});
      },
    ),
    );
  }
}
