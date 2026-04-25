import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/screens/doctor/model/doctor_list_res.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';
import '../../../utils/app_common.dart';
import '../../service/model/service_list_model.dart';
import '../../slots/booking_form_controller.dart';
import '../../slots/booking_form_screen.dart';

class DoctorServiceCard extends StatelessWidget {
  final ServiceElement serviceElement;
  final Doctor? doctor;
  const DoctorServiceCard(
      {super.key, required this.serviceElement, this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationDefault(color: context.cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                serviceElement.serviceName,
                overflow: TextOverflow.ellipsis,
                style: boldTextStyle(size: 16),
              ).expand(),
              Obx(() {
                return Text(
                  locale.value.bookNow,
                  style: primaryTextStyle(color: context.primaryColor),
                ).onTap(() {
                  if (doctor == null) {
                    toast(errorSomethingWentWrong);
                    return;
                  }

                  // Set globals first so BookingFormController.onInit reads
                  // the correct service/doctor/clinic context.
                  currentSelectedDoctor(doctor!);
                  currentSelectedService(serviceElement);
                  if (currentSelectedClinic.value.id.isNegative &&
                      doctor!.clinics.isNotEmpty) {
                    currentSelectedClinic(doctor!.clinics.first);
                  }

                  final BookingFormController bookingFormCont =
                      Get.put(BookingFormController());
                  bookingFormCont.selectedDoctor(doctor!);
                  bookingFormCont.doctorNameText(doctor!.fullName.isNotEmpty
                      ? doctor!.fullName
                      : '${doctor!.firstName} ${doctor!.lastName}'.trim());
                  bookingFormCont.selectedService(serviceElement);
                  bookingFormCont.serviceNameText(
                    serviceElement.localizedName.isNotEmpty
                        ? serviceElement.localizedName
                        : serviceElement.serviceName,
                  );
                  if (!currentSelectedClinic.value.id.isNegative) {
                    bookingFormCont.selectedClinic(currentSelectedClinic.value);
                    bookingFormCont
                        .clinicNameText(currentSelectedClinic.value.name);
                  }

                  Get.to(BookingFormScreen());
                });
              }),
            ],
          ),
          16.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${locale.value.totalAppointmentsDone}:",
                style: secondaryTextStyle(size: 14),
              ),
              Text(
                "${serviceElement.totalAppointments}",
                style: primaryTextStyle(),
              ),
            ],
          ),
          8.height,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${locale.value.clinicName}:",
                style: secondaryTextStyle(size: 14),
              ).flexible(),
              Text(
                serviceElement.clinicName
                    .map((e) => e.validate())
                    .toList()
                    .join(', '),
                style: primaryTextStyle(),
              ).flexible(),
            ],
          ),
        ],
      ),
    );
  }
}
