//
//  Accessibility.swift
//  Calendr
//
//  Created by Paker on 14/07/2021.
//

import Foundation

enum Accessibility {

    enum Main {
        static let view = "main_view"
        static let title = "main_title"
        static let prevBtn = "main_prev_button"
        static let resetBtn = "main_reset_button"
        static let nextBtn = "main_next_button"
        static let calendarBtn = "main_calendar_button"
        static let settingsBtn = "main_settings_button"
        static let pinBtn = "main_pin_button"
    }

    enum MenuBar {
        static let main = "main_status_item"
        static let event = "event_status_item"
    }

    enum Calendar {
        static let view = "calendar_view"
        static let weekNumber = "calendar_week_number"
        static let weekDay = "calendar_week_day"
        static let date = "calendar_date"
        static let today = "calendar_date_today"
        static let selected = "calendar_date_selected"
        static let hovered = "calendar_date_hovered"
        static let event = "calendar_event_dot"
    }

    enum EventDetails {
        static let view = "event_details_view"
    }
}