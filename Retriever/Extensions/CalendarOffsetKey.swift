//
//  CalendarOffsetKey.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/7.
//

import SwiftUI

struct CalendarOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
