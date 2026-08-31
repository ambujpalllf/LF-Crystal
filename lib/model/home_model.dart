import 'dart:convert';

HomeResponse homeResponseFromJson(String str) => HomeResponse.fromJson(json.decode(str));
String homeResponseToJson(HomeResponse data) => json.encode(data.toJson());

class HomeResponse {
  HomeData? data;
  String? status;
  String? message;

  HomeResponse({this.data, this.status, this.message});

  factory HomeResponse.fromJson(Map<String, dynamic> json) => HomeResponse(
    data: json["data"] == null ? null : HomeData.fromJson(json["data"]),
    status: json["status"],
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {"data": data?.toJson(), "status": status, "message": message};
}

class HomeData {
  Map<String, List<SpinnerMaster>>? spinnerMaster;
  List<SurveyDetail>? surveyDetails;

  HomeData({this.spinnerMaster, this.surveyDetails});

  factory HomeData.fromJson(Map<String, dynamic> json) => HomeData(
    spinnerMaster:
        json["spinnerMaster"] == null
            ? null
            : Map.from(json["spinnerMaster"]).map(
              (k, v) => MapEntry<String, List<SpinnerMaster>>(
                k,
                List<SpinnerMaster>.from(v.map((x) => SpinnerMaster.fromJson(x))),
              ),
            ),
    surveyDetails:
        json["SurveyDetails"] == null
            ? []
            : List<SurveyDetail>.from(json["SurveyDetails"].map((x) => SurveyDetail.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "spinnerMaster":
        spinnerMaster == null
            ? null
            : Map.from(
              spinnerMaster!,
            ).map((k, v) => MapEntry<String, dynamic>(k, List<dynamic>.from(v.map((x) => x.toJson())))),
    "SurveyDetails": surveyDetails == null ? [] : List<dynamic>.from(surveyDetails!.map((x) => x.toJson())),
  };
}

class SpinnerMaster {
  String? key;
  String? value;

  SpinnerMaster({this.key, this.value});

  factory SpinnerMaster.fromJson(Map<String, dynamic> json) => SpinnerMaster(key: json["Key"], value: json["Value"]);

  Map<String, dynamic> toJson() => {"Key": key, "Value": value};
}

class SurveyDetail {
  BasicDetails? basicDetails;
  SiteDetails? siteDetails;

  SurveyDetail({this.basicDetails, this.siteDetails});

  factory SurveyDetail.fromJson(Map<String, dynamic> json) => SurveyDetail(
    basicDetails: json["BasicDetails"] == null ? null : BasicDetails.fromJson(json["BasicDetails"]),
    siteDetails: json["SiteDetails"] == null ? null : SiteDetails.fromJson(json["SiteDetails"]),
  );

  Map<String, dynamic> toJson() => {"BasicDetails": basicDetails?.toJson(), "SiteDetails": siteDetails?.toJson()};
}

class BasicDetails {
  int? siteId;
  int? initId;
  int? siteEngineerId;
  String? caseId;
  int? bankId;
  String? bankName;
  int? siteEngAccepted;
  String? appointmentDatetime;
  String? visitDate;
  String? visitStatus;
  int? appointmentStatus;
  String? appointmentRemarks;
  String? applicantNameSite;
  String? addressAsPerSite;
  String? contactName;
  String? contactNo;
  int? siteSubmitted;
  String? siteRejectReason;
  String? propertyType;
  String? mobDatetime;
  bool? isSelfieTaken;
  bool? isFormSaved;

  BasicDetails({
    this.siteId,
    this.initId,
    this.siteEngineerId,
    this.caseId,
    this.bankId,
    this.bankName,
    this.siteEngAccepted,
    this.appointmentDatetime,
    this.visitDate,
    this.visitStatus,
    this.appointmentStatus,
    this.appointmentRemarks,
    this.applicantNameSite,
    this.addressAsPerSite,
    this.contactName,
    this.contactNo,
    this.siteSubmitted,
    this.siteRejectReason,
    this.propertyType,
    this.mobDatetime,
    this.isSelfieTaken,
    this.isFormSaved,
  });

  factory BasicDetails.fromJson(Map<String, dynamic> json) => BasicDetails(
    siteId: json["site_id"],
    initId: json["init_id"],
    siteEngineerId: json["site_engineer_id"],
    caseId: json["case_id"],
    bankId: json["bank_id"],
    bankName: json["bank_name"],
    siteEngAccepted: json["site_eng_accepted"],
    appointmentDatetime: json["appointment_datetime"],
    visitDate: json["visit_date"],
    visitStatus: json["visit_status"],
    appointmentStatus: json["appointment_status"],
    appointmentRemarks: json["appointment_remarks"],
    applicantNameSite: json["applicant_name_site"],
    addressAsPerSite: json["address_as_per_site"],
    contactName: json["contact_name"],
    contactNo: json["contact_no"],
    siteSubmitted: json["site_submitted"],
    siteRejectReason: json["site_reject_reason"],
    propertyType: json["property_type"],
    mobDatetime: json["mob_datetime"],
    isSelfieTaken: json["is_selfie_taken"] == null ? null : json["is_selfie_taken"] == 1,
    isFormSaved: json["is_form_saved"] == null ? null : json["is_form_saved"] == 1,
  );

  Map<String, dynamic> toJson() => {
    "site_id": siteId,
    "init_id": initId,
    "site_engineer_id": siteEngineerId,
    "case_id": caseId,
    "bank_id": bankId,
    "bank_name": bankName,
    "site_eng_accepted": siteEngAccepted,
    "appointment_datetime": appointmentDatetime,
    "visit_date": visitDate,
    "visit_status": visitStatus,
    "appointment_status": appointmentStatus,
    "appointment_remarks": appointmentRemarks,
    "applicant_name_site": applicantNameSite,
    "address_as_per_site": addressAsPerSite,
    "contact_name": contactName,
    "contact_no": contactNo,
    "site_submitted": siteSubmitted,
    "site_reject_reason": siteRejectReason,
    "property_type": propertyType,
    "mob_datetime": mobDatetime,
    "is_selfie_taken": isSelfieTaken == null ? null : (isSelfieTaken! ? 1 : 0),
    "is_form_saved": isFormSaved == null ? null : (isFormSaved! ? 1 : 0),
  };
}

class SiteDetails {
  dynamic dynamicField;
  List<Field>? fields;

  SiteDetails({this.dynamicField, this.fields});

  factory SiteDetails.fromJson(Map<String, dynamic> json) => SiteDetails(
    dynamicField: json["DynamicField"],
    fields: json["Fields"] == null ? [] : List<Field>.from(json["Fields"].map((x) => Field.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "DynamicField": dynamicField,
    "Fields": fields == null ? [] : List<dynamic>.from(fields!.map((x) => x.toJson())),
  };
}

class Field {
  String? name;
  String? label;
  String? type;
  String? value;
  String? dataType;
  bool? isMandatory;
  bool? isEditable;
  int? fieldLength;

  Field({
    this.name,
    this.label,
    this.type,
    this.value,
    this.dataType,
    this.isMandatory,
    this.isEditable,
    this.fieldLength,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      name: json['Name'],
      label: json['Label'],
      type: json['Type'],
      value: json['Value'],
      dataType: json['data_type'],
      isMandatory: json['is_mandatory'],
      isEditable: json['is_editable'],
      fieldLength: json['field_length'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Label': label,
      'Type': type,
      'Value': value,
      'data_type': dataType,
      'is_mandatory': isMandatory,
      'is_editable': isEditable,
      'field_length': fieldLength,
    };
  }
}
