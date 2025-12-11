import 'package:flutter/material.dart';

import '../../style/app_colors.dart';

enum ToastType {
  warning,
  error,
  success,
  simple, //default
}

extension EToastType on ToastType {
  Color get backgroundColor {
    switch(this) {
      case ToastType.warning:
        return AppColors.secondary20;
      case ToastType.error:
        return AppColors.errorBackground;
      case ToastType.success:
        return AppColors.successBackground;
      case ToastType.simple:
        return AppColors.primary60;
    }
  }

  Color get color {
    switch(this) {
      case ToastType.warning:
        return AppColors.secondary60;
      case ToastType.error:
        return AppColors.error;
      case ToastType.success:
        return AppColors.success;
      case ToastType.simple:
        return AppColors.backgroundLight;
    }
  }

  Widget get icon {
    return Container();
    // switch(this) {
    //   case ToastType.warning:
    //     return Assets.icon.bold.infoCircle.svg(
    //       color: color,
    //     );
    //   case ToastType.error:
    //     return Assets.icon.bold.closeCircle.svg(
    //       color: color,
    //     );
    //   case ToastType.success:
    //     return Assets.icon.bold.tickCircle.svg(
    //       color: color,
    //     );
    //   case ToastType.simple:
    //     return const SizedBox.shrink();
    //     // TODO: Handle this case.
    // }
  }
}

class Assets {
}
