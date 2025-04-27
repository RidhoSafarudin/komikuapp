import 'package:flutter/material.dart';

class MyKisahPage extends StatelessWidget {
  const MyKisahPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Kisah'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Introduksi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 16),
              Text(
                'Aplikasi myKisah merupakan platform digital yang memungkinkan pengguna untuk menulis, '
                'membagikan, dan membaca cerita pendek dalam berbagai genre.\n\n'
                'Aplikasi ini dirancang untuk para penulis, pembaca, dan pecinta cerita yang mencari pengalaman '
                'membaca yang ringkas dan membuat interaksi antara penulis dan pembaca lebih mudah untuk '
                'memberikan tanggapan.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5, // supaya spasi antar baris lebih enak dibaca
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
