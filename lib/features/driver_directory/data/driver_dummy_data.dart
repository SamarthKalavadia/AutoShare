// ============================================================
//  DRIVER DUMMY DATA
// ============================================================
//
//  ✏️  HOW TO REPLACE WITH REAL DATA:
//
//  This is the ONLY file you need to edit to add real drivers.
//  Simply replace the sample entries below with real ones.
//
//  Rules:
//  - driverId  : any unique string (e.g. 'd001', 'd002' …)
//  - phoneNumber: digits only, with country code, no '+' or spaces
//                 Example: '919876543210' (91 = India)
//  - rating    : 1.0 – 5.0 (shown on card)
//  - verified  : set true once you've personally verified the driver
//  - available : set false if driver is temporarily unavailable
//
// ============================================================

import '../models/driver_model.dart';

const List<DriverModel> kDummyDrivers = [
  DriverModel(
    driverId: 'd001',
    name: 'Driver 1',
    phoneNumber: '919000000001',
    area: 'Indiranagar',
    city: 'Bangalore',
    available: true,
    verified: true,
    rating: 4.9,
  ),
  DriverModel(
    driverId: 'd002',
    name: 'Driver 2',
    phoneNumber: '919000000002',
    area: 'Koramangala',
    city: 'Bangalore',
    available: true,
    verified: true,
    rating: 4.7,
  ),
  DriverModel(
    driverId: 'd003',
    name: 'Driver 3',
    phoneNumber: '919000000003',
    area: 'HSR Layout',
    city: 'Bangalore',
    available: false,
    verified: false,
    rating: 4.2,
  ),
  DriverModel(
    driverId: 'd004',
    name: 'Driver 4',
    phoneNumber: '919000000004',
    area: 'Whitefield',
    city: 'Bangalore',
    available: true,
    verified: true,
    rating: 4.8,
  ),
  DriverModel(
    driverId: 'd005',
    name: 'Driver 5',
    phoneNumber: '919000000005',
    area: 'Electronic City',
    city: 'Bangalore',
    available: false,
    verified: false,
    rating: 3.9,
  ),
];
