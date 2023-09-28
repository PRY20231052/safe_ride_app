// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../styles.dart';
import 'map_screen.dart';
import 'sing_up_screen.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});
  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget emailTextField = TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        style: MyTextStyles.hintTextStyle,
        decoration: Templates.inputDecoration('Email', CupertinoIcons.mail));

    Widget passwordTextField = TextField(
        controller: passwordController,
        style: MyTextStyles.hintTextStyle,
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        decoration: Templates.inputDecoration('Password', CupertinoIcons.lock));

    return Scaffold(
      backgroundColor: MyColors.white,
      body: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: Templates.paddingApp,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(),
                    Column(
                      children: [
                        const Text('Sign In', style: MyTextStyles.title),
                        SizedBox(height: 5,),
                        emailTextField,
                        SizedBox(height: 5,),
                        passwordTextField,
                        SizedBox(height: 5,),
                        Container(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: MyButtonStyles.primary,
                            child: Text('Login', style: MyTextStyles.button1,),
                            onPressed: () {
                              Navigator.push(context, CupertinoPageRoute(builder: (context) => MapScreen()));
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?"),
                        TextButton(
                          child: Text('Sign Up'),
                          onPressed: () {
                            Navigator.push(context, CupertinoPageRoute(builder: (context) => SignUpScreen()));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )),
    );
  }
}