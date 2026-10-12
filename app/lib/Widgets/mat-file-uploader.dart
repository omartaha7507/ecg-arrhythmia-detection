import 'package:ecg_analysis2/Screens/result-screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class MatFileUploader extends StatefulWidget {
  @override
  _MatFileUploaderState createState() => _MatFileUploaderState();
}

class _MatFileUploaderState extends State<MatFileUploader> {
  bool _isLoading = false;
  String? _error;

  // Replace with your server URL
  final String serverUrl = "http://10.0.2.2:8000/predict-mat";

  Future<void> _pickAndUploadFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Pick .mat file
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        String fileName = result.files.single.name;
        if (fileName.toLowerCase().endsWith('.mat')) {
          await _uploadFile(file);
        } else {
          setState(() {
            _error = 'Please select a .mat file';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'No file selected';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking file: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadFile(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(serverUrl));

      // Add file to request
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Send request
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        setState(() {
          _isLoading = false;
        });
        Navigator.pushNamed(
          context,
          ResultScreen.path,
          arguments: jsonResponse,
        );
      } else {
        var errorResponse = json.decode(responseBody);
        setState(() {
          _error = errorResponse['error'] ?? 'Unknown error occurred';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isLoading ? null : _pickAndUploadFile,
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Processing...',
                        style: TextStyle(color: Color(0xFF1976D2)),
                      ),
                    ],
                  )
                : Text(
                    'Pick & Upload .mat File',
                    style: TextStyle(color: Color(0xFF1976D2)),
                  ),
          ),
          SizedBox(height: 20),
          if (_error != null)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                'Error: $_error',
                style: TextStyle(color: Colors.red[800]),
              ),
            ),
        ],
      ),
    );
  }
}
