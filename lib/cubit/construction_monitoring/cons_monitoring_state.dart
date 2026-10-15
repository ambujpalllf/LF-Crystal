abstract class ConsMonitoringState {}

class InitState extends ConsMonitoringState {}

class LoadingState extends ConsMonitoringState {}

class SuccessState extends ConsMonitoringState {
  final String message;
  SuccessState({required this.message});
}

class ErrorState extends ConsMonitoringState {
  final String message;
  ErrorState({required this.message});
}

class PlinthState extends ConsMonitoringState {
  final bool isEnable;
  PlinthState({required this.isEnable});
}

class ValidationState extends ConsMonitoringState {
  final String? floorEr;
  final String? slabsEr;
  final String? plinthEr;
  final String? rccEr;
  final String? bwUptoSlabEr;
  final String? plasteringInternalEr;
  final String? plasteringExternalEr;
  final String? flooringEr;
  final String? electricEr;
  final String? plumbingEr;
  final String? woodWorkEr;
  final String? paintingEr;
  ValidationState({
    this.floorEr,
    this.slabsEr,
    this.plinthEr,
    this.rccEr,
    this.bwUptoSlabEr,
    this.plasteringInternalEr,
    this.plasteringExternalEr,
    this.flooringEr,
    this.electricEr,
    this.plumbingEr,
    this.woodWorkEr,
    this.paintingEr,
  });

  ValidationState copyWith({
    String? floorEr,
    String? slabsEr,
    String? plinthEr,
    String? rccEr,
    String? bwUptoSlabEr,
    String? plasteringInternalEr,
    String? plasteringExternalEr,
    String? flooringEr,
    String? electricEr,
    String? plumbingEr,
    String? woodWorkEr,
    String? paintingEr,
  }) {
    return ValidationState(
      floorEr: floorEr ?? this.floorEr,
      slabsEr: slabsEr ?? this.slabsEr,
      plinthEr: plinthEr ?? this.plinthEr,
      rccEr: rccEr ?? this.rccEr,
      bwUptoSlabEr: bwUptoSlabEr ?? this.bwUptoSlabEr,
      plasteringInternalEr: plasteringInternalEr ?? this.plasteringInternalEr,
      plasteringExternalEr: plasteringExternalEr ?? this.plasteringExternalEr,
      flooringEr: flooringEr ?? this.flooringEr,
      electricEr: electricEr ?? this.electricEr,
      plumbingEr: plumbingEr ?? this.plumbingEr,
      woodWorkEr: woodWorkEr ?? this.woodWorkEr,
      paintingEr: paintingEr ?? this.paintingEr,
    );

    //    return ValidationState(
    //   floorEr: floorEr,
    //   slabsEr: slabsEr,
    //   plinthEr: plinthEr,
    //   rccEr: rccEr,
    //   bwUptoSlabEr: bwUptoSlabEr,
    //   plasteringInternalEr: plasteringInternalEr,
    //   plasteringExternalEr: plasteringExternalEr,
    //   flooringEr: flooringEr,
    //   electricEr: electricEr,
    //   plumbingEr: plumbingEr,
    //   woodWorkEr: woodWorkEr,
    //   paintingEr: paintingEr,
    // );
  }
}
