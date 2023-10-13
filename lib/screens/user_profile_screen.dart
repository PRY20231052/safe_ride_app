// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, prefer_const_literals_to_create_immutables
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:safe_ride_app/models/favorite_location_model.dart';
import 'package:safe_ride_app/models/location_model.dart';
import 'package:safe_ride_app/providers/user_provider.dart';
import '../styles.dart';

class UserProfileScreen extends StatefulWidget {
  final Function(LocationModel)? dropMarker;
  const UserProfileScreen({super.key, this.dropMarker});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {

  late UserProvider readUserProv;
  late UserProvider watchUserProv;

  TextEditingController usernameController= TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController fullNameController= TextEditingController();
  TextEditingController passwordController = TextEditingController();

  TextEditingController aliasController = TextEditingController();

  bool showRegisterForm = false;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    readUserProv = context.read<UserProvider>();
    watchUserProv = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: MyColors.white,
      body: SafeArea(
        // minimum: EdgeInsets.only(left: 25, right: 25, top: 25),
        child: Container(
          margin: EdgeInsets.only(left: 25, right: 25, top: 25),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.close_rounded, size: 35,),
                    onPressed: (){
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              watchUserProv.user == null ? showRegisterForm ? registerForm() : logInForm() : userProfile(),
            ],
          ),
        ),
      ),
    );
  }

  Widget userProfile(){
    double profilePictureSize = 120;
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: 10, bottom: 10, right: 10),
          width: profilePictureSize,
          height: profilePictureSize,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(profilePictureSize/2),
            border: Border.all(
              width: 4,
              color: MyColors.grey,
            ),
          ),
          child: Image.asset('assets/user1.png', color: MyColors.grey,),
        ),
        Text(watchUserProv.user!.userName, style: MyTextStyles.h1,),
        Text(watchUserProv.user!.email, style: MyTextStyles.h4,),
        SizedBox(height: 10,),
        OutlinedButton(
          style: MyButtonStyles.outlinedRed,
          child: Text('Cerrar Sesión', style: MyTextStyles.outlinedRed,),
          onPressed: () {
            readUserProv.user = null;
          },
        ),
        Divider(thickness: 2, height: 40,),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text('Nombre completo: ${watchUserProv.user!.fullName}', style: MyTextStyles.h3,),
            // Text('Número de teléfono: ${watchUserProv.user!.phoneNumber}', style: MyTextStyles.h3,),
            // SizedBox(height: 20,),
            Text('Tus Lugares Favoritos', style: MyTextStyles.h2,),
            SizedBox(height: 20,),
            Container(
              width: double.infinity,
              height: 450, // temporal fix
              child: watchUserProv.user!.favoriteLocations.isNotEmpty ? ListView.separated(
                // shrinkWrap: true,
                // physics: AlwaysScrollableScrollPhysics(),
                itemCount: watchUserProv.user!.favoriteLocations.length,
                itemBuilder: (context, index) => favoriteLocationTile(index),
                separatorBuilder: (context, index) => SizedBox(height: 10,),
              ) : Text('No tienes lugares favoritos guardados', style: MyTextStyles.h4,),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> showEditFavoriteLocationDialog(FavoriteLocationModel favoriteLocation) async {
    aliasController.text = favoriteLocation.alias;
    return await showDialog(
      context: context,
      builder: (context){
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 30,
          title: Text('Editar Alias'),
          content: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: MyColors.lightGrey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: aliasController,
              decoration: MyTextFieldStyles.mainInput(
                hintText: 'Alias'
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          contentPadding: EdgeInsets.only(left: 12, top: 12, right: 12),
          actions: [
            Container(
              width: 120,
              child: OutlinedButton(
                style: MyButtonStyles.outlinedRed,
                child: Text('Cancelar', style: MyTextStyles.outlinedRed,),
                onPressed: (){
                  Navigator.pop(context);
                },
              ),
            ),
            Container(
              width: 120,
              child: ElevatedButton(
                style: MyButtonStyles.primaryNoElevation,
                child: Text('Guardar', style: MyTextStyles.button2,),
                onPressed: () {
                  favoriteLocation.alias = aliasController.text;
                  readUserProv.modifyFavoriteLocation(favoriteLocation.id!, favoriteLocation);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget favoriteLocationTile(int index){
    var favoriteLocation = watchUserProv.user!.favoriteLocations[index];
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: MyColors.lightGrey,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Text(favoriteLocation.alias.isNotEmpty ? favoriteLocation.alias: favoriteLocation.name!, style: MyTextStyles.h2,),
        subtitle: Text(
          favoriteLocation.address!,
          style: MyTextStyles.h4,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.all(10),
              constraints: BoxConstraints(),
              onPressed: (){
                showEditFavoriteLocationDialog(favoriteLocation);
              },
              icon: Icon(Icons.edit),
            ),
            IconButton(
              padding: EdgeInsets.all(10),
              constraints: BoxConstraints(),
              onPressed: (){
                readUserProv.deleteFavoriteLocation(favoriteLocation.id!);
              },
              icon: Icon(Icons.delete),
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          if(widget.dropMarker != null){
            widget.dropMarker!(favoriteLocation);
          }
        },
      ),
    );
  }

  Widget logInForm(){
    return Column(
      children: [
        Text('Iniciar Sesión', style: MyTextStyles.title),
        SizedBox(height: 20,),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: MyColors.lightGrey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: MyTextStyles.inputTextStyle,
                decoration: MyTextFieldStyles.mainInput(
                  hintText: 'Email',
                  prefixIcon: Icon(CupertinoIcons.mail),
                ),
              ),
              SizedBox(height: 10,),
              TextField(
                controller: passwordController,
                style: MyTextStyles.inputTextStyle,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                decoration: MyTextFieldStyles.mainInput(
                  hintText: 'Password',
                  prefixIcon: Icon(CupertinoIcons.lock),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20,),
        Container(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            style: MyButtonStyles.primary,
            child: Text('INGRESAR', style: MyTextStyles.button1,),
            onPressed: () async {
              if(emailController.text == '' || passwordController.text == ''){
                Fluttertoast.showToast(
                  msg: "Ingrese la información solicitada",
                  toastLength: Toast.LENGTH_LONG
                );
                return;
              }
              bool success = await readUserProv.login(email: emailController.text, password: passwordController.text);
              if (!success){
                Fluttertoast.showToast(
                  msg: "Usuario no registrado",
                  toastLength: Toast.LENGTH_LONG
                );
                return;
              }
            },
          ),
        ),
        SizedBox(height: 5,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("No tienes una cuenta?"),
            TextButton(
              child: Text('Registrate aquí',),
              onPressed: () {
                showRegisterForm = true;
                setState(() {});
                // Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget registerForm(){
    List<Widget> textFields = [
      TextField(
        controller: usernameController,
        keyboardType: TextInputType.name,
        style: MyTextStyles.inputTextStyle,
        decoration: MyTextFieldStyles.mainInput(
          hintText: 'Nombre de Usuario',
          prefixIcon: Icon(CupertinoIcons.person),
        ),
      ),
      TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        style: MyTextStyles.inputTextStyle,
        decoration: MyTextFieldStyles.mainInput(
          hintText: 'Correo Electrónico',
          prefixIcon: Icon(CupertinoIcons.mail),
        ),
      ),
      TextField(
        controller: fullNameController,
        keyboardType: TextInputType.name,
        style: MyTextStyles.inputTextStyle,
        decoration: MyTextFieldStyles.mainInput(
          hintText: 'Nombre Completo',
          prefixIcon: Icon(CupertinoIcons.person),
        ),
      ),
      TextField(
        controller: passwordController,
        keyboardType: TextInputType.visiblePassword,
        style: MyTextStyles.inputTextStyle,
        obscureText: true,
        decoration: MyTextFieldStyles.mainInput(
          hintText: 'Contraseña',
          prefixIcon: Icon(CupertinoIcons.lock),
        ),
      ),
    ];
    return Column(
      children: [
        Text('Registro de Usuario', style: MyTextStyles.title),
        SizedBox(height: 20,),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: MyColors.lightGrey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: textFields.length,
            itemBuilder: (context, index) => textFields[index],
            separatorBuilder: (context, index) => SizedBox(height: 10,),
          ),
        ),
        SizedBox(height: 20,),
        Container(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            style: MyButtonStyles.primary,
            child: Text('REGISTRARME', style: MyTextStyles.button1,),
            onPressed: () async {
              if(emailController.text == '' || passwordController.text == '' || usernameController.text == ''){
                Fluttertoast.showToast(
                  msg: "Ingrese la información solicitada",
                  toastLength: Toast.LENGTH_LONG
                );
                return;
              }

              bool success = await readUserProv.register(
                email: emailController.text,
                password: passwordController.text,
                username: usernameController.text,
                fullName: fullNameController.text,
              );
              if (!success){
                Fluttertoast.showToast(
                  msg: "Error al intentar registrar el usuario",
                  toastLength: Toast.LENGTH_LONG
                );
                return;
              }
            },
          ),
        ),
        SizedBox(height: 5,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ya tienes una cuenta?"),
            TextButton(
              child: Text('Inicia sesión aquí',),
              onPressed: () {
                showRegisterForm = false;
                setState(() {});
              },
            ),
          ],
        ),
      ],
    );
  }
}