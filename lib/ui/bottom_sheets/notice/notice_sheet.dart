import 'package:flutter/material.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'package:marina_aqua/ui/common/ui_helpers.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import 'notice_sheet_model.dart';

class NoticeSheet extends StackedView<NoticeSheetModel> {
  final Function(SheetResponse)? completer;
  final SheetRequest request;
  const NoticeSheet({Key? key, required this.completer, required this.request})
      : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    NoticeSheetModel viewModel,
    Widget? child,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (request.title != null && request.title!.isNotEmpty)
              Text(
                request.title!,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            verticalSpaceTiny,
            if (request.description != null && request.description!.isNotEmpty)
              Text(
                request.description!,
                style: const TextStyle(fontSize: 14, color: kcMediumGrey),
                softWrap: true,
              ),
            verticalSpaceLarge,
          ],
        ),
      ),
    );
  }

  @override
  NoticeSheetModel viewModelBuilder(BuildContext context) => NoticeSheetModel();
}
