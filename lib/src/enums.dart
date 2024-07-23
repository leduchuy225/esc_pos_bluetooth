/*
 * esc_pos_bluetooth
 * Created by Andrey Ushakov
 * 
 * Copyright (c) 2020. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

class PosPrintResult {
  const PosPrintResult._internal(this.value);
  final int value;
  static const success = PosPrintResult._internal(1);
  static const timeout = PosPrintResult._internal(2);
  static const printerNotSelected = PosPrintResult._internal(3);
  static const ticketEmpty = PosPrintResult._internal(4);
  static const printInProgress = PosPrintResult._internal(5);
  static const scanInProgress = PosPrintResult._internal(6);
  static const error = PosPrintResult._internal(7);

  String get msg {
    if (value == PosPrintResult.success.value) {
      return 'Success';
    } else if (value == PosPrintResult.timeout.value) {
      return 'Error. Printer connection timeout';
    } else if (value == PosPrintResult.printerNotSelected.value) {
      return 'Error. Printer not selected';
    } else if (value == PosPrintResult.ticketEmpty.value) {
      return 'Error. Ticket is empty';
    } else if (value == PosPrintResult.printInProgress.value) {
      return 'Error. Another print in progress';
    } else if (value == PosPrintResult.scanInProgress.value) {
      return 'Error. Printer scanning in progress';
    } else {
      return 'Unknown error';
    }
  }

  String get vietnameseMsg {
    if (value == PosPrintResult.success.value) {
      return 'THÀNH CÔNG';
    } else if (value == PosPrintResult.timeout.value) {
      return 'LỖI. Kết nối máy in thất bại';
    } else if (value == PosPrintResult.printerNotSelected.value) {
      return 'LỖI. Không chọn được máy in';
    } else if (value == PosPrintResult.ticketEmpty.value) {
      return 'LỖI. Nội dung in bị trống';
    } else if (value == PosPrintResult.printInProgress.value) {
      return 'LỖI. Tiến trình in khác đang được thực hiện';
    } else if (value == PosPrintResult.scanInProgress.value) {
      return 'LỖI. Đang trong tiến trình tìm máy in';
    } else {
      return 'Có lỗi xảy ra';
    }
  }

  bool get isSuccess {
    return value == PosPrintResult.success.value;
  }
}
