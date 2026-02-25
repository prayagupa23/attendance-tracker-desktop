// main_content.dart
import 'package:flutter/material.dart';
import 'package:final_year_project_desktop/screens/faculty_dashboard.dart';
import 'info_row.dart';

class MainContent extends StatelessWidget{
  const MainContent({super.key}); 
  
  @override
  Widget build(BuildContext context){
    return Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [

                        // Title
                        Text(
                          "Image Processing",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10),
                        Divider(),
                        SizedBox(height: 10),

                        // Info rows
                        InfoRow(label: "Lecturer", value: "Manjiri Samant"),
                        InfoRow(label: "Time Slot", value: "10:30 to 11:30"),
                        InfoRow(label: "Room No.", value: "207"),
                        InfoRow(label: "Department", value: "Computer"),
                        InfoRow(label: "Batch", value: "TYCO"),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex:3,
                child: Card(
                  elevation: 4,
                  child: Container(
                    
                  )
                )
              )
            ],
      );
  }
}