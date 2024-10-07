// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DataProvider dataProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.initialize(context);
    });
  }

  @override
  void dispose() {
    dataProvider.dispose();
    super.dispose();
  }

  Widget _buildDeviceDataList() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (dataProvider.deviceData.isEmpty) {
          return Center(child: Text('No hay datos disponibles.'));
        }

        return ListView.builder(
          itemCount: dataProvider.deviceData.length,
          itemBuilder: (context, index) {
            final data = dataProvider.deviceData[index];
            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text('Temperatura: ${data['Temperature']}°C'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SetPoint: ${data['SetPoint']}°C'),
                    Text('RunTime: ${data['RunTime']}'),
                    Text(
                        'GPS: ${data['GPS']['Latitude']}, ${data['GPS']['Longitude']}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Termoking Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _buildDeviceDataList(),
    );
  }
}
