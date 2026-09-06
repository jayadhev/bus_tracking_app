
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform.copyWith(
      databaseURL:
          'https://sathyabama-bus-tracker-2259a-default-rtdb.firebaseio.com',
    ),
  );

  runApp(const SathyabamaBusTracker());
}

class SathyabamaBusTracker extends StatelessWidget {
  const SathyabamaBusTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sathyabama Bus Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SATHYABAMA BUS TRACKER'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_bus,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Sathyabama Bus Tracker',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Track your college bus in real time',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentHome(),
                      ),
                    );
                  },
                  child: const Text('STUDENT'),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('STAFF'),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('ADMIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BUS 12'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref()
            .child('buses')
            .child('BUS12')
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Firebase Error:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                'BUS 12 data not found.',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          final value = snapshot.data!.snapshot.value;

          if (value is! Map) {
            return const Center(
              child: Text(
                'Invalid Firebase data.',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          final data = Map<dynamic, dynamic>.from(value);

          final busNumber = data['busNumber'] ?? 'BUS 12';
          final latitude = data['latitude'] ?? 0;
          final longitude = data['longitude'] ?? 0;
          final speed = data['speed'] ?? 0;
          final status = data['status'] ?? 'UNKNOWN';
          final breakdown = data['breakdown'] ?? false;
          final emergency = data['emergency'] ?? false;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.directions_bus,
                size: 70,
                color: Colors.blue,
              ),
              const SizedBox(height: 10),
              const Text(
                'LIVE BUS TRACKING',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.directions_bus,
                    size: 35,
                  ),
                  title: const Text('Bus Number'),
                  subtitle: Text(
                    busNumber.toString(),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Status'),
                  subtitle: Text(
                    status.toString(),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Latitude'),
                  subtitle: Text(
                    latitude.toString(),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Longitude'),
                  subtitle: Text(
                    longitude.toString(),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Speed'),
                  subtitle: Text(
                    '$speed km/h',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.build,
                    color: breakdown == true
                        ? Colors.red
                        : Colors.green,
                  ),
                  title: const Text('Breakdown'),
                  subtitle: Text(
                    breakdown == true
                        ? 'BREAKDOWN REPORTED'
                        : 'No Breakdown',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.warning,
                    color: emergency == true
                        ? Colors.red
                        : Colors.green,
                  ),
                  title: const Text('Emergency'),
                  subtitle: Text(
                    emergency == true
                        ? 'EMERGENCY ALERT!'
                        : 'No Emergency',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Live map will be added next.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('VIEW LIVE MAP'),
              ),
            ],
          );
        },
      ),
    );
  }
}
