import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'users_data.dart';
import 'auth_screen.dart';
import 'stream_builder_with_listener.dart';
import 'main_screen.dart';

class RegistrationInputData{
  String login = '';
  String pass = '';
  String name = '';
  RegistrationInputData(this.login, this.name, this.pass);
}

class RegistrationState{
  bool loginIsAlready;
  bool loginIsEmpty;
  bool nameIsEmpty;
  bool passIsEmpty;
  bool registrationOK = false;

  RegistrationState([this.loginIsAlready = false, this.loginIsEmpty = false, this.nameIsEmpty = false, this.passIsEmpty = false]);
}

class RegistrationBloc extends Bloc<RegistrationInputData, RegistrationState> {
  RegistrationState state = RegistrationState();
  final StreamController<RegistrationState> stateController = StreamController<RegistrationState>();

  @override
  RegistrationBloc() : super(RegistrationState()) {
    on<RegistrationInputData>(
          (RegistrationInputData inputData, Emitter<RegistrationState> emit) {
            inputDataValidate(inputData);
            if((!state.passIsEmpty)&&(!state.nameIsEmpty)&&(!state.loginIsEmpty)&&(!state.loginIsAlready)) {
              auth.saveUser(inputData.login, inputData.name, inputData.pass);
              if(auth.validateUser(inputData.login, inputData.pass)) {
                state.registrationOK = true;
              }
            }
            stateController.sink.add(state);
          },
    );
  }

  inputDataValidate(RegistrationInputData inputData){
    inputData.login.isEmpty? state.loginIsEmpty = true:state.loginIsEmpty = false;
    auth.checkUserLoginIsReady(inputData.name)? state.loginIsAlready = false:state.loginIsAlready = true;
    inputData.name.isEmpty? state.nameIsEmpty = true:state.nameIsEmpty = false;
    inputData.pass.isEmpty? state.passIsEmpty = true:state.passIsEmpty = false;
  }
}


class RegisterScreen extends StatefulWidget {

  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {

  @override
  Widget build(BuildContext context) {
    RegistrationBloc _bloc = BlocProvider.of(context, listen: true);
    String tmpLogin = '', tmpName = '', tmpPass = '';

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
            title: const Text('Регистрация')),
        body:
        StreamListenableBuilder<RegistrationState>(
        listener: (value) {
          if(_bloc.state.registrationOK) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => BlocProvider<MainBloc>(
              create: (context) => MainBloc(), child: MainScreen(), )), (Route<dynamic> route) => false);
          }
        },
        stream: _bloc.stateController.stream,
        builder: (BuildContext context, AsyncSnapshot<RegistrationState>snapshot){
          InputDecoration loginInputDecoration = const InputDecoration();
          if(_bloc.state.loginIsEmpty) {
            loginInputDecoration = const InputDecoration(errorText: 'введите логин');
          }
          else if(_bloc.state.loginIsAlready) {
            loginInputDecoration = const InputDecoration(errorText: 'такой пользователь уже существует');
          }
          InputDecoration nameInputDecoration = const InputDecoration();
          if(_bloc.state.nameIsEmpty) {
            nameInputDecoration = const InputDecoration(errorText: 'введите имя');
          }

          InputDecoration passInputDecoration = const InputDecoration();
          if(_bloc.state.passIsEmpty) {
            passInputDecoration = const InputDecoration(errorText: 'введите пароль');
          }

        return Center(
          child: Stack( children:[
            Column(children: [
              Container(padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), child: Column( children:[
                const Text('Введите логин:', maxLines: 1, textScaleFactor: 1.0),
                TextFormField(onChanged: (text) {tmpLogin = text;}, decoration: loginInputDecoration),
              ],),),
              Container(padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), child: Column( children:[
                const Text('Введите имя:', maxLines: 1, textScaleFactor: 1.0),
                TextFormField(decoration: nameInputDecoration, onChanged: (text) {tmpName = text;},),
              ],),),
              Container( padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), child: Column( children:[
                const Text('Введите пароль:', maxLines: 1, textScaleFactor: 1.0),
                TextFormField(onChanged: (text) {tmpPass = text;}, decoration: passInputDecoration),
              ],),),
              ElevatedButton(onPressed: (){
                _bloc.add(RegistrationInputData(tmpLogin, tmpName, tmpPass));
                },
                  child: const Text('Зарегистрироваться', maxLines: 1, textScaleFactor: 1.0)),
            ],),
            Container(alignment: Alignment.bottomCenter, padding: const EdgeInsets.only(bottom: 15),
              child: ElevatedButton(onPressed: (){
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => BlocProvider<AuthBloc>(
                  create: (context) => AuthBloc(), child: AuthScreen(), )), (Route<dynamic> route) => false);
                },
                child: const Text('Вход', maxLines: 1, textScaleFactor: 1.0)),),
          ],),
        );},
    ),);
  }
}
