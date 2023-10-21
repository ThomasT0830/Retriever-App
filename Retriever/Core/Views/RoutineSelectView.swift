//
//  RoutineSelectView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/8.
//

import SwiftUI

struct RoutineSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tabManager: TabManager
    
    @Binding var routine: [Int]

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        ForEach(1..<8) { day in
                            HStack {
                                Text(numToDay(day))
                                    .foregroundStyle(.black)
                                Spacer()
                                if routine.contains(day) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture {
                                if routine.contains(day){
                                    routine.remove(at: routine.firstIndex(of: day) ?? 0)
                                }
                                else {
                                    routine.append(day)
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .background(Color(Color.backgroundColor))
        // .onAppear(perform: tabManager.turnOff)
    }
}

#Preview {
    RoutineSelectView(routine: .constant([1]))
}
