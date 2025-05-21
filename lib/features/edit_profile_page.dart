import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String username = 'username';
  String bio = 'Bio';
  bool isEditingUsername = false;
  bool isEditingBio = false;
  TextEditingController _controller = TextEditingController();

  void _startEditing(String field) {
    setState(() {
      if (field == 'username') {
        isEditingUsername = true;
        _controller.text = username;
      } else if (field == 'bio') {
        isEditingBio = true;
        _controller.text = bio;
      }
    });
  }

  void _saveChanges() {
  setState(() {
    if (isEditingUsername) {
      username = _controller.text;
      isEditingUsername = false;
    } else if (isEditingBio) {
      bio = _controller.text;
      isEditingBio = false;
    }
    _controller.clear();
  });

  // Kirim data balik ke ProfilePage
  Navigator.pop(context, {
    'username': username,
    'bio': bio,
  });
}

  void _cancelEditing() {
    setState(() {
      isEditingUsername = false;
      isEditingBio = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Ganti bingkai action
            },
            child: Text('ganti bingkai'),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text(username),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _startEditing('username'),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text(bio),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _startEditing('bio'),
                  ),
                ),
              ],
            ),
          ),
          if (isEditingUsername || isEditingBio)
            Container(
              color: Colors.blue.shade100,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditingUsername ? 'Ubah Username' : 'Ubah Bio'),
                  TextField(controller: _controller),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _cancelEditing,
                        child: Icon(Icons.close),
                      ),
                      ElevatedButton(
                        onPressed: _saveChanges,
                        child: Text('Ubah'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}