import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'firebase_options.dart';

const String databaseUrl =
    'https://sathyabama-bus-tracker-2259a-default-rtdb.firebaseio.com';

// Termini Coordinates
const double defaultLatitude = 12.8731;
const double defaultLongitude = 80.2210;

// Helper to determine route direction based on time of day
bool getAutoRouteDirection() {
  return DateTime.now().hour < 12;
}

// =====================================================
// OFFICIAL SATHYABAMA ROUTES DATA
// =====================================================

class SathyabamaRoute {
  final String routeNo;
  final String fullRouteString;
  final List<String> stops;

  SathyabamaRoute({
    required this.routeNo,
    required this.fullRouteString,
    required this.stops,
  });
}

final Map<String, SathyabamaRoute> officialRoutesMap = {
  '1': SathyabamaRoute(
      routeNo: '1',
      fullRouteString: 'Cheyyar - Kancheepuram - Walajabath - Oragadam - Padapai - Mannivakkam - Vandalore - Kandigai',
      stops: ['Cheyyar', 'Kancheepuram', 'Walajabath', 'Oragadam', 'Padapai', 'Mannivakkam', 'Vandalore', 'Kandigai', 'Sathyabama University']),
  '1A': SathyabamaRoute(
      routeNo: '1A',
      fullRouteString: 'Vandhavasi - Kancheepuram - Walajabath - Oragadam - Padapai - Mannivakkam - Vandalore - Kandigai - Kolabakkam - Mambakkam',
      stops: ['Vandhavasi', 'Kancheepuram', 'Walajabath', 'Oragadam', 'Padapai', 'Mannivakkam', 'Vandalore', 'Kandigai', 'Kolabakkam', 'Mambakkam', 'Sathyabama University']),
  '1B': SathyabamaRoute(
      routeNo: '1B',
      fullRouteString: 'Kancheepuram - Walajabath - Oragadam - Padapai - Mannivakkam - Vandalore - Kolabakkam - Kandigai',
      stops: ['Kancheepuram', 'Walajabath', 'Oragadam', 'Padapai', 'Mannivakkam', 'Vandalore', 'Kolabakkam', 'Kandigai', 'Sathyabama University']),
  '1C': SathyabamaRoute(
      routeNo: '1C',
      fullRouteString: 'Kancheepuram - Walajabath - Oragadam - Padapai - Mannivakkam - Vandalore - Kandigai - Mambakkam',
      stops: ['Kancheepuram', 'Walajabath', 'Oragadam', 'Padapai', 'Mannivakkam', 'Vandalore', 'Kandigai', 'Mambakkam', 'Sathyabama University']),
  '1D': SathyabamaRoute(
      routeNo: '1D',
      fullRouteString: 'Sriperumbudur - Pushpagiri - Manimangalam - Vandalore - Kolabakkam - Kandigai',
      stops: ['Sriperumbudur', 'Pushpagiri', 'Manimangalam', 'Vandalore', 'Kolabakkam', 'Kandigai', 'Sathyabama University']),
  '1E': SathyabamaRoute(
      routeNo: '1E',
      fullRouteString: 'Kancheepuram - Walajabath - Oragadam - Padapai - Mannivakkam - Vandalore - Kandigai - Kolabakkam - Mambakkam - Kelambakkam',
      stops: ['Kancheepuram', 'Walajabath', 'Oragadam', 'Padapai', 'Mannivakkam', 'Vandalore', 'Kandigai', 'Kolabakkam', 'Mambakkam', 'Kelambakkam', 'Sathyabama University']),
  '1F': SathyabamaRoute(
      routeNo: '1F',
      fullRouteString: 'Kancheepuram - Walajabath - Oragadam - Padapai - Mannivakkam - Vandalore - Kolabakkam - Kandigai',
      stops: ['Kancheepuram', 'Walajabath', 'Oragadam', 'Padapai', 'Mannivakkam', 'Vandalore', 'Kolabakkam', 'Kandigai', 'Sathyabama University']),
  '2': SathyabamaRoute(
      routeNo: '2',
      fullRouteString: 'Melmaruvathur - Madhuranthakam - Bhukkathurai - Chengalpet - Raatina Kinaru - Thiruporur Koot Road - Thiruvadisoolam - Mullibakkam - Karumbakkam',
      stops: ['Melmaruvathur', 'Madhuranthakam', 'Bhukkathurai', 'Chengalpet', 'Raatina Kinaru', 'Thiruporur Koot Road', 'Thiruvadisoolam', 'Mullibakkam', 'Karumbakkam', 'Sathyabama University']),
  '2A': SathyabamaRoute(
      routeNo: '2A',
      fullRouteString: 'Madhuranthakam - Karunkuzhi - Maamandur - Patalam - Chengalpattu - Thiruporur Koot Road - Thiruvadisoolam - Mullibakkam - Karumbakkam',
      stops: ['Madhuranthakam', 'Karunkuzhi', 'Maamandur', 'Patalam', 'Chengalpattu', 'Thiruporur Koot Road', 'Thiruvadisoolam', 'Mullibakkam', 'Karumbakkam', 'Sathyabama University']),
  '2B': SathyabamaRoute(
      routeNo: '2B',
      fullRouteString: 'Uthiramerur - Bhukkathurai - Chengalpet Bye pass - Chengalpet bus stand - Raatina Kinaru - Thiruporur Koot Road',
      stops: ['Uthiramerur', 'Bhukkathurai', 'Chengalpet Bye Pass', 'Chengalpet Bus Stand', 'Raatina Kinaru', 'Thiruporur Koot Road', 'Sathyabama University']),
  '2C': SathyabamaRoute(
      routeNo: '2C',
      fullRouteString: 'Chengalpet Bye pass - Raatina Kinaru - Thiruporur Koot Road - Thiruvadisoolam - Mullibakkam - Karumbakkam',
      stops: ['Chengalpet Bye Pass', 'Raatina Kinaru', 'Thiruporur Koot Road', 'Thiruvadisoolam', 'Mullibakkam', 'Karumbakkam', 'Sathyabama University']),
  '2D': SathyabamaRoute(
      routeNo: '2D',
      fullRouteString: 'Raatina Kinaru - Thiruporur Koot Road - Thiruvadisoolam - Mullibakkam - Karumbakkam - Kottamedu - Thiruporur - Kalavakkam',
      stops: ['Raatina Kinaru', 'Thiruporur Koot Road', 'Thiruvadisoolam', 'Mullibakkam', 'Karumbakkam', 'Kottamedu', 'Thiruporur', 'Kalavakkam', 'Sathyabama University']),
  '2E': SathyabamaRoute(
      routeNo: '2E',
      fullRouteString: 'Thiruporur Koot Road - Thiruvadisoolam - Mullibakkam - Karumbakkam - Kottamedu - Thiruporur',
      stops: ['Thiruporur Koot Road', 'Thiruvadisoolam', 'Mullibakkam', 'Karumbakkam', 'Kottamedu', 'Thiruporur', 'Sathyabama University']),
  '2F': SathyabamaRoute(
      routeNo: '2F',
      fullRouteString: 'Chengalpet - Paranur - S.P.Kovil - M.M. Nagar - SRM - Guduvancherry - Urapakkam - Vandalore - Kandigai - Mambakkam - Kelambakkam',
      stops: ['Chengalpet', 'Paranur', 'S.P.Kovil', 'M.M. Nagar', 'SRM', 'Guduvancherry', 'Urapakkam', 'Vandalore', 'Kandigai', 'Mambakkam', 'Kelambakkam', 'Sathyabama University']),
  '2G': SathyabamaRoute(
      routeNo: '2G',
      fullRouteString: 'Chengalpet - Paranur - S.P.Kovil - M.M. Nagar - SRM - Guduvancherry - Urapakkam - Kilambakkam - Vandalore - Kandigai - Mambakkam',
      stops: ['Chengalpet', 'Paranur', 'S.P.Kovil', 'M.M. Nagar', 'SRM', 'Guduvancherry', 'Urapakkam', 'Kilambakkam', 'Vandalore', 'Kandigai', 'Mambakkam', 'Sathyabama University']),
  '2H': SathyabamaRoute(
      routeNo: '2H',
      fullRouteString: 'Chengalpet - Paranur - S.P.Kovil - M.M. Nagar - SRM - Guduvancherry - Urapakkam - Kilambakkam - Vandalore - Kandigai - Mambakkam',
      stops: ['Chengalpet', 'Paranur', 'S.P.Kovil', 'M.M. Nagar', 'SRM', 'Guduvancherry', 'Urapakkam', 'Kilambakkam', 'Vandalore', 'Kandigai', 'Mambakkam', 'Sathyabama University']),
  '3': SathyabamaRoute(
      routeNo: '3',
      fullRouteString: 'Kannivakkam - Kaayarmedu - Guduvancherry - Urapakkam - Kilambakkam - Vandalore - Kolambakkam - Kandigai',
      stops: ['Kannivakkam', 'Kaayarmedu', 'Guduvancherry', 'Urapakkam', 'Kilambakkam', 'Vandalore', 'Kolambakkam', 'Kandigai', 'Sathyabama University']),
  '3A': SathyabamaRoute(
      routeNo: '3A',
      fullRouteString: 'Guduvancherry - Urapakkam - Kilambakkam - Vandalore - Kolambakkam - Mambakkam - Kelambakkam - Padur',
      stops: ['Guduvancherry', 'Urapakkam', 'Kilambakkam', 'Vandalore', 'Kolambakkam', 'Mambakkam', 'Kelambakkam', 'Padur', 'Sathyabama University']),
  '3B': SathyabamaRoute(
      routeNo: '3B',
      fullRouteString: 'Urapakkam - Vandalore - Kolabakkam - Mela Kottaiyur - Keela Kottaiyur - Mambakkam - Pudubakkam - Kelambakkam',
      stops: ['Urapakkam', 'Vandalore', 'Kolabakkam', 'Mela Kottaiyur', 'Keela Kottaiyur', 'Mambakkam', 'Pudubakkam', 'Kelambakkam', 'Sathyabama University']),
  '3C': SathyabamaRoute(
      routeNo: '3C',
      fullRouteString: 'Vandalore - Kolambakkam - Kandigai - Mela Kottaiyur - Keela Kottaiyur - Mambakkam - Kelambakkam - Padur',
      stops: ['Vandalore', 'Kolambakkam', 'Kandigai', 'Mela Kottaiyur', 'Keela Kottaiyur', 'Mambakkam', 'Kelambakkam', 'Padur', 'Sathyabama University']),
  '3D': SathyabamaRoute(
      routeNo: '3D',
      fullRouteString: 'Vandalore - Kolambakkam - Kandigai - Mela Kottaiyur - Keela Kottaiyur - Mambakkam - Kelambakkam - Padur',
      stops: ['Vandalore', 'Kolambakkam', 'Kandigai', 'Mela Kottaiyur', 'Keela Kottaiyur', 'Mambakkam', 'Kelambakkam', 'Padur', 'Sathyabama University']),
  '3E': SathyabamaRoute(
      routeNo: '3E',
      fullRouteString: 'Vandalore - Kolambakkam - Kandigai - Mela Kottaiyur - Keela Kottaiyur - Mambakkam - Kelambakkam - Padur',
      stops: ['Vandalore', 'Kolambakkam', 'Kandigai', 'Mela Kottaiyur', 'Keela Kottaiyur', 'Mambakkam', 'Kelambakkam', 'Padur', 'Sathyabama University']),
  '4': SathyabamaRoute(
      routeNo: '4',
      fullRouteString: 'Marakanam - Kovathur - Kathankadai - Veppancherry - Kalpakkam Indra Nagar - Vengambakkam - Poonjeri Toll Gate - Thiruporur - Kelambakkam',
      stops: ['Marakanam', 'Kovathur', 'Kathankadai', 'Veppancherry', 'Kalpakkam Indra Nagar', 'Vengambakkam', 'Poonjeri Toll Gate', 'Thiruporur', 'Kelambakkam', 'Sathyabama University']),
  '4A': SathyabamaRoute(
      routeNo: '4A',
      fullRouteString: 'Kovathur - Kathankadai - Veppancherry - Kalpakkam Indra Nagar - Vengambakkam - Poonjeri Toll Gate - Thiruporur - Kelambakkam',
      stops: ['Kovathur', 'Kathankadai', 'Veppancherry', 'Kalpakkam Indra Nagar', 'Vengambakkam', 'Poonjeri Toll Gate', 'Thiruporur', 'Kelambakkam', 'Sathyabama University']),
  '4B': SathyabamaRoute(
      routeNo: '4B',
      fullRouteString: 'Kalpakkam - Kalpakkam Ladies Hostel - Satras Gate - Vengambakkam - Poonjeri Toll Gate - Thiruporur',
      stops: ['Kalpakkam', 'Kalpakkam Ladies Hostel', 'Satras Gate', 'Vengambakkam', 'Poonjeri Toll Gate', 'Thiruporur', 'Sathyabama University']),
  '4C': SathyabamaRoute(
      routeNo: '4C',
      fullRouteString: 'Thirukazhukundram - Mahabalipuram - Deveneri - Thiruvidanthai - Pattipulam - Vadanemmeli - Perur - Kovalam',
      stops: ['Thirukazhukundram', 'Mahabalipuram', 'Deveneri', 'Thiruvidanthai', 'Pattipulam', 'Vadanemmeli', 'Perur', 'Kovalam', 'Sathyabama University']),
  '4D': SathyabamaRoute(
      routeNo: '4D',
      fullRouteString: 'Kothimangalam - Eachur - Mamallapuram - Devaneri - Therkupattu - Kovalam - Kelambakkam - Padur',
      stops: ['Kothimangalam', 'Eachur', 'Mamallapuram', 'Devaneri', 'Therkupattu', 'Kovalam', 'Kelambakkam', 'Padur', 'Sathyabama University']),
  '4E': SathyabamaRoute(
      routeNo: '4E',
      fullRouteString: 'Kalpakkam - Vengambakkam - Kunnapattu - Poonjeri - Mahabalipuram - Pattipulam - Thiruvidanthai - Kovalam - Kelambakkam',
      stops: ['Kalpakkam', 'Vengambakkam', 'Kunnapattu', 'Poonjeri', 'Mahabalipuram', 'Pattipulam', 'Thiruvidanthai', 'Kovalam', 'Kelambakkam', 'Sathyabama University']),
  '4F': SathyabamaRoute(
      routeNo: '4F',
      fullRouteString: 'Kalpakkam - Vengambakkam - Anupuram - Poonjeri Toll Gate - Thiruporur - Kalavakkam - Kelambakkam',
      stops: ['Kalpakkam', 'Vengambakkam', 'Anupuram', 'Poonjeri Toll Gate', 'Thiruporur', 'Kalavakkam', 'Kelambakkam', 'Sathyabama University']),
  '4G': SathyabamaRoute(
      routeNo: '4G',
      fullRouteString: 'Thirukazhukundram - Kothimangalam - Poonjeri Toll Gate - Alathur - Thandalam - Thiruporur - Kalavakkam',
      stops: ['Thirukazhukundram', 'Kothimangalam', 'Poonjeri Toll Gate', 'Alathur', 'Thandalam', 'Thiruporur', 'Kalavakkam', 'Sathyabama University']),
  '5': SathyabamaRoute(
      routeNo: '5',
      fullRouteString: 'Maanapathy - Ambur - Thiruporur Rountana - Kalavakkam - Vijaya Shanthi Apartments - Kelambakkam - Padur - Navalur',
      stops: ['Maanapathy', 'Ambur', 'Thiruporur Rountana', 'Kalavakkam', 'Vijaya Shanthi Apartments', 'Kelambakkam', 'Padur', 'Navalur', 'Sathyabama University']),
  '5A': SathyabamaRoute(
      routeNo: '5A',
      fullRouteString: 'Thiruporur - Kalavakkam - Vijaya Shanthi Apartments - Kelambakkam - Padur - Navalur',
      stops: ['Thiruporur', 'Kalavakkam', 'Vijaya Shanthi Apartments', 'Kelambakkam', 'Padur', 'Navalur', 'Sathyabama University']),
  '5B': SathyabamaRoute(
      routeNo: '5B',
      fullRouteString: 'Kayar - Vembedu - Ellalur - Thiruporur - Kalavakkam - Vijaya Shanthi Apartments - Kelambakkam - Padur - Navalur',
      stops: ['Kayar', 'Vembedu', 'Ellalur', 'Thiruporur', 'Kalavakkam', 'Vijaya Shanthi Apartments', 'Kelambakkam', 'Padur', 'Navalur', 'Sathyabama University']),
  '5C': SathyabamaRoute(
      routeNo: '5C',
      fullRouteString: 'Kelambakkam - Padur - Kazhipattur - Navalur - Ags - Semmencherry Alamaram',
      stops: ['Kelambakkam', 'Padur', 'Kazhipattur', 'Navalur', 'Ags', 'Semmencherry Alamaram', 'Sathyabama University']),
  '5D': SathyabamaRoute(
      routeNo: '5D',
      fullRouteString: 'Thiruporur - Kalavakkam - Vijaya Shanthi Apartments - Kelambakkam - Padur - Navalur',
      stops: ['Thiruporur', 'Kalavakkam', 'Vijaya Shanthi Apartments', 'Kelambakkam', 'Padur', 'Navalur', 'Sathyabama University']),
  '5E': SathyabamaRoute(
      routeNo: '5E',
      fullRouteString: 'Kelambakkam - Padur - Kazhipattur - Navalur - Ags - Semmencherry Alamaram',
      stops: ['Kelambakkam', 'Padur', 'Kazhipattur', 'Navalur', 'Ags', 'Semmencherry Alamaram', 'Sathyabama University']),
  '6': SathyabamaRoute(
      routeNo: '6',
      fullRouteString: 'Thalankuppam - Ennore - Ernavur - Vimco Nagar - Thiruvotriyur - Theradi - Toll gate - Tondiarpet - Kasimedu - Kalmandabam - Royapuram',
      stops: ['Thalankuppam', 'Ennore', 'Ernavur', 'Vimco Nagar', 'Thiruvotriyur', 'Theradi', 'Toll Gate', 'Tondiarpet', 'Kasimedu', 'Kalmandabam', 'Royapuram', 'Sathyabama University']),
  '6A': SathyabamaRoute(
      routeNo: '6A',
      fullRouteString: 'Vimco Nagar - Thiruvotriyur - Theradi - Tondiarpet - Kalra Hospital - Kasimedu - Kalmandabam - Royapuram - Light house - Santhome - Pattinambakkam - ECR',
      stops: ['Vimco Nagar', 'Thiruvotriyur', 'Theradi', 'Tondiarpet', 'Kalra Hospital', 'Kasimedu', 'Kalmandabam', 'Royapuram', 'Light House', 'Santhome', 'Pattinambakkam', 'ECR', 'Sathyabama University']),
  '6B': SathyabamaRoute(
      routeNo: '6B',
      fullRouteString: 'Thiruvotriyur - Theradi - Tondiarpet toll gate - Kasimedu - Royapuram - Beach Station - Parrys Corner - Anna square - Light House - Santhome - Pattinambakkam',
      stops: ['Thiruvotriyur', 'Theradi', 'Tondiarpet Toll Gate', 'Kasimedu', 'Royapuram', 'Beach Station', 'Parrys Corner', 'Anna Square', 'Light House', 'Santhome', 'Pattinambakkam', 'Sathyabama University']),
  '6C': SathyabamaRoute(
      routeNo: '6C',
      fullRouteString: 'Tondiarpet Toll gate - Appollo - Tondiarpet metro - Manikoondu - Maharani post office - Singapore shopping - Cement road - Royapuram',
      stops: ['Tondiarpet Toll Gate', 'Appollo', 'Tondiarpet Metro', 'Manikoondu', 'Maharani Post Office', 'Singapore Shopping', 'Cement Road', 'Royapuram', 'Sathyabama University']),
  '6D': SathyabamaRoute(
      routeNo: '6D',
      fullRouteString: 'Tondiarpet Toll gate - Lakshmi temple - Appollo - Mani Cycle - Tondiarpet metro - Manikoondu - Maharani post office - Singapore shopping - Cement road - Depo - Water tank - ECR',
      stops: ['Tondiarpet Toll Gate', 'Lakshmi Temple', 'Appollo', 'Mani Cycle', 'Tondiarpet Metro', 'Manikoondu', 'Maharani Post Office', 'Singapore Shopping', 'Cement Road', 'Depo', 'Water Tank', 'ECR', 'Sathyabama University']),
  '6E': SathyabamaRoute(
      routeNo: '6E',
      fullRouteString: 'Mint bharath theatre - Pencil factory - Mint Metro - Stanli - Bharathi Arts college - Broadway theatre - Mannadi metro - High court',
      stops: ['Mint Bharath Theatre', 'Pencil Factory', 'Mint Metro', 'Stanli', 'Bharathi Arts College', 'Broadway Theatre', 'Mannadi Metro', 'High Court', 'Sathyabama University']),
  '6F': SathyabamaRoute(
      routeNo: '6F',
      fullRouteString: 'Tondiarpet Toll gate - Appollo - Tondiarpet metro - Manikoondu - Maharani post office - Singapore shopping - Cement road',
      stops: ['Tondiarpet Toll Gate', 'Appollo', 'Tondiarpet Metro', 'Manikoondu', 'Maharani Post Office', 'Singapore Shopping', 'Cement Road', 'Sathyabama University']),
  '6G': SathyabamaRoute(
      routeNo: '6G',
      fullRouteString: 'Thiruvotriyur - Theradi - Tondiarpet toll gate - Kalra Hospital - Kasimedu - Royapuram - Beach Station - Parrys Corner - Light House - ECR',
      stops: ['Thiruvotriyur', 'Theradi', 'Tondiarpet Toll Gate', 'Kalra Hospital', 'Kasimedu', 'Royapuram', 'Beach Station', 'Parrys Corner', 'Light House', 'ECR', 'Sathyabama University']),
  '6H': SathyabamaRoute(
      routeNo: '6H',
      fullRouteString: 'Mint bharath theatre - Pencil factory - Mint Metro - Stanli - Bharathi Arts college - Broadway theatre - Mannadi metro - High court - Light house - ECR',
      stops: ['Mint Bharath Theatre', 'Pencil Factory', 'Mint Metro', 'Stanli', 'Bharathi Arts College', 'Broadway Theatre', 'Mannadi Metro', 'High Court', 'Light House', 'ECR', 'Sathyabama University']),
  '6I': SathyabamaRoute(
      routeNo: '6I',
      fullRouteString: 'Vimco Nagar - Thiruvotriyur - Theradi - Tondiarpet - Kalra Hospital - Kasimedu - Kalmandabam - Royapuram - Light house - Santhome - Pattinambakkam - ECR',
      stops: ['Vimco Nagar', 'Thiruvotriyur', 'Theradi', 'Tondiarpet', 'Kalra Hospital', 'Kasimedu', 'Kalmandabam', 'Royapuram', 'Light House', 'Santhome', 'Pattinambakkam', 'ECR', 'Sathyabama University']),
  '7': SathyabamaRoute(
      routeNo: '7',
      fullRouteString: 'Maathur - Madhavaram Post Office - Moolakadai - Sharma Nagar - Vyasarpadi - Walltax Road - Central - Anna Square - Vivekanandar illam',
      stops: ['Maathur', 'Madhavaram Post Office', 'Moolakadai', 'Sharma Nagar', 'Vyasarpadi', 'Walltax Road', 'Central', 'Anna Square', 'Vivekanandar Illam', 'Sathyabama University']),
  '7A': SathyabamaRoute(
      routeNo: '7A',
      fullRouteString: 'Madhavaram - Moolakadai - Sharma Nagar - Vyasarpadi - Basin bridge - Nehru Stadium - Central - Pattinambakkam - Santhome - Adyar',
      stops: ['Madhavaram', 'Moolakadai', 'Sharma Nagar', 'Vyasarpadi', 'Basin Bridge', 'Nehru Stadium', 'Central', 'Pattinambakkam', 'Santhome', 'Adyar', 'Sathyabama University']),
  '7B': SathyabamaRoute(
      routeNo: '7B',
      fullRouteString: 'Madhavaram M.R Nagar - M.K.B Nagar - Vyasarpadi - Wall tax Road - Central - Light House - Santhome - Pattinambakkam - Adyar',
      stops: ['Madhavaram M.R Nagar', 'M.K.B Nagar', 'Vyasarpadi', 'Wall Tax Road', 'Central', 'Light House', 'Santhome', 'Pattinambakkam', 'Adyar', 'Sathyabama University']),
  '7C': SathyabamaRoute(
      routeNo: '7C',
      fullRouteString: 'Madhavaram M.R Nagar - M.K.B Nagar - EB - Vyasarpadi - Basin bridge - Nehru Stadium - Central - Pattinambakkam - Santhome - Adyar',
      stops: ['Madhavaram M.R Nagar', 'M.K.B Nagar', 'EB', 'Vyasarpadi', 'Basin Bridge', 'Nehru Stadium', 'Central', 'Pattinambakkam', 'Santhome', 'Adyar', 'Sathyabama University']),
  '8': SathyabamaRoute(
      routeNo: '8',
      fullRouteString: 'Valluvarkottam - Semmozhi Poonga - Stella Marrys College - Luz Corner - Mylapore - Mandaveli - Sathya Studio - Adyar - ECR',
      stops: ['Valluvarkottam', 'Semmozhi Poonga', 'Stella Marrys College', 'Luz Corner', 'Mylapore', 'Mandaveli', 'Sathya Studio', 'Adyar', 'ECR', 'Sathyabama University']),
  '8A': SathyabamaRoute(
      routeNo: '8A',
      fullRouteString: 'City Centre - Mylapore - Mandaveli - Sathya studio - Adyar - Thiruvanmiyur - Palavakkam - Kottivakkam - V.G.P - ECR',
      stops: ['City Centre', 'Mylapore', 'Mandaveli', 'Sathya Studio', 'Adyar', 'Thiruvanmiyur', 'Palavakkam', 'Kottivakkam', 'V.G.P', 'ECR', 'Sathyabama University']),
  '8C': SathyabamaRoute(
      routeNo: '8C',
      fullRouteString: 'Ameer Mahal - Russian Emforce - Ajantha - Royapetah - Santhome - Pattinambakkam - Sathya studio - Adyar - ECR',
      stops: ['Ameer Mahal', 'Russian Emforce', 'Ajantha', 'Royapetah', 'Santhome', 'Pattinambakkam', 'Sathya Studio', 'Adyar', 'ECR', 'Sathyabama University']),
  '8D': SathyabamaRoute(
      routeNo: '8D',
      fullRouteString: 'Mandaveli - Mylapore - Sathya Studio - Adyar Malar Hospital - AdyarDepot - Thiruvanmiyur - Palavakkam - Neelankarai - V.G.P - ECR',
      stops: ['Mandaveli', 'Mylapore', 'Sathya Studio', 'Adyar Malar Hospital', 'Adyar Depot', 'Thiruvanmiyur', 'Palavakkam', 'Neelankarai', 'V.G.P', 'ECR', 'Sathyabama University']),
  '8E': SathyabamaRoute(
      routeNo: '8E',
      fullRouteString: 'Triplecane - Annapoonra - Ice house - Vivekanandar Illam - Light House - Santhome - Pattinambakkam - Adyar - Thiruvanmiyur - Palavakkam - ECR',
      stops: ['Triplecane', 'Annapoonra', 'Ice House', 'Vivekanandar Illam', 'Light House', 'Santhome', 'Pattinambakkam', 'Adyar', 'Thiruvanmiyur', 'Palavakkam', 'ECR', 'Sathyabama University']),
  '8F': SathyabamaRoute(
      routeNo: '8F',
      fullRouteString: 'Light House - Santhome - Pattinambakkam - MRC Nagar - Sathya studio - Adyar - ECR',
      stops: ['Light House', 'Santhome', 'Pattinambakkam', 'MRC Nagar', 'Sathya Studio', 'Adyar', 'ECR', 'Sathyabama University']),
  '8G': SathyabamaRoute(
      routeNo: '8G',
      fullRouteString: 'Light House - Santhome - Pattinambakkam - MRC Nagar - Sathya studio - Thiruvanmiyur - Kottivakkam - V.G.P - ECR',
      stops: ['Light House', 'Santhome', 'Pattinambakkam', 'MRC Nagar', 'Sathya Studio', 'Thiruvanmiyur', 'Kottivakkam', 'V.G.P', 'ECR', 'Sathyabama University']),
  '8H': SathyabamaRoute(
      routeNo: '8H',
      fullRouteString: 'Egmore - Chintharipet - Triplecane - Annapoonra - Ice house - Vivekanandar Illam - Light House - Santhome - ECR',
      stops: ['Egmore', 'Chintharipet', 'Triplecane', 'Annapoonra', 'Ice House', 'Vivekanandar Illam', 'Light House', 'Santhome', 'ECR', 'Sathyabama University']),
  '9': SathyabamaRoute(
      routeNo: '9',
      fullRouteString: 'Besant Nagar - Vannathurai - Thiruvanmiyur - Palavakkam - V.G.P',
      stops: ['Besant Nagar', 'Vannathurai', 'Thiruvanmiyur', 'Palavakkam', 'V.G.P', 'Sathyabama University']),
  '9A': SathyabamaRoute(
      routeNo: '9A',
      fullRouteString: 'Adyar Telephone Exchange - Thiruvanmiyur - Kottivakkam - V.G.P',
      stops: ['Adyar Telephone Exchange', 'Thiruvanmiyur', 'Kottivakkam', 'V.G.P', 'Sathyabama University']),
  '9B': SathyabamaRoute(
      routeNo: '9B',
      fullRouteString: 'Thiruvanmiyur - Palavakkam - Neelankarai - Kottivakkam - V.G.P - ECR',
      stops: ['Thiruvanmiyur', 'Palavakkam', 'Neelankarai', 'Kottivakkam', 'V.G.P', 'ECR', 'Sathyabama University']),
  '9C': SathyabamaRoute(
      routeNo: '9C',
      fullRouteString: 'Thiruvanmiyur - Palavakkam - Neelankarai - Kottivakkam - V.G.P - ECR',
      stops: ['Thiruvanmiyur', 'Palavakkam', 'Neelankarai', 'Kottivakkam', 'V.G.P', 'ECR', 'Sathyabama University']),
  '9D': SathyabamaRoute(
      routeNo: '9D',
      fullRouteString: 'Thiruvanmiyur - Palavakkam - Neelankarai - Kottivakkam - V.G.P - ECR',
      stops: ['Thiruvanmiyur', 'Palavakkam', 'Neelankarai', 'Kottivakkam', 'V.G.P', 'ECR', 'Sathyabama University']),
  '9E': SathyabamaRoute(
      routeNo: '9E',
      fullRouteString: 'Vettuvankeni - Injambakkam - V.G.P - Akkarai - ECR',
      stops: ['Vettuvankeni', 'Injambakkam', 'V.G.P', 'Akkarai', 'ECR', 'Sathyabama University']),
  '9F': SathyabamaRoute(
      routeNo: '9F',
      fullRouteString: 'Thiruvanmiyur - Palavakkam - Neelankarai - Kottivakkam - V.G.P - ECR',
      stops: ['Thiruvanmiyur', 'Palavakkam', 'Neelankarai', 'Kottivakkam', 'V.G.P', 'ECR', 'Sathyabama University']),
  '10': SathyabamaRoute(
      routeNo: '10',
      fullRouteString: 'Thiruvallur - Manavalan Nagar - Poonamallee - Kumananchavadi - Ayyapanthangal - Ramapuram - Butt Road - Guindy',
      stops: ['Thiruvallur', 'Manavalan Nagar', 'Poonamallee', 'Kumananchavadi', 'Ayyapanthangal', 'Ramapuram', 'Butt Road', 'Guindy', 'Sathyabama University']),
  '10A': SathyabamaRoute(
      routeNo: '10A',
      fullRouteString: 'Thiruvallur - Manavalan Nagar - Poonamallee - Kumananchavadi - Ayyapanthangal - Ramapuram - Butt Road - Guindy',
      stops: ['Thiruvallur', 'Manavalan Nagar', 'Poonamallee', 'Kumananchavadi', 'Ayyapanthangal', 'Ramapuram', 'Butt Road', 'Guindy', 'Sathyabama University']),
  '10B': SathyabamaRoute(
      routeNo: '10B',
      fullRouteString: 'Poonamallee - Ayyapanthangal - Karayanchavadi - Porur Signal - Mugalivakkam - Ramapuram - Butt Road - Guindy - Velacherry bye pass - Chennai one',
      stops: ['Poonamallee', 'Ayyapanthangal', 'Karayanchavadi', 'Porur Signal', 'Mugalivakkam', 'Ramapuram', 'Butt Road', 'Guindy', 'Velacherry Bye Pass', 'Chennai One', 'Sathyabama University']),
  '10C': SathyabamaRoute(
      routeNo: '10C',
      fullRouteString: 'Poonamallee - Ayyapanthangal - Karayanchavadi - Porur Signal - Mugalivakkam - Ramapuram - Butt Road - Guindy - Velacherry bye pass',
      stops: ['Poonamallee', 'Ayyapanthangal', 'Karayanchavadi', 'Porur Signal', 'Mugalivakkam', 'Ramapuram', 'Butt Road', 'Guindy', 'Velacherry Bye Pass', 'Sathyabama University']),
  '10D': SathyabamaRoute(
      routeNo: '10D',
      fullRouteString: 'Poonamallee - Ayyapanthangal - Karayanchavadi - Porur Signal - Mugalivakkam - Ramapuram - Butt Road - Guindy - Velacherry bye pass',
      stops: ['Poonamallee', 'Ayyapanthangal', 'Karayanchavadi', 'Porur Signal', 'Mugalivakkam', 'Ramapuram', 'Butt Road', 'Guindy', 'Velacherry Bye Pass', 'Sathyabama University']),
  '10E': SathyabamaRoute(
      routeNo: '10E',
      fullRouteString: 'Porur Bai Kadai - Porur signal - Mugalivakkam - Ramapuram - Butt Road - Guindy - Velacherry bye pass',
      stops: ['Porur Bai Kadai', 'Porur Signal', 'Mugalivakkam', 'Ramapuram', 'Butt Road', 'Guindy', 'Velacherry Bye Pass', 'Sathyabama University']),
  '10F': SathyabamaRoute(
      routeNo: '10F',
      fullRouteString: 'Poonamallee - Ayyapanthangal - Karayanchavadi - Porur Signal - Mugalivakkam - Ramapuram - Butt Road - Guindy - Velacherry bye pass',
      stops: ['Poonamallee', 'Ayyapanthangal', 'Karayanchavadi', 'Porur Signal', 'Mugalivakkam', 'Ramapuram', 'Butt Road', 'Guindy', 'Velacherry Bye Pass', 'Sathyabama University']),
  '11': SathyabamaRoute(
      routeNo: '11',
      fullRouteString: 'Veppampattu - Thirunindravur - Jaya College - Nemilicherry bye pass - Vandalore - Kandigai - Melakottaiyur',
      stops: ['Veppampattu', 'Thirunindravur', 'Jaya College', 'Nemilicherry Bye Pass', 'Vandalore', 'Kandigai', 'Melakottaiyur', 'Sathyabama University']),
  '11A': SathyabamaRoute(
      routeNo: '11A',
      fullRouteString: 'Thirunindravur - Pattabiram - Avadi check post - Sennarikuppam - TVS bye pass - Vandalore - Kolabakkam - Kelakottaiyur - Mambakkam',
      stops: ['Thirunindravur', 'Pattabiram', 'Avadi Check Post', 'Sennarikuppam', 'TVS Bye Pass', 'Vandalore', 'Kolabakkam', 'Kelakottaiyur', 'Mambakkam', 'Sathyabama University']),
  '11B': SathyabamaRoute(
      routeNo: '11B',
      fullRouteString: 'Avadi - Avadi Murugappa Polytechnic - Thirumullaivoyal - Ambattur O.T - Ambattur - Padi - Koyambedu - MMDA - Vadapalani - Alandur metro',
      stops: ['Avadi', 'Avadi Murugappa Polytechnic', 'Thirumullaivoyal', 'Ambattur O.T', 'Ambattur', 'Padi', 'Koyambedu', 'MMDA', 'Vadapalani', 'Alandur Metro', 'Sathyabama University']),
  '11C': SathyabamaRoute(
      routeNo: '11C',
      fullRouteString: 'Ayapakkam - Mugapair West - J.J Nagar Police Station - Collector Nagar - Thirumangalam - Koyambedu - Vadapalani - Ekattuthangal - Alandur metro',
      stops: ['Ayapakkam', 'Mugapair West', 'J.J Nagar Police Station', 'Collector Nagar', 'Thirumangalam', 'Koyambedu', 'Vadapalani', 'Ekattuthangal', 'Alandur Metro', 'Sathyabama University']),
  '11D': SathyabamaRoute(
      routeNo: '11D',
      fullRouteString: 'Muthapudupet - Ambattur O.T - Vavin - Collector Nagar - Thirumangalam - Koyambedu - Vadapalani - Alandur Metro - Thillai ganga nagar subway',
      stops: ['Muthapudupet', 'Ambattur O.T', 'Vavin', 'Collector Nagar', 'Thirumangalam', 'Koyambedu', 'Vadapalani', 'Alandur Metro', 'Thillai Ganga Nagar Subway', 'Sathyabama University']),
  '11E': SathyabamaRoute(
      routeNo: '11E',
      fullRouteString: 'Mugapair East - MMM Hospital - Thirumangalam - Koyambedu - MMDA - Vadapalani - Ashok Nagar - Ekkatuthangal',
      stops: ['Mugapair East', 'MMM Hospital', 'Thirumangalam', 'Koyambedu', 'MMDA', 'Vadapalani', 'Ashok Nagar', 'Ekkatuthangal', 'Sathyabama University']),
  '11F': SathyabamaRoute(
      routeNo: '11F',
      fullRouteString: 'Sennarikuppam - ACS College - Vanagaram - Vellappanchavadi - Maduravoyul - Nerkundram - Koyambedu - Vadapalani',
      stops: ['Sennarikuppam', 'ACS College', 'Vanagaram', 'Vellappanchavadi', 'Maduravoyul', 'Nerkundram', 'Koyambedu', 'Vadapalani', 'Sathyabama University']),
  '11G': SathyabamaRoute(
      routeNo: '11G',
      fullRouteString: 'Ambattur - Mugapair West - Collector Nagar - Thirumangalam - Koyambedu - Vadapalani - Ashok Pillar - Guindy - Alandur metro',
      stops: ['Ambattur', 'Mugapair West', 'Collector Nagar', 'Thirumangalam', 'Koyambedu', 'Vadapalani', 'Ashok Pillar', 'Guindy', 'Alandur Metro', 'Sathyabama University']),
  '11H': SathyabamaRoute(
      routeNo: '11H',
      fullRouteString: 'Pudur - Ambattur - Padi - Thirumangalam - Koyambedu - MMDA - Vadapalani - Ashok pillar - Alandur metro',
      stops: ['Pudur', 'Ambattur', 'Padi', 'Thirumangalam', 'Koyambedu', 'MMDA', 'Vadapalani', 'Ashok Pillar', 'Alandur Metro', 'Sathyabama University']),
  '11I': SathyabamaRoute(
      routeNo: '11I',
      fullRouteString: 'Pattabiram - Avadi Checkpost - Paruthipattu - Sennarikuppam - ACS College - Vanagaram - Vellappanchavadi - Maduravoyul - Nerkundram - Koyambedu - Vadapalani',
      stops: ['Pattabiram', 'Avadi Checkpost', 'Paruthipattu', 'Sennarikuppam', 'ACS College', 'Vanagaram', 'Vellappanchavadi', 'Maduravoyul', 'Nerkundram', 'Koyambedu', 'Vadapalani', 'Sathyabama University']),
  '11J': SathyabamaRoute(
      routeNo: '11J',
      fullRouteString: 'Koyambedu - MMDA - Vadapalani - Ashok Nagar - Udhayam - Ekkatuthangal - Guindy - Alandur',
      stops: ['Koyambedu', 'MMDA', 'Vadapalani', 'Ashok Nagar', 'Udhayam', 'Ekkatuthangal', 'Guindy', 'Alandur', 'Sathyabama University']),
  '11K': SathyabamaRoute(
      routeNo: '11K',
      fullRouteString: 'Koyambedu - MMDA - Vadapalani - Ashok Nagar - Udhayam - Ekkatuthangal - Guindy - Alandur',
      stops: ['Koyambedu', 'MMDA', 'Vadapalani', 'Ashok Nagar', 'Udhayam', 'Ekkatuthangal', 'Guindy', 'Alandur', 'Sathyabama University']),
  '12': SathyabamaRoute(
      routeNo: '12',
      fullRouteString: 'Red Hills - Puzhal - Camp - Rettari - Padi - Thirumangalam - Koyambedu - Vadapalani - Alandur metro',
      stops: ['Red Hills', 'Puzhal', 'Camp', 'Rettari', 'Padi', 'Thirumangalam', 'Koyambedu', 'Vadapalani', 'Alandur Metro', 'Sathyabama University']),
  '12A': SathyabamaRoute(
      routeNo: '12A',
      fullRouteString: 'Moogambigai Theater - Kolathur - Periyar Nagar - Paravalur - Anna Statue - Jamalaya - Binny mills - Otteri - Egmore - Spencer',
      stops: ['Moogambigai Theater', 'Kolathur', 'Periyar Nagar', 'Paravalur', 'Anna Statue', 'Jamalaya', 'Binny Mills', 'Otteri', 'Egmore', 'Spencer', 'Sathyabama University']),
  '12B': SathyabamaRoute(
      routeNo: '12B',
      fullRouteString: 'Rettari - Anna Salai market - Agaram - Venus - Perambur Bus stand - Bhuvaneshwari - G3 Police station',
      stops: ['Rettari', 'Anna Salai Market', 'Agaram', 'Venus', 'Perambur Bus Stand', 'Bhuvaneshwari', 'G3 Police Station', 'Sathyabama University']),
  '12C': SathyabamaRoute(
      routeNo: '12C',
      fullRouteString: 'Moolakadai - Perambur Railway Station - Perambur Bus Stand - Aaduthotti - G3 Police Station - Purasaivakkam - Egmore',
      stops: ['Moolakadai', 'Perambur Railway Station', 'Perambur Bus Stand', 'Aaduthotti', 'G3 Police Station', 'Purasaivakkam', 'Egmore', 'Sathyabama University']),
  '12D': SathyabamaRoute(
      routeNo: '12D',
      fullRouteString: 'Rettari - Kolathur - Jamalaya - G3 Police station - Puliyanthoppu - Veppery - Central - Spencer plaza - DMS - Teynampet - Kotturpuram',
      stops: ['Rettari', 'Kolathur', 'Jamalaya', 'G3 Police Station', 'Puliyanthoppu', 'Veppery', 'Central', 'Spencer Plaza', 'DMS', 'Teynampet', 'Kotturpuram', 'Sathyabama University']),
  '12E': SathyabamaRoute(
      routeNo: '12E',
      fullRouteString: 'Rettari - Kolathur - Paravalur - Perambur Railway station - Otteri - Purasaiwakkam - Egmore - Ethiraj',
      stops: ['Rettari', 'Kolathur', 'Paravalur', 'Perambur Railway Station', 'Otteri', 'Purasaiwakkam', 'Egmore', 'Ethiraj', 'Sathyabama University']),
  '12F': SathyabamaRoute(
      routeNo: '12F',
      fullRouteString: 'Rettari - Kolathur - Paravalur - Perambur Railway station - Otteri - Purasaiwakkam - Egmore - Ethiraj',
      stops: ['Rettari', 'Kolathur', 'Paravalur', 'Perambur Railway Station', 'Otteri', 'Purasaiwakkam', 'Egmore', 'Ethiraj', 'Sathyabama University']),
  '13': SathyabamaRoute(
      routeNo: '13',
      fullRouteString: 'Villivakkam - Nadamuni Theatre - ICF - Ayanavaram - Kilpauk Hospital - Noor Hotel - Kellys - Purasaivakkan - Egmore',
      stops: ['Villivakkam', 'Nadamuni Theatre', 'ICF', 'Ayanavaram', 'Kilpauk Hospital', 'Noor Hotel', 'Kellys', 'Purasaivakkan', 'Egmore', 'Sathyabama University']),
  '13A': SathyabamaRoute(
      routeNo: '13A',
      fullRouteString: 'Villivakkam - Nadamuni Theatre - ICF - Ayanavaram - Noor Hotel - Kellys - Purasaivakkam - Egmore - Greams road - Gemini',
      stops: ['Villivakkam', 'Nadamuni Theatre', 'ICF', 'Ayanavaram', 'Noor Hotel', 'Kellys', 'Purasaivakkam', 'Egmore', 'Greams Road', 'Gemini', 'Sathyabama University']),
  '13B': SathyabamaRoute(
      routeNo: '13B',
      fullRouteString: 'Villivakkam - Nadamuni Theatre - ICF - Ayanavaram - Kilpauk Hospital - Noor Hotel - Purasaivakkam - Egmore',
      stops: ['Villivakkam', 'Nadamuni Theatre', 'ICF', 'Ayanavaram', 'Kilpauk Hospital', 'Noor Hotel', 'Purasaivakkam', 'Egmore', 'Sathyabama University']),
  '13D': SathyabamaRoute(
      routeNo: '13D',
      fullRouteString: 'Purasaivakkam - Egmore - Spencer - Gemini - DMS - Teynampet - Kotturpuram - Madhyakailash - OMR',
      stops: ['Purasaivakkam', 'Egmore', 'Spencer', 'Gemini', 'DMS', 'Teynampet', 'Kotturpuram', 'Madhyakailash', 'OMR', 'Sathyabama University']),
  '14': SathyabamaRoute(
      routeNo: '14',
      fullRouteString: 'Kodambakkam Power House - B.B.C - Kodambakkam Meenakshi College - T.Nagar Bus Stand - CIT Nagar - Saidapet - Little Mount - IIT',
      stops: ['Kodambakkam Power House', 'B.B.C', 'Kodambakkam Meenakshi College', 'T.Nagar Bus Stand', 'CIT Nagar', 'Saidapet', 'Little Mount', 'IIT', 'Sathyabama University']),
  '14A': SathyabamaRoute(
      routeNo: '14A',
      fullRouteString: 'T.Nagar Bus stand - Saidapet - Little Mount - Anna University - IIT - Madhyakailash - Tidel Park - SRP Tools - Kandhanchavadi',
      stops: ['T.Nagar Bus Stand', 'Saidapet', 'Little Mount', 'Anna University', 'IIT', 'Madhyakailash', 'Tidel Park', 'SRP Tools', 'Kandhanchavadi', 'Sathyabama University']),
  '14B': SathyabamaRoute(
      routeNo: '14B',
      fullRouteString: 'Saidapet - Little mount - Velacherry Bye pass - Vijayanagar - Baby nagar - Taramani - Perungudi - PTC - Karapakkam',
      stops: ['Saidapet', 'Little Mount', 'Velacherry Bye Pass', 'Vijayanagar', 'Baby Nagar', 'Taramani', 'Perungudi', 'PTC', 'Karapakkam', 'Sathyabama University']),
  '15': SathyabamaRoute(
      routeNo: '15',
      fullRouteString: 'Chinmaya Nagar - Virugambakkam - Avichi School - Pondicherry Guest House - K.K.Nagar - Meetupalayam - Seenuvasa Theatre - Kannamapettai - CIT Nagar - Saidapet',
      stops: ['Chinmaya Nagar', 'Virugambakkam', 'Avichi School', 'Pondicherry Guest House', 'K.K.Nagar', 'Meetupalayam', 'Seenuvasa Theatre', 'Kannamapettai', 'CIT Nagar', 'Saidapet', 'Sathyabama University']),
  '15A': SathyabamaRoute(
      routeNo: '15A',
      fullRouteString: 'Chinmaya Nagar - Virugambakkam - Avichi School - Pondicherry Guest House - K.K.Nagar - Meetupalayam - Seenuvasa Theatre - Kannamapettai - CIT Nagar - Saidapet',
      stops: ['Chinmaya Nagar', 'Virugambakkam', 'Avichi School', 'Pondicherry Guest House', 'K.K.Nagar', 'Meetupalayam', 'Seenuvasa Theatre', 'Kannamapettai', 'CIT Nagar', 'Saidapet', 'Sathyabama University']),
  '15B': SathyabamaRoute(
      routeNo: '15B',
      fullRouteString: 'Saligramam - AVM Signal - West Mambalam - Brindavanam Street - Duraisamy Sub Way - Panagal Park - Nandanam Signal',
      stops: ['Saligramam', 'AVM Signal', 'West Mambalam', 'Brindavanam Street', 'Duraisamy Sub Way', 'Panagal Park', 'Nandanam Signal', 'Sathyabama University']),
  '15C': SathyabamaRoute(
      routeNo: '15C',
      fullRouteString: '7th Avenue Sangam Hotel - Blue Tank - Ekkatuthangal - Velacherry Bye Pass - Vijayanagar - Chennai One',
      stops: ['7th Avenue Sangam Hotel', 'Blue Tank', 'Ekkatuthangal', 'Velacherry Bye Pass', 'Vijayanagar', 'Chennai One', 'Sathyabama University']),
  '16': SathyabamaRoute(
      routeNo: '16',
      fullRouteString: 'Senthil Nagar - K 4 Police Station - Chinthamani - Kilpauk Garden - Kilpauk Ega Theatre - Chetpet - Gemini - Kalaignar TV - Teynampet - SIET - Kotturpuram',
      stops: ['Senthil Nagar', 'K 4 Police Station', 'Chinthamani', 'Kilpauk Garden', 'Kilpauk Ega Theatre', 'Chetpet', 'Gemini', 'Kalaignar TV', 'Teynampet', 'SIET', 'Kotturpuram', 'Sathyabama University']),
  '16A': SathyabamaRoute(
      routeNo: '16A',
      fullRouteString: 'Manali - Madhavaram Rountana - Senthil Nagar - Blue Star - Anna Nagar Rountana - Shanthi Colony - Anna Arch Choolaimedu - Metha Nagar - Loyala College',
      stops: ['Manali', 'Madhavaram Rountana', 'Senthil Nagar', 'Blue Star', 'Anna Nagar Rountana', 'Shanthi Colony', 'Anna Arch Choolaimedu', 'Metha Nagar', 'Loyala College', 'Sathyabama University']),
  '16B': SathyabamaRoute(
      routeNo: '16B',
      fullRouteString: 'Anna Nagar West Depot - Shanthi Colony - Anna Arch - Metha Nagar - Choolaimedu - Loyala College - Nungambakkam - Gemini - DMS - Kalaignar TV',
      stops: ['Anna Nagar West Depot', 'Shanthi Colony', 'Anna Arch', 'Metha Nagar', 'Choolaimedu', 'Loyala College', 'Nungambakkam', 'Gemini', 'DMS', 'Kalaignar TV', 'Sathyabama University']),
  '16C': SathyabamaRoute(
      routeNo: '16C',
      fullRouteString: 'Temple School - Senthil Nagar - Thathankuppam - Anna Arch - Metha Nagar - Choolaimedu - Loyala College - Nungambakkam - Gemini - DMS - Kalaignar TV - Teynampet - Kotturpuram - IIT - Madhyakailash',
      stops: ['Temple School', 'Senthil Nagar', 'Thathankuppam', 'Anna Arch', 'Metha Nagar', 'Choolaimedu', 'Loyala College', 'Nungambakkam', 'Gemini', 'DMS', 'Kalaignar TV', 'Teynampet', 'Kotturpuram', 'IIT', 'Madhyakailash', 'Sathyabama University']),
  '16D': SathyabamaRoute(
      routeNo: '16D',
      fullRouteString: 'Korattur - TVS - Lucas - Anna Nagar West Depo - Anna Arch - Choolaimedu - Metha Nagar - Loyala College - Nungambakkam - Gemini - DMS - Teynampet - Kotturpuram',
      stops: ['Korattur', 'TVS', 'Lucas', 'Anna Nagar West Depo', 'Anna Arch', 'Choolaimedu', 'Metha Nagar', 'Loyala College', 'Nungambakkam', 'Gemini', 'DMS', 'Teynampet', 'Kotturpuram', 'Sathyabama University']),
  '16E': SathyabamaRoute(
      routeNo: '16E',
      fullRouteString: 'Anna Arch - Choolaimedu - Metha Nagar - Loyala College - Nungambakkam - Gemini - DMS - Teynampet - Kotturpuram - Madhyakailash - Tidel Park - Perungudi',
      stops: ['Anna Arch', 'Choolaimedu', 'Metha Nagar', 'Loyala College', 'Nungambakkam', 'Gemini', 'DMS', 'Teynampet', 'Kotturpuram', 'Madhyakailash', 'Tidel Park', 'Perungudi', 'Sathyabama University']),
  '17': SathyabamaRoute(
      routeNo: '17',
      fullRouteString: 'Porur - Lakshmi Nagar - Valasaravakkam - Alwarthiru Nagar - Kesavarthini - Virugambakkam - Guindy - Velacherry bye pass - Chennai One',
      stops: ['Porur', 'Lakshmi Nagar', 'Valasaravakkam', 'Alwarthiru Nagar', 'Kesavarthini', 'Virugambakkam', 'Guindy', 'Velacherry Bye Pass', 'Chennai One', 'Sathyabama University']),
  '17A': SathyabamaRoute(
      routeNo: '17A',
      fullRouteString: 'Porur - Karampakkam - Lakshmi Nagar - Valasaravakkam - Kesavarthini - Alwarthiru Nagar - Guindy - Velacherry Bye Pass',
      stops: ['Porur', 'Karampakkam', 'Lakshmi Nagar', 'Valasaravakkam', 'Kesavarthini', 'Alwarthiru Nagar', 'Guindy', 'Velacherry Bye Pass', 'Sathyabama University']),
  '17B': SathyabamaRoute(
      routeNo: '17B',
      fullRouteString: 'K.K.Nagar - Pondicherry Guest House - Udayam - Kasi - Guindy - Velacherry Bye Pass - Velacherry Railway Station - Kaiveli',
      stops: ['K.K.Nagar', 'Pondicherry Guest House', 'Udayam', 'Kasi', 'Guindy', 'Velacherry Bye Pass', 'Velacherry Railway Station', 'Kaiveli', 'Sathyabama University']),
  '18': SathyabamaRoute(
      routeNo: '18',
      fullRouteString: 'Mangadu - Kundrathur - Anakapudur - Pammal - Pallavaram - Vels College - S.Kolathur - Kamakshi Hospital - Chennai One',
      stops: ['Mangadu', 'Kundrathur', 'Anakapudur', 'Pammal', 'Pallavaram', 'Vels College', 'S.Kolathur', 'Kamakshi Hospital', 'Chennai One', 'Sathyabama University']),
  '18A': SathyabamaRoute(
      routeNo: '18A',
      fullRouteString: 'Kundrathur - Anakaputhur - Pammal - Pallavaram - Vels College - S.Kolathur - Kamakshi Hospital - Chennai One',
      stops: ['Kundrathur', 'Anakaputhur', 'Pammal', 'Pallavaram', 'Vels College', 'S.Kolathur', 'Kamakshi Hospital', 'Chennai One', 'Sathyabama University']),
  '18B': SathyabamaRoute(
      routeNo: '18B',
      fullRouteString: 'Kundrathur - Anakaputhur - Pammal - Pallavaram - Vels College - S.Kolathur - Kamakshi Hospital - Chennai One',
      stops: ['Kundrathur', 'Anakaputhur', 'Pammal', 'Pallavaram', 'Vels College', 'S.Kolathur', 'Kamakshi Hospital', 'Chennai One', 'Sathyabama University']),
  '18C': SathyabamaRoute(
      routeNo: '18C',
      fullRouteString: 'Pallavaram Vels College - Echankadu Signal - S.Kolathur - Kamakshi Hospital - Chennai One',
      stops: ['Pallavaram Vels College', 'Echankadu Signal', 'S.Kolathur', 'Kamakshi Hospital', 'Chennai One', 'Sathyabama University']),
  '18D': SathyabamaRoute(
      routeNo: '18D',
      fullRouteString: 'Meenambakkam - Pallavaram - Chrompet - Sanitorium - Tambaram - West Depot - Camproad - Mahalakshmi Nagar',
      stops: ['Meenambakkam', 'Pallavaram', 'Chrompet', 'Sanitorium', 'Tambaram', 'West Depot', 'Camproad', 'Mahalakshmi Nagar', 'Sathyabama University']),
  '18E': SathyabamaRoute(
      routeNo: '18E',
      fullRouteString: 'Pammal - Pallavaram - Chrompet - Sanitorium - Tambaram - Camproad - Sembakkam - Gowrivakkam - Medavakkam Koot Road - Sithalabakkam',
      stops: ['Pammal', 'Pallavaram', 'Chrompet', 'Sanitorium', 'Tambaram', 'Camproad', 'Sembakkam', 'Gowrivakkam', 'Medavakkam Koot Road', 'Sithalabakkam', 'Sathyabama University']),
  '18F': SathyabamaRoute(
      routeNo: '18F',
      fullRouteString: 'Kundrathur - Anakaputhur - Pammal - Pallavaram - Vels College - S.Kolathur - Kamakshi Hospital - Chennai One',
      stops: ['Kundrathur', 'Anakaputhur', 'Pammal', 'Pallavaram', 'Vels College', 'S.Kolathur', 'Kamakshi Hospital', 'Chennai One', 'Sathyabama University']),
  '19': SathyabamaRoute(
      routeNo: '19',
      fullRouteString: 'Walajabath - Oragadam - Padapai - Salamangalam - Mannivakkam - Mudichur - Tambaram',
      stops: ['Walajabath', 'Oragadam', 'Padapai', 'Salamangalam', 'Mannivakkam', 'Mudichur', 'Tambaram', 'Sathyabama University']),
  '19A': SathyabamaRoute(
      routeNo: '19A',
      fullRouteString: 'Mudichur - Old Perungulathore - Bharathi Nagar - Tambaram - Selaiyur - Camproad - Mahalakshmi Nagar - Sembakkam',
      stops: ['Mudichur', 'Old Perungulathore', 'Bharathi Nagar', 'Tambaram', 'Selaiyur', 'Camproad', 'Mahalakshmi Nagar', 'Sembakkam', 'Sathyabama University']),
  '19B': SathyabamaRoute(
      routeNo: '19B',
      fullRouteString: 'Manimangalam - Mudichur - Old Perungulathore - Bharathi Nagar - Tambaram - Selaiyur - Camproad - Mahalakshmi Nagar - Sembakkam - Santhoshpuram',
      stops: ['Manimangalam', 'Mudichur', 'Old Perungulathore', 'Bharathi Nagar', 'Tambaram', 'Selaiyur', 'Camproad', 'Mahalakshmi Nagar', 'Santhoshpuram', 'Sathyabama University']),
  '19C': SathyabamaRoute(
      routeNo: '19C',
      fullRouteString: 'Mudichur - Gandhi Nagar - Tambaram - Selaiyur - Camproad - Kamarajapuram - Sithalabakkam',
      stops: ['Mudichur', 'Gandhi Nagar', 'Tambaram', 'Selaiyur', 'Camproad', 'Kamarajapuram', 'Sithalabakkam', 'Sathyabama University']),
  '20': SathyabamaRoute(
      routeNo: '20',
      fullRouteString: 'Hasthinapuram - Chitlapakkam - Selaiyur Police Station - Camproad - Mahalakshmi Nagar - Rajakilpakkam - Kamarajapuram',
      stops: ['Hasthinapuram', 'Chitlapakkam', 'Selaiyur Police Station', 'Camproad', 'Mahalakshmi Nagar', 'Rajakilpakkam', 'Kamarajapuram', 'Sathyabama University']),
  '20A': SathyabamaRoute(
      routeNo: '20A',
      fullRouteString: 'Hasthinapuram - Chitlapakkam - Poondi Bazar - Selaiyur - Camproad - Sembakkam - Santhoshpuram - Medavakkam',
      stops: ['Hasthinapuram', 'Chitlapakkam', 'Poondi Bazar', 'Selaiyur', 'Camproad', 'Sembakkam', 'Santhoshpuram', 'Medavakkam', 'Sathyabama University']),
  '20B': SathyabamaRoute(
      routeNo: '20B',
      fullRouteString: 'Kamarajapuram - Santhospuram - Medavakkam Koot Road - Medavakkam - Perumbakkam - Global - HCL',
      stops: ['Kamarajapuram', 'Santhospuram', 'Medavakkam Koot Road', 'Medavakkam', 'Perumbakkam', 'Global', 'HCL', 'Sathyabama University']),
  '21': SathyabamaRoute(
      routeNo: '21',
      fullRouteString: 'Mannivakkam - Lakshmi Nagar - Mudichur - Old Perungulathore - Bharathi Nagar - Tambaram - Selaiyur - Camproad - Mahalakshmi Nagar - Sembakkam',
      stops: ['Mannivakkam', 'Lakshmi Nagar', 'Mudichur', 'Old Perungulathore', 'Bharathi Nagar', 'Tambaram', 'Selaiyur', 'Camproad', 'Mahalakshmi Nagar', 'Sembakkam', 'Sathyabama University']),
  '21A': SathyabamaRoute(
      routeNo: '21A',
      fullRouteString: 'Vandalore - Perungulathore - Irumpuliyur - Tambaram - Selaiyur - Camproad - Kamarajapuram',
      stops: ['Vandalore', 'Perungulathore', 'Irumpuliyur', 'Tambaram', 'Selaiyur', 'Camproad', 'Kamarajapuram', 'Sathyabama University']),
  '21B': SathyabamaRoute(
      routeNo: '21B',
      fullRouteString: 'Vandalore - Perungulathore - Irumpuliyur - Tambaram - Selaiyur - Camproad - Kamarajapuram',
      stops: ['Vandalore', 'Perungulathore', 'Irumpuliyur', 'Tambaram', 'Selaiyur', 'Camproad', 'Kamarajapuram', 'Sathyabama University']),
  '21C': SathyabamaRoute(
      routeNo: '21C',
      fullRouteString: 'Camproad - Sembakkam - Kamarajapuram - Medavakkam Koot Road - Sithalabakkam',
      stops: ['Camproad', 'Sembakkam', 'Kamarajapuram', 'Medavakkam Koot Road', 'Sithalabakkam', 'Sathyabama University']),
  '22': SathyabamaRoute(
      routeNo: '22',
      fullRouteString: 'Kamakshi Hospital - Balaji Dental College - Narayanapuram - Pallikaranai - Medavakkam - Perumbakkam - Global - HCL',
      stops: ['Kamakshi Hospital', 'Balaji Dental College', 'Narayanapuram', 'Pallikaranai', 'Medavakkam', 'Perumbakkam', 'Global', 'HCL', 'Sathyabama University']),
  '22A': SathyabamaRoute(
      routeNo: '22A',
      fullRouteString: 'Kamakshi Hospital - Balaji Dental College - Narayanapuram - Pallikaranai - Medavakkam - Perumbakkam - Global - HCL',
      stops: ['Kamakshi Hospital', 'Balaji Dental College', 'Narayanapuram', 'Pallikaranai', 'Medavakkam', 'Perumbakkam', 'Global', 'HCL', 'Sathyabama University']),
  '22B': SathyabamaRoute(
      routeNo: '22B',
      fullRouteString: 'Kamakshi Hospital - Balaji Dental College - Narayanapuram - Pallikaranai - Medavakkam - Perumbakkam - Global - HCL',
      stops: ['Kamakshi Hospital', 'Balaji Dental College', 'Narayanapuram', 'Pallikaranai', 'Medavakkam', 'Perumbakkam', 'Global', 'HCL', 'Sathyabama University']),
  '22C': SathyabamaRoute(
      routeNo: '22C',
      fullRouteString: 'Medavakkam - Perumbakkam Church - Global - HCL',
      stops: ['Medavakkam', 'Perumbakkam Church', 'Global', 'HCL', 'Sathyabama University']),
  '22D': SathyabamaRoute(
      routeNo: '22D',
      fullRouteString: 'Vengaivasal - IM Gear Company - New Prince College - Santhoshpuram - Medavakkam Koot Road - Medavakkam - Perumbakkam',
      stops: ['Vengaivasal', 'IM Gear Company', 'New Prince College', 'Santhoshpuram', 'Medavakkam Koot Road', 'Medavakkam', 'Perumbakkam', 'Sathyabama University']),
  '23': SathyabamaRoute(
      routeNo: '23',
      fullRouteString: 'Axis Bank - Madipakkam Ponniyamman Temple - Balaya Gardan - Sadasivam Nagar - Ram Nagar - Kaiveli - Chennai One',
      stops: ['Axis Bank', 'Madipakkam Ponniyamman Temple', 'Balaya Gardan', 'Sadasivam Nagar', 'Ram Nagar', 'Kaiveli', 'Chennai One', 'Sathyabama University']),
  '23A': SathyabamaRoute(
      routeNo: '23A',
      fullRouteString: 'Axis Bank - Madipakkam Ponniyamman Temple - Balaya Gardan - Sadasivam Nagar - Ram Nagar - Kaiveli - Chennai One',
      stops: ['Axis Bank', 'Madipakkam Ponniyamman Temple', 'Balaya Gardan', 'Sadasivam Nagar', 'Ram Nagar', 'Kaiveli', 'Chennai One', 'Sathyabama University']),
  '23B': SathyabamaRoute(
      routeNo: '23B',
      fullRouteString: 'Kaiveli - Kamakshi Hospital - Chennai One - Thoraipakkam - PTC - Karapakkam',
      stops: ['Kaiveli', 'Kamakshi Hospital', 'Chennai One', 'Thoraipakkam', 'PTC', 'Karapakkam', 'Sathyabama University']),
  '24': SathyabamaRoute(
      routeNo: '24',
      fullRouteString: 'Ross Nagar - Nun Mangalam - Mothersa Textiles - Vellakal - Anjaneyar Temple - Kovilambakkam - Medavakkam Koot Road - Babu Nagar - Veerapathira Nagar - Sithalabakkam',
      stops: ['Ross Nagar', 'Nun Mangalam', 'Mothersa Textiles', 'Vellakal', 'Anjaneyar Temple', 'Kovilambakkam', 'Medavakkam Koot Road', 'Babu Nagar', 'Veerapathira Nagar', 'Sithalabakkam', 'Sathyabama University']),
  '24A': SathyabamaRoute(
      routeNo: '24A',
      fullRouteString: 'Echankadu Signal - Ross Nagar - Nun Mangalam - Mothersa Textiles - Vellakal - Anjaneyar Temple - Kovilambakkam - Medavakkam Koot Road - Babu Nagar - Veerapathira Nagar',
      stops: ['Echankadu Signal', 'Ross Nagar', 'Nun Mangalam', 'Mothersa Textiles', 'Vellakal', 'Anjaneyar Temple', 'Kovilambakkam', 'Medavakkam Koot Road', 'Babu Nagar', 'Veerapathira Nagar', 'Sathyabama University']),
  '24B': SathyabamaRoute(
      routeNo: '24B',
      fullRouteString: 'Puthukovil - Medavakkam Koot Road - Babu Nagar - Veerabathira Nagar - Sithalabakkam',
      stops: ['Puthukovil', 'Medavakkam Koot Road', 'Babu Nagar', 'Veerabathira Nagar', 'Sithalabakkam', 'Sathyabama University']),
  '25': SathyabamaRoute(
      routeNo: '25',
      fullRouteString: 'Axis Bank - Keelkattalai - Ganesh Nagar - S.Kolathur - Kamakshi Hospital - Chennai One - PTC - Karapakkam',
      stops: ['Axis Bank', 'Keelkattalai', 'Ganesh Nagar', 'S.Kolathur', 'Kamakshi Hospital', 'Chennai One', 'PTC', 'Karapakkam', 'Sathyabama University']),
  '25A': SathyabamaRoute(
      routeNo: '25A',
      fullRouteString: 'Pallavaram Vels College - Echankadu Signal - S.Kolathur - Kamakshi Hospital - Chennai One - Thoraipakkam - PTC - Karapakkam',
      stops: ['Pallavaram Vels College', 'Echankadu Signal', 'S.Kolathur', 'Kamakshi Hospital', 'Chennai One', 'Thoraipakkam', 'PTC', 'Karapakkam', 'Sathyabama University']),
  '26': SathyabamaRoute(
      routeNo: '26',
      fullRouteString: 'Movarasanpet Kolam - J.K.Mahal - Nanganallur Park - Poorvika - Vanuvampettai Church - Velacherry Railway Station - Kaiveli - Chennai One',
      stops: ['Movarasanpet Kolam', 'J.K.Mahal', 'Nanganallur Park', 'Poorvika', 'Vanuvampettai Church', 'Velacherry Railway Station', 'Kaiveli', 'Chennai One', 'Sathyabama University']),
  '26A': SathyabamaRoute(
      routeNo: '26A',
      fullRouteString: 'Pazhavanthangal Subway - Canara Bank - Poorvika - Pillayar Temple - Anjaneyar Temple - Vanuvampettai Church - Pulithivakkam Police Booth - Kaiveli',
      stops: ['Pazhavanthangal Subway', 'Canara Bank', 'Poorvika', 'Pillayar Temple', 'Anjaneyar Temple', 'Vanuvampettai Church', 'Pulithivakkam Police Booth', 'Kaiveli', 'Sathyabama University']),
  '26B': SathyabamaRoute(
      routeNo: '26B',
      fullRouteString: 'Nangnallur Sub Way - Vanuvanpettai Church - Velacherry Railway Station - Kaiveli - Chennai One',
      stops: ['Nangnallur Sub Way', 'Vanuvanpettai Church', 'Velacherry Railway Station', 'Kaiveli', 'Chennai One', 'Sathyabama University']),
  '27': SathyabamaRoute(
      routeNo: '27',
      fullRouteString: 'Tambaram MCC College - Selaiyur - Camproad - Sembakkam - Kamarajapuram - Santoshpuram',
      stops: ['Tambaram MCC College', 'Selaiyur', 'Camproad', 'Sembakkam', 'Kamarajapuram', 'Santoshpuram', 'Sathyabama University']),
  '27A': SathyabamaRoute(
      routeNo: '27A',
      fullRouteString: 'Indra Nagar - Bharath University - Lakshmi Ammal College - Kovilancherry Erikarai - Sithalabakkam',
      stops: ['Indra Nagar', 'Bharath University', 'Lakshmi Ammal College', 'Kovilancherry Erikarai', 'Sithalabakkam', 'Sathyabama University']),
  '27B': SathyabamaRoute(
      routeNo: '27B',
      fullRouteString: 'SSM Nagar - Mappedu - Agaramthen - Kovilancherry Erikarai - Konar Briyani - Sithalabakkam',
      stops: ['SSM Nagar', 'Mappedu', 'Agaramthen', 'Kovilancherry Erikarai', 'Konar Briyani', 'Sithalabakkam', 'Sathyabama University']),
  '28': SathyabamaRoute(
      routeNo: '28',
      fullRouteString: 'Rajakilpakkam - Sudarsan Nagar - Maruthi Nagar - Kozhi Pannai - Madambakkam Sivan Temple - Sithalabakkam Koot Road - Sithalabakkam',
      stops: ['Rajakilpakkam', 'Sudarsan Nagar', 'Maruthi Nagar', 'Kozhi Pannai', 'Madambakkam Sivan Temple', 'Sithalabakkam Koot Road', 'Sithalabakkam', 'Sathyabama University']),
  '28A': SathyabamaRoute(
      routeNo: '28A',
      fullRouteString: 'Bharath University - Padmavathy Nagar - ALS Nagar - Madambakkam - Rajakilpakkam - Veerapathiranagar - Sowmiyanagar - Navins Apartment',
      stops: ['Bharath University', 'Padmavathy Nagar', 'ALS Nagar', 'Madambakkam', 'Rajakilpakkam', 'Veerapathiranagar', 'Sowmiyanagar', 'Navins Apartment', 'Sathyabama University']),
  '29': SathyabamaRoute(
      routeNo: '29',
      fullRouteString: 'Arasankazhani Signal - Ottiyambakkam - Kaaranai - Nest Apartment',
      stops: ['Arasankazhani Signal', 'Ottiyambakkam', 'Kaaranai', 'Nest Apartment', 'Sathyabama University']),
  '29A': SathyabamaRoute(
      routeNo: '29A',
      fullRouteString: 'Veerapathira Nagar - Sowmiyanagar - Sithalabakkam Koot Road - Sithalabakkam - Ottiyambakkam - Kaaranai - DLF',
      stops: ['Veerapathira Nagar', 'Sowmiyanagar', 'Sithalabakkam Koot Road', 'Sithalabakkam', 'Ottiyambakkam', 'Kaaranai', 'DLF', 'Sathyabama University']),
  '30': SathyabamaRoute(
      routeNo: '30',
      fullRouteString: 'N.G.O Colony - Brindavan Nagar - Velacherry Railway Station - Kaiveli Signal - Thuraipakkam - PTC',
      stops: ['N.G.O Colony', 'Brindavan Nagar', 'Velacherry Railway Station', 'Kaiveli Signal', 'Thuraipakkam', 'PTC', 'Sathyabama University']),
  '30A': SathyabamaRoute(
      routeNo: '30A',
      fullRouteString: 'N.G.O Colony - Brindavan Nagar - Velacherry Railway Station - Kaiveli Signal - Thuraipakkam - PTC',
      stops: ['N.G.O Colony', 'Brindavan Nagar', 'Velacherry Railway Station', 'Kaiveli Signal', 'Thuraipakkam', 'PTC', 'Sathyabama University']),
  '32': SathyabamaRoute(
      routeNo: '32',
      fullRouteString: 'Velacherry Gurunanak College - GRT - Vijaya Nagar - Baby Nagar - Tansi Nagar - Taramani - Perungudi - Jain College - Mettukuppam',
      stops: ['Velacherry Gurunanak College', 'GRT', 'Vijaya Nagar', 'Baby Nagar', 'Tansi Nagar', 'Taramani', 'Perungudi', 'Jain College', 'Mettukuppam', 'Sathyabama University']),
  '32A': SathyabamaRoute(
      routeNo: '32A',
      fullRouteString: 'Velacherry Bus Stand - Velacherry Tansi Nagar - Baby Kovil - Pillayar Kovil - Taramani - Perungudi - Jain College - Mettukuppam',
      stops: ['Velacherry Bus Stand', 'Velacherry Tansi Nagar', 'Baby Kovil', 'Pillayar Kovil', 'Taramani', 'Perungudi', 'Jain College', 'Mettukuppam', 'Sathyabama University']),
  '32B': SathyabamaRoute(
      routeNo: '32B',
      fullRouteString: 'Velacherry Baby Nagar - Pillayarkovil - Taramani - Perungudi - Jain College - Mettukuppam - Karapakkam',
      stops: ['Velacherry Baby Nagar', 'Pillayarkovil', 'Taramani', 'Perungudi', 'Jain College', 'Mettukuppam', 'Karapakkam', 'Sathyabama University']),
  '32C': SathyabamaRoute(
      routeNo: '32C',
      fullRouteString: 'Kandhanchavadi - Perungudi - Thoraipakkam - Jain College - Mettukuppam - Karapakkam - Dollar',
      stops: ['Kandhanchavadi', 'Perungudi', 'Thoraipakkam', 'Jain College', 'Mettukuppam', 'Karapakkam', 'Dollar', 'Sathyabama University']),
  '33': SathyabamaRoute(
      routeNo: '33',
      fullRouteString: 'Taramani - Perungudi Toll Gate - Thoraipakkam - Jain College - Mettukuppam PTC',
      stops: ['Taramani', 'Perungudi Toll Gate', 'Thoraipakkam', 'Jain College', 'Mettukuppam PTC', 'Sathyabama University']),
  '33A': SathyabamaRoute(
      routeNo: '33A',
      fullRouteString: 'Perungudi Toll Gate - Thoraipakkam - Jain College - Mettukuppam PTC - Karapakkam',
      stops: ['Perungudi Toll Gate', 'Thoraipakkam', 'Jain College', 'Mettukuppam PTC', 'Karapakkam', 'Sathyabama University']),
  '33B': SathyabamaRoute(
      routeNo: '33B',
      fullRouteString: 'Thoraipakkam Toll Gate - Jain College - Mettukuppam PTC - Karapakkam - Dollar',
      stops: ['Thoraipakkam Toll Gate', 'Jain College', 'Mettukuppam PTC', 'Karapakkam', 'Dollar', 'Sathyabama University']),
  '33C': SathyabamaRoute(
      routeNo: '33C',
      fullRouteString: 'PTC - Karapakkam - Dollar - Sholinganallur - Aavin - Ponniyamman Temple - HP Petrol Bunk',
      stops: ['PTC', 'Karapakkam', 'Dollar', 'Sholinganallur', 'Aavin', 'Ponniyamman Temple', 'HP Petrol Bunk', 'Sathyabama University']),
  '33D': SathyabamaRoute(
      routeNo: '33D',
      fullRouteString: 'Thoraipakkam Toll Gate - Jain College - Mettukuppam PTC - Karapakkam - Dollar',
      stops: ['Thoraipakkam Toll Gate', 'Jain College', 'Mettukuppam PTC', 'Karapakkam', 'Dollar', 'Sathyabama University']),
  '33E': SathyabamaRoute(
      routeNo: '33E',
      fullRouteString: 'PTC - Karapakkam - Dollar - Sholinganallur - Aavin - Ponniyamman Temple - HP Petrol Bunk',
      stops: ['PTC', 'Karapakkam', 'Dollar', 'Sholinganallur', 'Aavin', 'Ponniyamman Temple', 'HP Petrol Bunk', 'Sathyabama University']),
  '33F': SathyabamaRoute(
      routeNo: '33F',
      fullRouteString: 'PTC - Karapakkam - Dollar - Sholinganallur - Aavin - Ponniyamman Temple - HP Petrol Bunk',
      stops: ['PTC', 'Karapakkam', 'Dollar', 'Sholinganallur', 'Aavin', 'Ponniyamman Temple', 'HP Petrol Bunk', 'Sathyabama University']),
  '33G': SathyabamaRoute(
      routeNo: '33G',
      fullRouteString: 'Karapakkam - Dollar - Sholinganallur - Aavin - Ponniyamman Temple - HP Petrol Bunk',
      stops: ['Karapakkam', 'Dollar', 'Sholinganallur', 'Aavin', 'Ponniyamman Temple', 'HP Petrol Bunk', 'Sathyabama University']),
  '33H': SathyabamaRoute(
      routeNo: '33H',
      fullRouteString: 'Karapakkam - Dollar - Sholinganallur - Aavin - Ponniyamman Temple - HP Petrol Bunk',
      stops: ['Karapakkam', 'Dollar', 'Sholinganallur', 'Aavin', 'Ponniyamman Temple', 'HP Petrol Bunk', 'Sathyabama University']),
  '33(1)': SathyabamaRoute(
      routeNo: '33(1)',
      fullRouteString: 'Madhyakailash - Tidel Park - SRP Tools - Kandhanchavadi - Perungudi - Thoraipakkam - Jain College - Mettukuppam - Karapakkam - Dollar',
      stops: ['Madhyakailash', 'Tidel Park', 'SRP Tools', 'Kandhanchavadi', 'Perungudi', 'Thoraipakkam', 'Jain College', 'Mettukuppam', 'Karapakkam', 'Dollar', 'Sathyabama University']),
  '34A': SathyabamaRoute(
      routeNo: '34A',
      fullRouteString: 'Sholinganallur ECR Toll gate - Ponniyamman Temple - HP Petrol',
      stops: ['Sholinganallur ECR Toll Gate', 'Ponniyamman Temple', 'HP Petrol', 'Sathyabama University']),
  '34B': SathyabamaRoute(
      routeNo: '34B',
      fullRouteString: 'Sholinganallur ECR Toll gate - Ponniyamman Temple - HP Petrol',
      stops: ['Sholinganallur ECR Toll Gate', 'Ponniyamman Temple', 'HP Petrol', 'Sathyabama University']),
  '35': SathyabamaRoute(
      routeNo: '35',
      fullRouteString: 'Pudubakkam - Siruseri - Thalambur - Navalur - AGS - Semmencherry Alamaram',
      stops: ['Pudubakkam', 'Siruseri', 'Thalambur', 'Navalur', 'AGS', 'Semmencherry Alamaram', 'Sathyabama University']),
  '35A': SathyabamaRoute(
      routeNo: '35A',
      fullRouteString: 'Ponmar - Thalambur - Navalur - AGS - Semmencherry Alamaram',
      stops: ['Ponmar', 'Thalambur', 'Navalur', 'AGS', 'Semmencherry Alamaram', 'Sathyabama University']),
  '35B': SathyabamaRoute(
      routeNo: '35B',
      fullRouteString: 'Thalambur - Navalur - AGS - Semmencherry Alamaram',
      stops: ['Thalambur', 'Navalur', 'AGS', 'Semmencherry Alamaram', 'Sathyabama University']),
  '35C': SathyabamaRoute(
      routeNo: '35C',
      fullRouteString: 'Sipcot Signal - Marina Mall - Navalur - AGS - Semmencherry Alamaram',
      stops: ['Sipcot Signal', 'Marina Mall', 'Navalur', 'AGS', 'Semmencherry Alamaram', 'Sathyabama University']),
  '35D': SathyabamaRoute(
      routeNo: '35D',
      fullRouteString: 'Thalambur - Navalur - AGS - Semmencherry Alamaram',
      stops: ['Thalambur', 'Navalur', 'AGS', 'Semmencherry Alamaram', 'Sathyabama University']),
  '36': SathyabamaRoute(
      routeNo: '36',
      fullRouteString: 'Bollini Apartment - Nest Apartment - Kumaran Nagar',
      stops: ['Bollini Apartment', 'Nest Apartment', 'Kumaran Nagar', 'Sathyabama University']),
  '36A': SathyabamaRoute(
      routeNo: '36A',
      fullRouteString: 'Dinesh Vihar Apartment - DLF Garden City Apartment - Nest Apartment - Kumaran Nagar Petrol',
      stops: ['Dinesh Vihar Apartment', 'DLF Garden City Apartment', 'Nest Apartment', 'Kumaran Nagar Petrol', 'Sathyabama University']),
  '36B': SathyabamaRoute(
      routeNo: '36B',
      fullRouteString: 'Perumbakkam Church - Nookampalayam Road - Bollini Apartment - Nest Apartment',
      stops: ['Perumbakkam Church', 'Nookampalayam Road', 'Bollini Apartment', 'Nest Apartment', 'Sathyabama University']),
  '36C': SathyabamaRoute(
      routeNo: '36C',
      fullRouteString: 'DLF Garden City Apartment - Nest Apartment - Kumaran Nagar Petrol',
      stops: ['DLF Garden City Apartment', 'Nest Apartment', 'Kumaran Nagar Petrol', 'Sathyabama University']),
  '37': SathyabamaRoute(
      routeNo: '37',
      fullRouteString: 'Uthandi Toll Gate - Panaiyur - Akkarai - Sholinganallur - Ponniyamman Temple',
      stops: ['Uthandi Toll Gate', 'Panaiyur', 'Akkarai', 'Sholinganallur', 'Ponniyamman Temple', 'Sathyabama University']),
};

