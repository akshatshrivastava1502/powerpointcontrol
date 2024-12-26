import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Buttons',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ServerConfigScreen(),
    );
  }
}

class ServerConfigScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextEditingController ipController = TextEditingController();
    final TextEditingController portController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Server Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: ipController,
              decoration: InputDecoration(
                labelText: 'Server IP',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: portController,
              decoration: InputDecoration(
                labelText: 'Server Port',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final ip = ipController.text;
                final port = portController.text;

                if (ip.isNotEmpty && port.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageButtonsScreen(
                        serverUrl: 'http://$ip:$port',
                      ),
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Error'),
                      content: Text('Please enter both IP and Port.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageButtonsScreen extends StatefulWidget {
  final String serverUrl;

  const ImageButtonsScreen({required this.serverUrl});

  @override
  _ImageButtonsScreenState createState() => _ImageButtonsScreenState();
}

class _ImageButtonsScreenState extends State<ImageButtonsScreen> {
  List<String> _imageFiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final url = Uri.parse('${widget.serverUrl}/images');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _imageFiles = List<String>.from(json.decode(response.body));
        _loading = false;
      });
    } else {
      print('Failed to load images');
    }
  }

Future<void> _sendDataToServer(String data) async {
  final url = Uri.parse('${widget.serverUrl}/image');
  
  // Make sure you're sending 'image_index' as the key
  final response = await http.post(
    url,
    body: {'image_index': data},  // Correct parameter name ('image_index')
  );

  if (response.statusCode == 200) {
    print('Data sent successfully');
  } else {
    print('Failed to send data');
  }
}


  Future<Image> _loadImage(String imageName) async {
    final url = Uri.parse('${widget.serverUrl}/image/$imageName');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return Image.memory(response.bodyBytes);
    } else {
      throw Exception('Failed to load image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PowerTool'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_left),
            onPressed: () => _sendDataToServer('1000'),
          ),
          IconButton(
            icon: Icon(Icons.arrow_right),
            onPressed: () => _sendDataToServer('2000'),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 8.0, 
                mainAxisSpacing: 8.0, 
                childAspectRatio: 1, 
              ),
              itemCount: _imageFiles.length,
              itemBuilder: (context, index) {
                final imageFile = _imageFiles[index];

                return ElevatedButton(
                  onPressed: () => _sendDataToServer(index.toString()),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero, 
                    backgroundColor: Colors.transparent, 
                    elevation: 0, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0), 
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: FutureBuilder<Image>(
                          future: _loadImage(imageFile),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Icon(Icons.error));
                            } else {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8.0), 
                                child: snapshot.data!,
                              );
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          imageFile,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.0),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
