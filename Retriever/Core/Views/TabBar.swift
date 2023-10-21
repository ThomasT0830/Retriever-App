//
//  TabBar.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/20.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case map
    case calendar
    case checklist
    case gearshape
}

class TabManager: ObservableObject{
    @Published var showTabBar = true
    
    func turnOn() {
        self.showTabBar = true
    }
    
    func turnOff() {
        self.showTabBar = false
    }
}

struct TabBar: View {
    @Binding var selectedTab: Tab
    
    private var fillIcon: String {
        if selectedTab == .map || selectedTab == .gearshape {
            return selectedTab.rawValue + ".fill"
        }
        return selectedTab.rawValue
    }
    
    var body: some View {
        VStack {
            HStack {
                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    Spacer()
                    Image(systemName: selectedTab == tab ? fillIcon : tab.rawValue)
                        .scaleEffect(selectedTab == tab ? 1.25 : 1.0)
                        .foregroundStyle(selectedTab == tab ? .blue : .black)
                        .font(.system(size: 20))
                        .onTapGesture {
                            withAnimation(.interpolatingSpring(mass: 0.7, stiffness: 200, damping: 10, initialVelocity: 4)) {
                                selectedTab = tab
                            }
                        }
                    Spacer()
                }
            }
            .frame(width: nil, height: 40)
            .background(.white)
            .padding([.vertical])
        }
        .background(.white)
    }
}

#Preview {
    TabBar(selectedTab: .constant(.map))
}
