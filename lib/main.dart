import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_screen.dart';

void main() {
  runApp(
      MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(primarySwatch: Colors.blue,),
          home: BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(),
            child: AuthScreen(),
          ),
      )
  );
}
