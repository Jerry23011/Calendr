//
//  StatusItemViewModel.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import RxCocoa
import RxSwift

class StatusItemViewModel {

    let text: Observable<NSAttributedString>

    init(
        dateObservable: Observable<Date>,
        settings: Observable<StatusItemSettings>,
        locale: Locale
    ) {

        let titleIcon = NSAttributedString(string: "\u{1f4c5}", attributes: [
            .font: NSFont(name: "SegoeUISymbol", size: Constants.iconPointSize)!,
            .baselineOffset: Constants.iconBaselineOffset
        ])

        let dateFormatter = DateFormatter(locale: locale)

        text = Observable.combineLatest(
            dateObservable, settings
        )
        .map { date, settings in

            dateFormatter.dateStyle = settings.dateStyle

            let title = NSMutableAttributedString()

            if settings.showIcon {
                title.append(titleIcon)
            }

            if settings.showDate {
                if title.length > 0 {
                    title.append(NSAttributedString(string: "  "))
                }
                title.append(NSAttributedString(string: dateFormatter.string(from: date)))
            }

            return title
        }
    }
}

private enum Constants {

    static let iconPointSize: CGFloat = 14
    static let iconBaselineOffset: CGFloat = -1
}
