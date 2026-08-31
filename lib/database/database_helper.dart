import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/model/image_entity_model.dart';
import 'package:lf_crystal/model/location_model.dart';
import 'package:lf_crystal/model/photo_category_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DBHelper {
  static const _dbName = 'lf_crystal.db';
  static const _dbVersion = 1;

  static final DBHelper instance = DBHelper._privateConstructor();
  static Database? _database;

  DBHelper._privateConstructor();

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);

    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS home_data (
        id INTEGER PRIMARY KEY,
        json TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           category_type TEXT
         );
    ''');

    await db.execute('''
          CREATE TABLE IF NOT EXISTS sub_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER,
            sub_category_type TEXT,
            FOREIGN KEY(category_id) REFERENCES categories(id)
          );
        ''');

    await db.execute('''
          CREATE TABLE IF NOT EXISTS photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT NOT NULL,
            valueEmpId INTEGER NOT NULL,
            siteId INTEGER NOT NULL,
            selectedCategoryTitle TEXT NOT NULL,
            selectedSubCategoryTitle TEXT NOT NULL,
            photoId INTEGER NOT NULL,
            serialOrder INTEGER NOT NULL,
            sync INTEGER NOT NULL,
            syncSerialOrder INTEGER NOT NULL,
            moDateTime TEXT NOT NULL,
            imgLatitude TEXT NOT NULL,
            imgLongitude TEXT NOT NULL,
            imgAccuracy TEXT NOT NULL
          )
      ''');

    await db.execute('''
          CREATE TABLE location (
            GPS_TRACKER_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            GPS_TRACKER_DATE_TIME TEXT,
            LATITUDE REAL,
            LONGITUDE REAL,
            MOBILE_APP_ID INTEGER,
            USERS_ID INTEGER,
            BATTERY_PERC INTEGER,
            ACCURACY REAL,
            IS_MOCK TEXT,
            PROVIDER TEXT
          )
      ''');
  }

  // await db.execute('''
  //       CREATE TABLE location (
  //         id INTEGER PRIMARY KEY AUTOINCREMENT,
  //         userId INTEGER NOT NULL,
  //         latitude REAL NOT NULL,
  //         longitude REAL NOT NULL,
  //         accuracy REAL NOT NULL,
  //         timestamp TEXT NOT NULL,
  //         batteryPercentage REAL NOT NULL
  //       )
  //   ''');
  static Future<int> insertHomeData(HomeData newHomeData) async {
    try {
      final db = await database;
      final existing = await db.query('home_data', where: 'id = ?', whereArgs: [1]);

      if (existing.isNotEmpty) {
        // Existing data found
        final existingJsonString = existing.first['json'] as String;
        final existingMap = jsonDecode(existingJsonString);
        final existingHomeData = HomeData.fromJson(existingMap);

        // Merge existing and new data
        final mergedHomeData = mergeHomeData(existingHomeData, newHomeData);

        final updatedJsonString = jsonEncode(mergedHomeData.toJson());
        final updated = await db.update(
          'home_data',
          {'json': updatedJsonString},
          where: 'id = ?',
          whereArgs: [1],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('Rows updated: $updated');
        return 1;
      } else {
        // Insert fresh
        final jsonString = jsonEncode(newHomeData.toJson());
        await db.insert('home_data', {'id': 1, 'json': jsonString});

        return 1;
      }
    } catch (e) {
      debugPrint("DB Save home Error: $e");
      return -1;
    }
  }

  static HomeData mergeHomeData(HomeData existing, HomeData incoming) {
    // === Merge surveyDetails ===
    final List<SurveyDetail> mergedSurveyDetails = [...existing.surveyDetails ?? []];

    for (var newDetail in incoming.surveyDetails ?? []) {
      final newSiteId = newDetail.basicDetails?.siteId;

      final alreadyExists = mergedSurveyDetails.any(
        (existingDetail) => existingDetail.basicDetails?.siteId == newSiteId,
      );

      if (!alreadyExists) {
        mergedSurveyDetails.add(newDetail);
      }
    }

    // === Merge spinnerMaster ===
    final Map<String, List<SpinnerMaster>> mergedSpinnerMaster = {};

    // Add all existing entries
    if (existing.spinnerMaster != null) {
      for (var key in existing.spinnerMaster!.keys) {
        mergedSpinnerMaster[key] = [...existing.spinnerMaster![key]!];
      }
    }

    // Merge incoming entries
    if (incoming.spinnerMaster != null) {
      for (var key in incoming.spinnerMaster!.keys) {
        final newList = incoming.spinnerMaster![key]!;

        if (mergedSpinnerMaster.containsKey(key)) {
          final existingList = mergedSpinnerMaster[key]!;

          for (var newItem in newList) {
            // final exists = existingList.any((e) => e.id == newItem.id);
            final exists = existingList.any((e) => e.key == newItem.key && e.value == newItem.value);

            if (!exists) {
              existingList.add(newItem);
            }
          }
        } else {
          mergedSpinnerMaster[key] = [...newList];
        }
      }
    }

    // === Return new HomeData ===
    return HomeData(surveyDetails: mergedSurveyDetails, spinnerMaster: mergedSpinnerMaster);
  }

  static Future<List<HomeData>> getAllHomeData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('home_data');

      return List.generate(maps.length, (i) {
        final jsonString = maps[i]['json'] as String;
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return HomeData.fromJson(jsonMap);
      });
    } catch (e) {
      debugPrint("DB Read home Error: $e");
      return [];
    }
  }

  static Future<int> updateHomeData(HomeData updatedHomeData) async {
    try {
      final db = await database;
      final String jsonString = jsonEncode(updatedHomeData.toJson());

      // Check if row with id = 1 exists
      final existingRecords = await db.query('home_data', where: 'id = ?', whereArgs: [1]);

      if (existingRecords.isEmpty) {
        debugPrint("Update failed: No existing record found with id = 1.");
        return 0; // Nothing to update
      }

      // Proceed with update
      int updated = await db.update(
        'home_data',
        {'json': jsonString},
        where: 'id = ?',
        whereArgs: [1],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('Rows updated: $updated');

      if (updated == 0) {
        debugPrint("Update attempted but no rows were changed.");
      }

      return updated; // Return how many rows were updated
    } catch (e) {
      debugPrint("DB Update home Error: $e");
      return -1;
    }
  }

  static Future<int> updateBasicDetailsBySiteId(int siteId, BasicDetails newDetails) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('home_data', where: 'id = ?', whereArgs: [1]);

      if (maps.isEmpty) return -1;

      final existingJson = maps.first['json'] as String;
      final existingHomeData = HomeData.fromJson(jsonDecode(existingJson));

      bool updated = false;

      // Find and update the correct survey by siteId
      for (var survey in existingHomeData.surveyDetails!) {
        if (survey.basicDetails!.siteId == siteId) {
          survey.basicDetails = newDetails;
          updated = true;
          break;
        }
      }

      if (!updated) return 0; // No matching siteId found

      // Serialize and update the DB
      final String updatedJson = jsonEncode(existingHomeData.toJson());

      return await db.update('home_data', {'json': updatedJson}, where: 'id = ?', whereArgs: [1]);
    } catch (e) {
      debugPrint("DB Update basicDetails by siteId Error: $e");
      return -1;
    }
  }

  static Future<void> deleteBasicDetailsBySiteId(int siteIdToRemove) async {
    try {
      final db = await database;

      // Step 1: Get the latest HomeData row (assuming only one)
      final List<Map<String, dynamic>> maps = await db.query('home_data', orderBy: 'id DESC', limit: 1);

      if (maps.isEmpty) {
        debugPrint("No home_data found in DB.");
        return;
      }

      final rowId = maps.first['id'];
      final jsonString = maps.first['json'] as String;

      // Step 2: Parse JSON into HomeData
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final HomeData homeData = HomeData.fromJson(jsonMap);

      // Step 3: Remove SurveyDetail where basicDetails.siteId == siteIdToRemove
      homeData.surveyDetails?.removeWhere((detail) => detail.basicDetails?.siteId == siteIdToRemove);

      // Step 4: Convert back to JSON and update DB
      final updatedJsonString = jsonEncode(homeData.toJson());

      await db.update('home_data', {'json': updatedJsonString}, where: 'id = ?', whereArgs: [rowId]);

      debugPrint("Successfully deleted BasicDetails with siteId: $siteIdToRemove");
    } catch (e) {
      debugPrint("Error deleting BasicDetails: $e");
    }
  }

  static Future<void> insertCategory(List<CategoryDatum> categories) async {
    final db = await database;

    for (var category in categories) {
      final categoryId = await db.insert('categories', {'category_type': category.categoryType});

      for (var sub in category.subCategory ?? []) {
        await db.insert('sub_categories', {'category_id': categoryId, 'sub_category_type': sub.subCategoryType});
      }
    }
  }

  static Future<List<CategoryDatum>> getCategories() async {
    final db = await database;
    List<CategoryDatum> categoryList = [];
    final categories = await db.query('categories');

    for (var cat in categories) {
      final subCats = await db.query('sub_categories', where: 'category_id = ?', whereArgs: [cat['id']]);

      categoryList.add(
        CategoryDatum(
          categoryType: cat['category_type'] as String?,
          subCategory: subCats.map((sub) => SubCategory(subCategoryType: sub['sub_category_type'] as String?)).toList(),
        ),
      );
    }

    return categoryList;
  }

  static Future<void> insertImage(ImageEntity image) async {
    final db = await database;
    await db.insert('photos', image.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> insertMultiImages(List<ImageEntity> images) async {
    final db = await database;
    Batch batch = db.batch();
    for (var image in images) {
      batch.insert('photos', image.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> updateImage(ImageEntity image) async {
    final db = await database;
    await db.update(
      'photos',
      image.toMap(),
      // where: 'photoId = ?',
      // whereArgs: [image.photoId],
      where: 'id = ?',
      whereArgs: [image.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateAllImg(List<ImageEntity> images) async {
    final db = await database;

    final batch = db.batch();

    for (final image in images) {
      batch.update(
        'photos',
        image.toMap(),
        where: 'id = ?',
        whereArgs: [image.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<List<ImageEntity>> getImagesBySiteId(int siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('photos', where: 'siteId = ?', whereArgs: [siteId]);

    return List.generate(maps.length, (i) {
      return ImageEntity.fromMap(maps[i]);
    });
  }

  static Future<ImageEntity?> getImgByPath({required int siteId, required String imgPath}) async {
    final db = await database;
    final maps = await db.query(
      'photos',
      where: 'siteId = ? AND imagePath = ?',
      whereArgs: [siteId, imgPath],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ImageEntity.fromMap(maps.first);
  }

  static Future<List<ImageEntity>> getUnsyncImgBySiteId(int siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'siteId = ? AND sync = ?',
      whereArgs: [siteId, 0],
    );

    return List.generate(maps.length, (i) {
      return ImageEntity.fromMap(maps[i]);
    });
  }

  static Future<List<ImageEntity>> getSelfie(int siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'siteId = ? AND selectedCategoryTitle = ?',
      whereArgs: [siteId, "Selfie"],
    );

    return List.generate(maps.length, (i) {
      return ImageEntity.fromMap(maps[i]);
    });
  }

  static Future<List<ImageEntity>> getAllImages() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query('photos');

    return List.generate(maps.length, (i) {
      return ImageEntity.fromMap(maps[i]);
    });
  }

  static Future<List<ImageEntity>> getAllUnsyncImages() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query('photos', where: 'sync = ?', whereArgs: [0]);

    return List.generate(maps.length, (i) {
      return ImageEntity.fromMap(maps[i]);
    });
  }

  static Future<void> deleteImageBySiteIdAndPath(int siteId, String imagePath) async {
    final db = await database;
    await db.delete('photos', where: 'siteId = ? AND imagePath = ?', whereArgs: [siteId, imagePath]);
  }

  static Future<void> deleteImageByPath(String imagePath) async {
    final db = await database;
    await db.delete('photos', where: 'imagePath = ?', whereArgs: [imagePath]);
  }

  static Future<void> deleteImageById(int id) async {
    final db = await database;
    await db.delete('photos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteImageBySiteId(int siteId) async {
    final db = await database;
    await db.delete('photos', where: 'siteId = ?', whereArgs: [siteId]);
  }

  static Future<int> insertLocation(LocationModel location) async {
    final db = await database;
    return await db.insert('location', location.toMap());
  }

  static Future<List<LocationModel>> getAllLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('location');
    return maps.map((map) => LocationModel.fromMap(map)).toList();
  }

  // DELETE
  static Future<int> deleteLocation({required int gpsTrackerId}) async {
    final db = await database;
    return await db.delete('location', where: 'GPS_TRACKER_ID = ?', whereArgs: [gpsTrackerId]);
  }

  static Future<int> deleteAllLocations() async {
    final db = await database;
    return await db.delete('location');
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('home_data');
    await db.delete('categories');
    await db.delete('sub_categories');
    await db.delete('photos');
    await db.delete('location');
  }
}
