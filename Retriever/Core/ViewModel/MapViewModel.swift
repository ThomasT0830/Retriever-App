//
//  MapViewModel.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/21.
//

import SwiftUI

class MapViewModel: ObservableObject {
    @Published var carTime: Double? = nil
    @Published var walkTime: Double? = nil
    @Published var transitTime: Double? = nil
    @Published var updated: Bool = false
}
