import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_work_230322/main_screen.dart';
import 'package:test_work_230322/register_screen.dart';
import 'users_data.dart';
import 'dart:async';
import 'stream_builder_with_listener.dart';

class AuthInputData{
  String login = '';
  String pass = '';
  AuthInputData(this.login, this.pass);
}

class AuthState{
  bool loginIsEmpty;
  bool passIsEmpty;
  bool loginOrPassIsWrong;
  bool authOK = false;
  bool authReadingGoing = true;

  AuthState([this.loginIsEmpty = false,
    this.passIsEmpty = false, this.loginOrPassIsWrong = false]);
}

class AuthBloc extends Bloc<AuthInputData, AuthState> {

  AuthState state = AuthState();
  final StreamController<AuthState> stateController = StreamController<AuthState>();

  authCheck() async {
    await auth.readData();
    if(auth.isLogIn){
      state.authOK = true;
    }
    else {
      state.authReadingGoing = false;
    }
    stateController.sink.add(state);
  }

  @override
  AuthBloc() : super(AuthState()) {
    authCheck();

    on<AuthInputData>((AuthInputData inputData, Emitter<AuthState> emit) {
        inputDataValidate(inputData);
        if((!state.loginOrPassIsWrong)&&(!state.loginIsEmpty)&&(!state.passIsEmpty)) {
          if(auth.validateUser(inputData.login, inputData.pass)) {
            state.authOK = true;
            state.loginOrPassIsWrong = false;
          }
          else{
            state.authOK = false;
            state.loginOrPassIsWrong = true;
          }
        }
        else {
          state.loginOrPassIsWrong = false;
        }
        stateController.sink.add(state);
      },
    );
  }

  inputDataValidate(AuthInputData inputData){
    inputData.login.isEmpty? state.loginIsEmpty = true:state.loginIsEmpty = false;
    inputData.pass.isEmpty? state.passIsEmpty = true:state.passIsEmpty = false;
  }
}

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    AuthBloc _bloc = BlocProvider.of(context, listen: true);
    String tmpLogin = '', tmpPass = '';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          title: const Text('Авторизация')),
      body:
        StreamListenableBuilder<AuthState>(
          listener: (value) {
            if(_bloc.state.authOK) {
              Navigator.pushAndRemoveUntil(
                  context, MaterialPageRoute(builder: (context) => BlocProvider<MainBloc>(
                    create: (context) => MainBloc(), child: MainScreen(),)), (Route<dynamic> route) => false);
            }
          },
        stream: _bloc.stateController.stream,
        builder: (BuildContext context, AsyncSnapshot<AuthState>snapshot){

          InputDecoration loginInputDecoration = const InputDecoration();
          if(_bloc.state.loginIsEmpty) {
            loginInputDecoration = const InputDecoration(errorText: 'введите логин');
          }

          InputDecoration passInputDecoration = const InputDecoration();
          if(_bloc.state.passIsEmpty) {
            passInputDecoration = const InputDecoration(errorText: 'введите пароль');
          }

          return _bloc.state.authReadingGoing?
            const Center( child: Icon(Icons.hourglass_top)):
            Center(child: Stack( children:[
              Column(children: [
                Container( padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), child: Column( children:[
                  _bloc.state.loginOrPassIsWrong?
                  Padding( padding: const EdgeInsets.fromLTRB(0, 0, 0, 10), child:
                    Text('Неверный логин или пароль', maxLines: 1,
                      style: Theme.of(context).textTheme.bodyText1?.apply(color: Colors.red),),):
                  Container(),
                  const Text('Введите логин:', maxLines: 1, textScaleFactor: 1.0),
                  TextFormField(onChanged: (text) {tmpLogin = text;}, decoration: loginInputDecoration),
                ],),),
                Container( padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), child: Column( children:[
                  const Text('Введите пароль:', maxLines: 1, textScaleFactor: 1.0),
                  TextFormField(onChanged: (text) {tmpPass = text;}, decoration: passInputDecoration),
                ],),),
                ElevatedButton(onPressed: (){ _bloc.add(AuthInputData(tmpLogin, tmpPass));},
                  child: const Text('Войти', maxLines: 1, textScaleFactor: 1.0)),
              ],),
              Container(alignment: Alignment.bottomCenter, padding: const EdgeInsets.only(bottom: 15),
                child: ElevatedButton(onPressed: (){
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => BlocProvider<RegistrationBloc>(
                    create: (context) => RegistrationBloc(), child: RegisterScreen(), )), (Route<dynamic> route) => false);
                  },
                  child: const Text('Регистрация', maxLines: 1, textScaleFactor: 1.0)),),
            ],),
        );},),
    );
  }
}
