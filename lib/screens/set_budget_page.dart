import 'package:flutter/material.dart';

class SetBudgetPage extends StatefulWidget {
  static const String id = 'set_budget_page';

  const SetBudgetPage({super.key});

  @override
  SetBudgetPageState createState() => SetBudgetPageState();
}

class SetBudgetPageState extends State<SetBudgetPage> {
  List<Map<String, dynamic>> goals = [
    {
      "icon": Icons.directions_bike,
      "title": "New Bike",
      "currentAmount": 300,
      "goalAmount": 600,
    },
    {
      "icon": Icons.phone_iphone,
      "title": "iPhone 15 Pro",
      "currentAmount": 700,
      "goalAmount": 1000,
    },
  ];

  void _addNewGoal() {
    // Dummy function to simulate adding a new goal
    setState(() {
      goals.add({
        "icon": Icons.laptop_mac,
        "title": "New Laptop",
        "currentAmount": 400,
        "goalAmount": 1200,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("New goal added")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Your Goals", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text(
              "All Goals",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  double progress = goal['currentAmount'] / goal['goalAmount'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          radius: 25,
                          child: Icon(goal['icon'], color: Colors.black54),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: progress,
                                color: Colors.blue.shade400,
                                backgroundColor: Colors.grey.shade300,
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "\$${goal['currentAmount']}",
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    "\$${goal['goalAmount']}",
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewGoal,
        backgroundColor: Colors.blue.shade400,
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        color: Colors.white,
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.home, color: Colors.grey.shade700),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Home")),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.checklist, color: Colors.grey.shade700),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Checklist")),
                  );
                },
              ),
              SizedBox(width: 40), // spacing for the FAB
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.grey.shade700),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Notifications")),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.grey.shade700),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Settings")),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