final SathyabamaRoute defaultRoute = SathyabamaRoute(
  routeNo: '12',
  fullRouteString: 'Red Hills - Puzhal - Camp - Rettari - Padi - Thirumangalam - Koyambedu - Vadapalani - Alandur Metro',
  stops: ['Red Hills', 'Puzhal', 'Camp', 'Rettari', 'Padi', 'Thirumangalam', 'Koyambedu', 'Vadapalani', 'Alandur Metro', 'Sathyabama University'],
);

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371.0;
  final double dLat = (lat2 - lat1) * math.pi / 180.0;
  final double dLon = (lon2 - lon1) * math.pi / 180.0;

  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180.0) *
          math.cos(lat2 * math.pi / 180.0) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

// =====================================================
// MAIN ENTRY POINT
// =====================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization caught: $e');
  }

  runApp(const SathyabamaTracker());
}

class SathyabamaTracker extends StatelessWidget {
  const SathyabamaTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sathyabama Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// =====================================================
// HOME PAGE WITH FULL BACKGROUND LOGO WATERMARK
// =====================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SATHYABAMA TRACKER',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/sathyabama_logo.png',
                width: MediaQuery.of(context).size.width * 0.85,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.school,
                    size: 200,
                    color: Colors.grey,
                  );
                },
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome! 👋',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Track your college bus in real time',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 40),
                  _buildMenuButton(
                    context,
                    label: 'STUDENT',
                    icon: Icons.school,
                    targetScreen: const StudentHome(),
                  ),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    context,
                    label: 'DRIVER',
                    icon: Icons.drive_eta,
                    targetScreen: const DriverHome(),
                  ),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    context,
                    label: 'ADMIN',
                    icon: Icons.admin_panel_settings,
                    targetScreen: const AdminHome(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Widget targetScreen,
  }) {
    return SizedBox(
      width: 220,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

// =====================================================
// DRIVER SCREEN (STRICT ROUTE VALIDATION ADDED)
// =====================================================

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  StreamSubscription<Position>? positionSubscription;
  String currentBusId = '';
  TextEditingController busController = TextEditingController();

  bool tracking = false;
  bool breakdown = false;
  bool emergency = false;
  bool isMorningRoute = getAutoRouteDirection();

  double latitude = 0;
  double longitude = 0;
  double speed = 0;

  DatabaseReference? get busReference {
    if (currentBusId.isEmpty) return null;
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    ).ref('buses/$currentBusId');
  }

  bool isValidRoute(String inputRoute) {
    String cleanNo = inputRoute.replaceAll('BUS', '').trim().toUpperCase();
    return officialRoutesMap.containsKey(cleanNo);
  }

  Future<void> _fetchCurrentFirebaseState() async {
    if (busReference == null) return;
    try {
      final snapshot = await busReference!.get();
      bool autoDirection = getAutoRouteDirection();

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        if (mounted) {
          setState(() {
            breakdown = data['breakdown'] == true;
            emergency = data['emergency'] == true;
            isMorningRoute = autoDirection;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isMorningRoute = autoDirection;
          });
        }
      }

      await busReference!.update({
        'isMorningRoute': autoDirection,
      });
    } catch (e) {
      debugPrint('Error fetching bus status: $e');
    }
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }

  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please turn ON Location/GPS on your device')),
        );
      }
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required to broadcast bus GPS')),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> startBus() async {
    String rawInput = busController.text.trim().toUpperCase();

    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Bus/Route Number first (e.g., 12, 2F)')),
      );
      return;
    }

    if (!isValidRoute(rawInput)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bus $rawInput does not exist! Please enter a valid route number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String formattedBusId = rawInput.startsWith('BUS') ? rawInput : 'BUS$rawInput';
    setState(() {
      currentBusId = formattedBusId;
    });

    final bool permissionOK = await checkLocationPermission();
    if (!permissionOK) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      double currentSpeed = position.speed * 3.6;
      if (currentSpeed < 0) currentSpeed = 0;

      setState(() {
        tracking = true;
        latitude = position.latitude;
        longitude = position.longitude;
        speed = currentSpeed;
      });

      await updateFirebase(position.latitude, position.longitude, currentSpeed);

      positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position pos) async {
        double spd = pos.speed * 3.6;
        if (spd < 0) spd = 0;

        if (!mounted) return;
        setState(() {
          latitude = pos.latitude;
          longitude = pos.longitude;
          speed = spd;
        });

        await updateFirebase(pos.latitude, pos.longitude, spd);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS Error: $e')));
      }
    }
  }

  Future<void> updateFirebase(double lat, double lon, double spd) async {
    if (busReference == null) return;
    try {
      String routeNo = currentBusId.replaceAll('BUS', '');
      await busReference!.update({
        'busNumber': currentBusId,
        'routeNo': routeNo,
        'isMorningRoute': isMorningRoute,
        'latitude': lat,
        'longitude': lon,
        'speed': spd,
        'status': spd > 2 ? 'RUNNING' : 'STOPPED',
        'breakdown': breakdown,
        'emergency': emergency,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    } catch (e) {
      debugPrint('Firebase update error: $e');
    }
  }

  Future<void> stopBus() async {
    await positionSubscription?.cancel();
    positionSubscription = null;

    setState(() {
      tracking = false;
      speed = 0;
    });

    if (busReference != null) {
      try {
        await busReference!.update({
          'speed': 0,
          'status': 'STOPPED',
          'lastUpdated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      } catch (e) {
        debugPrint('Firebase stop error: $e');
      }
    }
  }

  Future<void> toggleBreakdown() async {
    if (busReference == null) return;
    final bool newBreakdown = !breakdown;
    setState(() => breakdown = newBreakdown);
    await busReference!.update({'breakdown': newBreakdown});
  }

  Future<void> toggleEmergency() async {
    if (busReference == null) return;
    final bool newEmergency = !emergency;
    setState(() => emergency = newEmergency);
    await busReference!.update({'emergency': newEmergency});
  }

  Future<void> toggleRouteDirection(bool morning) async {
    setState(() => isMorningRoute = morning);
    if (busReference != null) {
      await busReference!.update({
        'isMorningRoute': morning,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentBusId.isNotEmpty ? 'DRIVER - $currentBusId' : 'DRIVER PANEL'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: busController,
              decoration: InputDecoration(
                labelText: 'Enter Driver Route / Bus Number (e.g., 12, 2F)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.blue),
                  onPressed: () {
                    String input = busController.text.trim().toUpperCase();
                    if (input.isNotEmpty) {
                      if (!isValidRoute(input)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bus $input does not exist! Please enter a valid route number.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (!input.startsWith('BUS')) input = 'BUS$input';
                      setState(() {
                        currentBusId = input;
                      });
                      _fetchCurrentFirebaseState();
                    }
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.directions_bus, size: 70, color: Colors.blue),
            const SizedBox(height: 5),
            Text(
              currentBusId.isNotEmpty ? '$currentBusId CONTROLS' : 'SELECT BUS NUMBER',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('MORNING'),
                  icon: Icon(Icons.wb_sunny_outlined),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('EVENING'),
                  icon: Icon(Icons.nights_stay_outlined),
                ),
              ],
              selected: {isMorningRoute},
              onSelectionChanged: (Set<bool> newSelection) {
                toggleRouteDirection(newSelection.first);
              },
            ),
            const SizedBox(height: 15),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      tracking ? Icons.gps_fixed : Icons.gps_off,
                      size: 40,
                      color: tracking ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tracking ? 'GPS TRACKING ACTIVE' : 'GPS TRACKING OFF',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tracking ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: tracking ? null : startBus,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('START GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: tracking ? stopBus : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('STOP GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('ALERT CONTROLS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: currentBusId.isNotEmpty ? toggleBreakdown : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: breakdown ? Colors.orange : Colors.grey[300],
                      foregroundColor: breakdown ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(breakdown ? 'BREAKDOWN ON' : 'BREAKDOWN OFF'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: currentBusId.isNotEmpty ? toggleEmergency : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emergency ? Colors.red : Colors.grey[300],
                      foregroundColor: emergency ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(emergency ? 'EMERGENCY ON' : 'EMERGENCY OFF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// STUDENT SCREEN
// =====================================================

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  BitmapDescriptor busIcon = BitmapDescriptor.defaultMarker;
  String searchKeyword = '';
  String? selectedBusId;
  TextEditingController searchController = TextEditingController();

  DatabaseReference get busesReference {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    ).ref('buses');
  }

  @override
  void initState() {
    super.initState();
    _loadCustomBusIcon();
  }

  Future<void> _loadCustomBusIcon() async {
    try {
      final BitmapDescriptor icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/bus_icon.png',
      );
      setState(() {
        busIcon = icon;
      });
    } catch (e) {
      debugPrint('Error loading bus icon asset: $e');
    }
  }

  SathyabamaRoute getRouteInfo(String rawRouteNo) {
    String cleanNo = rawRouteNo.replaceAll('BUS', '').trim();
    if (officialRoutesMap.containsKey(cleanNo)) {
      return officialRoutesMap[cleanNo]!;
    }
    return defaultRoute;
  }

  String calculateETA(double busLat, double busLon, double currentSpeedKmH) {
    double distKm = calculateDistance(busLat, busLon, defaultLatitude, defaultLongitude);
    double effectiveSpeed = (currentSpeedKmH > 5) ? currentSpeedKmH : 30.0;
    double timeInHours = distKm / effectiveSpeed;
    int minutesETA = (timeInHours * 60).round();

    if (minutesETA <= 1) return 'Arriving soon (~1 min)';
    return '$minutesETA mins ($distKm km away)';
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, SathyabamaRoute>> matchedRoutes = [];
    if (searchKeyword.isNotEmpty && selectedBusId == null) {
      String cleanQuery = searchKeyword.toLowerCase().replaceAll(' ', '').trim();

      matchedRoutes = officialRoutesMap.entries.where((entry) {
        String cleanRouteNo = entry.key.toLowerCase().replaceAll(' ', '');

        bool matchesNo = cleanRouteNo.contains(cleanQuery);
        bool matchesStop = entry.value.stops.any((stop) {
          String cleanStop = stop.toLowerCase().replaceAll(' ', '');
          return cleanStop.contains(cleanQuery);
        });

        return matchesNo || matchesStop;
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (selectedBusId != null) {
              setState(() {
                selectedBusId = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SATHYABAMA FLEET',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ),
            Text(
              selectedBusId ?? 'Search Route / Location',
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Type Stop or Bus (e.g., Red Hills, 12, 2F)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchKeyword = '';
                            selectedBusId = null;
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchKeyword = value.trim();
                  selectedBusId = null;
                });
              },
            ),
          ),

          Expanded(
            child: selectedBusId == null
                ? (matchedRoutes.isEmpty
                    ? Center(
                        child: Text(
                          searchKeyword.isEmpty
                              ? 'Enter a location or route number to find buses'
                              : 'No bus routes found matching "$searchKeyword"',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: matchedRoutes.length,
                        itemBuilder: (context, index) {
                          var item = matchedRoutes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.directions_bus,
                                  color: Colors.blue),
                              title: Text('BUS ${item.key}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(item.value.fullRouteString,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16),
                              onTap: () {
                                setState(() {
                                  selectedBusId = 'BUS${item.key}';
                                });
                              },
                            ),
                          );
                        },
                      ))
                : StreamBuilder<DatabaseEvent>(
                    stream: busesReference.child(selectedBusId!).onValue,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = (snapshot.hasData &&
                              snapshot.data!.snapshot.value != null)
                          ? Map<dynamic, dynamic>.from(
                              snapshot.data!.snapshot.value as Map)
                          : {};

                      final String busNumber =
                          data['busNumber']?.toString() ?? selectedBusId!;
                      final String routeNoKey =
                          data['routeNo']?.toString() ?? selectedBusId!;
                      final SathyabamaRoute routeDetails = getRouteInfo(routeNoKey);

                      final double latitude = double.tryParse(
                              data['latitude']?.toString() ?? '') ??
                          defaultLatitude;
                      final double longitude = double.tryParse(
                              data['longitude']?.toString() ?? '') ??
                          defaultLongitude;
                      final double speed =
                          double.tryParse(data['speed']?.toString() ?? '') ?? 0;
                      final bool breakdown = data['breakdown'] == true;
                      final bool emergency = data['emergency'] == true;

                      final bool isMorningRoute = data['isMorningRoute'] ?? getAutoRouteDirection();
                      final int lastUpdated =
                          int.tryParse(data['lastUpdated']?.toString() ?? '') ?? 0;

                      final int currentTimeSec =
                          DateTime.now().millisecondsSinceEpoch ~/ 1000;
                      final bool isOffline =
                          (currentTimeSec - lastUpdated) > 60 && lastUpdated > 0;
                      final String status = isOffline
                          ? 'OFFLINE'
                          : (data['status']?.toString() ?? 'UNKNOWN');

                      final List<String> currentStops = isMorningRoute
                          ? routeDetails.stops
                          : routeDetails.stops.reversed.toList();
                      final String destinationName = currentStops.last;

                      final String liveETA = calculateETA(latitude, longitude, speed);

                      return Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  (latitude != 0) ? latitude : defaultLatitude,
                                  (longitude != 0) ? longitude : defaultLongitude,
                                ),
                                zoom: 12,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId(selectedBusId!),
                                  position: LatLng(latitude, longitude),
                                  icon: busIcon,
                                  infoWindow: InfoWindow(
                                    title: busNumber,
                                    snippet:
                                        '$status • ${speed.toStringAsFixed(1)} km/h',
                                  ),
                                ),
                                const Marker(
                                  markerId: MarkerId('DESTINATION'),
                                  position: LatLng(defaultLatitude, defaultLongitude),
                                  infoWindow: InfoWindow(
                                    title: 'Sathyabama Campus',
                                    snippet: 'Destination',
                                  ),
                                ),
                              },
                              zoomControlsEnabled: true,
                            ),
                          ),

                          Container(
                            color: Colors.blue[50],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.blue),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Estimated Time of Arrival (ETA): $liveETA',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.blue),
                                      ),
                                      Text(
                                        'To $destinationName',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (emergency)
                            Container(
                              width: double.infinity,
                              color: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'EMERGENCY ALERT: $busNumber HAS REPORTED AN EMERGENCY',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (breakdown)
                            Container(
                              width: double.infinity,
                              color: Colors.orange[800],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.build_circle_outlined,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'BREAKDOWN ALERT: $busNumber HAS REPORTED A BREAKDOWN',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              itemCount: currentStops.length,
                              itemBuilder: (context, index) {
                                final bool isFirst = index == 0;
                                final bool isLast =
                                    index == currentStops.length - 1;

                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Positioned(
                                              top: isFirst ? 24 : 0,
                                              bottom: isLast ? 24 : 0,
                                              child: Container(
                                                width: 3,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.black, width: 3),
                                              ),
                                            ),
                                            if (isFirst)
                                              Positioned(
                                                top: 2,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber[700],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.directions_bus,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (isFirst)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 4),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[50],
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'Starting Point',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              Text(
                                                currentStops[index],
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: isFirst
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ADMIN DASHBOARD
// =====================================================

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String searchQuery = '';
  String selectedFilter = 'ALL';
  bool isSeeding = false;
  final TextEditingController adminSearchController = TextEditingController();

  DatabaseReference get busesReference {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    ).ref('buses');
  }

  Future<void> seedOfficialFleet() async {
    setState(() => isSeeding = true);

    Map<String, dynamic> fleetData = {};

    officialRoutesMap.forEach((routeNo, routeObj) {
      String busId = 'BUS$routeNo';
      fleetData[busId] = {
        'busNumber': 'BUS $routeNo',
        'routeNo': routeNo,
        'latitude': defaultLatitude + (math.Random().nextDouble() * 0.05),
        'longitude': defaultLongitude + (math.Random().nextDouble() * 0.05),
        'speed': 35.0,
        'status': 'RUNNING',
        'isMorningRoute': getAutoRouteDirection(),
        'breakdown': false,
        'emergency': false,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    });

    try {
      await busesReference.update(fleetData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${officialRoutesMap.length} Sathyabama Routes into Fleet!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seed Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN - FLEET MANAGEMENT'),
        actions: [
          IconButton(
            icon: isSeeding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            tooltip: 'Populate Official Fleet',
            onPressed: isSeeding ? null : seedOfficialFleet,
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: busesReference.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<dynamic, dynamic> busesMap = {};
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            busesMap =
                Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          }

          int runningCount = 0;
          int breakdownCount = 0;
          int emergencyCount = 0;

          officialRoutesMap.forEach((routeNo, routeObj) {
            String busId = 'BUS$routeNo';
            if (busesMap.containsKey(busId)) {
              Map busData = Map.from(busesMap[busId] as Map);
              if (busData['status'] == 'RUNNING') runningCount++;
              if (busData['breakdown'] == true) breakdownCount++;
              if (busData['emergency'] == true) emergencyCount++;
            }
          });

          List<MapEntry<String, SathyabamaRoute>> allRoutesList = officialRoutesMap.entries.toList();

          List<MapEntry<String, SathyabamaRoute>> filteredRoutes = allRoutesList.where((entry) {
            String routeNoKey = entry.key;
            SathyabamaRoute routeObj = entry.value;

            String busId = 'BUS$routeNoKey';
            Map busData = Map.from(busesMap[busId] ?? {});

            String status = (busData['status'] ?? 'STOPPED').toString().toUpperCase();
            bool isBreakdown = busData['breakdown'] == true;
            bool isEmergency = busData['emergency'] == true;

            String cleanQuery = searchQuery.toLowerCase().replaceAll(' ', '').trim();

            String cleanRouteNo = routeNoKey.toLowerCase().replaceAll(' ', '');
            String cleanBusId = busId.toLowerCase().replaceAll(' ', '');
            String cleanRouteString = routeObj.fullRouteString.toLowerCase().replaceAll(' ', '');

            bool matchesSearch = cleanQuery.isEmpty ||
                cleanRouteNo.contains(cleanQuery) ||
                cleanBusId.contains(cleanQuery) ||
                cleanRouteString.contains(cleanQuery) ||
                routeObj.stops.any((s) => s.toLowerCase().replaceAll(' ', '').contains(cleanQuery));

            bool matchesFilter = true;
            if (selectedFilter == 'RUNNING') matchesFilter = status == 'RUNNING';
            if (selectedFilter == 'BREAKDOWN') matchesFilter = isBreakdown;
            if (selectedFilter == 'EMERGENCY') matchesFilter = isEmergency;

            return matchesSearch && matchesFilter;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatCard('Total', '${officialRoutesMap.length}', Colors.blue),
                    _buildStatCard('Running', '$runningCount', Colors.green),
                    _buildStatCard(
                        'Breakdowns', '$breakdownCount', Colors.orange),
                    _buildStatCard('Emergencies', '$emergencyCount', Colors.red),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: adminSearchController,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    labelText: 'Search Bus / Location (e.g., Red Hills, 12, 2F)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: adminSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              adminSearchController.clear();
                              setState(() => searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['ALL', 'RUNNING', 'BREAKDOWN', 'EMERGENCY'].map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: selectedFilter == filter,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedFilter = filter);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: filteredRoutes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No buses match "$searchQuery"',
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: seedOfficialFleet,
                                icon: const Icon(Icons.cloud_upload),
                                label: const Text('Populate Sathyabama Fleet'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredRoutes.length,
                          itemBuilder: (context, index) {
                            var item = filteredRoutes[index];
                            String routeNo = item.key;
                            SathyabamaRoute routeObj = item.value;

                            String busId = 'BUS$routeNo';
                            Map busData = Map.from(busesMap[busId] ?? {});

                            bool isBreakdown = busData['breakdown'] == true;
                            bool isEmergency = busData['emergency'] == true;
                            String status = busData['status'] ?? 'STOPPED';
                            var speed = busData['speed'] ?? 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: isEmergency
                                  ? Colors.red[50]
                                  : (isBreakdown
                                      ? Colors.orange[50]
                                      : Colors.white),
                              child: ListTile(
                                leading: Icon(
                                  Icons.directions_bus,
                                  color: isEmergency
                                      ? Colors.red
                                      : (isBreakdown
                                          ? Colors.orange
                                          : Colors.blue),
                                ),
                                title: Text('BUS $routeNo',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${routeObj.fullRouteString}\nStatus: $status | Speed: $speed km/h'),
                                isThreeLine: true,
                                trailing: isEmergency
                                    ? const Text('EMERGENCY',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold))
                                    : (isBreakdown
                                        ? const Text('BREAKDOWN',
                                            style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold))
                                        : null),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(count,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}