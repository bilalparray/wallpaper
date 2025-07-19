import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class ApiPage extends StatefulWidget {
  const ApiPage({super.key});

  @override
  State<ApiPage> createState() => _ApiPageState();
}

class _ApiPageState extends State<ApiPage> {
  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  List<dynamic> users = [];
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Api Page'),
      ),
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (BuildContext context, int index) {
          final user = users[index];
          return CupertinoListTile(title: user['name']['first']);
        },
      ),
    );
  }

  void fetchUsers() async {
    final uri = Uri.parse('https://randomuser.me/api/?results=200');
    final resp = await http.get(uri);
    final data = resp.body;
    final finalData = jsonDecode(data);
    setState(() {
      users = finalData['results'];
    });
    print(users);
  }
}
