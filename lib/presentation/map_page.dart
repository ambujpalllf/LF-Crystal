import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/cubit/map/map_cubit.dart';
import 'package:lf_crystal/cubit/map/map_state.dart';
import 'package:lf_crystal/widget/custom_app_dialogue.dart';
import 'package:lf_crystal/widget/custom_elevated_btn.dart';
import 'package:lf_crystal/widget/custom_textform_field.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Map<String, dynamic>> predictedLocations = [];
  GoogleMapController? mapController;
  String selectedType = "Hybrid";
  MapType _mapType = MapType.hybrid;
  TextEditingController searchC = TextEditingController();

  LatLng? _center;
  Set<Marker> markers = {};
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    context.read<MapCubit>().getCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
    searchC.dispose();
    mapController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomElevatedButton(
                    backgroundColor: Colors.grey.shade300,
                    borderRadius: 0.0,
                    onPressed: () {
                      Navigator.pop(context, _center);
                    },
                    textStyle: AppTextStyle.ts16MB,
                    textColor: AppColors.black,
                    text: "SELECT LOCATION",
                  ),
                  CustomElevatedButton(
                    backgroundColor: Colors.grey.shade300,
                    textStyle: AppTextStyle.ts16MB,
                    textColor: AppColors.black,
                    borderRadius: 0.0,
                    onPressed: () async {
                      final result = await CustomAppDialogue.mapTypeDialogue(
                        context: context,
                        selectedType: selectedType,
                      );
                      if (result != null) {
                        setState(() {
                          selectedType = result;
                          _mapType = _getMapTypeFromString(result);
                        });
                      }
                    },
                    text: "MAP TYPE",
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Tap on the map to pick location.",
                style: AppTextStyle.ts14MB.copyWith(color: Colors.grey.shade600),
              ),
            ),

            BlocBuilder<MapCubit, MapState>(
              builder: (BuildContext context, MapState state) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child:
                      _center == null
                          ? SizedBox.shrink()
                          : Text(
                            "${_center!.latitude},  ${_center!.longitude}",
                            style: AppTextStyle.ts14MB.copyWith(color: Colors.grey.shade400),
                          ),
                );
              },
            ),

            BlocConsumer<MapCubit, MapState>(
              builder: (context, state) {
                if (state is LocationLodingState) {
                  return Center(child: CircularProgressIndicator());
                }
                return Expanded(
                  child:
                      _center == null
                          ? Center(child: CircularProgressIndicator())
                          : Stack(
                            children: [
                              GoogleMap(
                                onMapCreated: _onMapCreated,
                                initialCameraPosition: CameraPosition(target: _center!, zoom: 5),
                                mapType: _mapType,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                markers: markers,
                                onTap: context.read<MapCubit>().onMapSelectLocation,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 60.0),
                                child: CustomTextformField(
                                  filled: true,
                                  fillColor: AppColors.white,
                                  controller: searchC,
                                  hintText: "Search location here...",
                                  onChanged: (value) {
                                    if (value.isNotEmpty && value.length >= 3) {
                                      context.read<MapCubit>().getSuggestions(searchC.text);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 120.0),
                                child: BlocBuilder<MapCubit, MapState>(
                                  buildWhen:
                                      (previous, current) =>
                                          current is SelectLocationState || current is PridictedLocations,
                                  builder: (_, state) {
                                    if (state is PridictedLocations) {
                                      predictedLocations.clear();
                                      predictedLocations.addAll(state.pridictedData);
                                    }
                                    return predictedLocations.isEmpty
                                        ? SizedBox.shrink()
                                        : ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: predictedLocations.length,
                                          itemBuilder: (_, index) {
                                            return InkWell(
                                              onTap: () {
                                                context.read<MapCubit>().selectPlace(
                                                  predictedLocations[index]["place_id"],
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(bottom: 8.0),
                                                child: Container(
                                                  padding: EdgeInsets.all(10.0),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(4.0),
                                                    color: AppColors.white,
                                                  ),
                                                  child: Text(predictedLocations[index]["description"]),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                  },
                                ),
                              ),
                            ],
                          ),
                );
              },
              listener: (BuildContext context, MapState state) {
                if (state is MapErrorState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AppColors.red, content: Text(state.message, style: AppTextStyle.ts14RW)),
                  );
                } else if (state is GetLocationState) {
                  _center = LatLng(state.position.latitude ?? 0.0, state.position.longitude ?? 0.0);
                  markers.clear();
                  markers.add(Marker(markerId: const MarkerId("current_location"), position: _center!));
                } else if (state is SelectLocationState) {
                  _center = LatLng(state.tapPosition.latitude, state.tapPosition.longitude);
                  mapController?.animateCamera(CameraUpdate.newLatLng(_center!));
                  predictedLocations.clear();
                  searchC.clear();
                  setState(() {
                    markers.clear();
                    markers.add(
                      Marker(
                        markerId: const MarkerId("selected_location"),
                        position: _center!,
                        infoWindow: InfoWindow(title: state.locationName ?? ""),
                      ),
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  MapType _getMapTypeFromString(String type) {
    switch (type) {
      case "Normal":
        return MapType.normal;
      case "Satellite":
        return MapType.satellite;
      case "Terrain":
        return MapType.terrain;
      case "Hybrid":
      default:
        return MapType.hybrid;
    }
  }
}
