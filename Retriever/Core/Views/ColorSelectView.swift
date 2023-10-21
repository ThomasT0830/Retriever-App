//
//  ColorSelectView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/15.
//

import SwiftUI
import SwiftData

struct ColorSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @EnvironmentObject var tabManager: TabManager
    
    @Bindable var settings: AppSettings
    
    var colors: [Color] = [.red, .pink, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .brown, .gray, .black]

    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                GeometryReader { geometry in
                    VStack(spacing: 8) {
                        HStack(spacing: 25) {
                            ForEach(colors[0..<4], id: \.self) { color in
                                if settings.uncategorizedColorString == color.description {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .background(
                                            Circle()
                                                .stroke(style: StrokeStyle(lineWidth: 3))
                                                .foregroundStyle(color.gradient)
                                                .padding(-2)
                                        )
                                        .onTapGesture {
                                            settings.uncategorizedColorString = color.description
                                        }
                                }
                                else {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .onTapGesture {
                                            settings.uncategorizedColorString = color.description
                                        }
                                }
                                
                            }
                        }
                        HStack(spacing: 25) {
                            ForEach(colors[4..<8], id: \.self) { color in
                                if settings.uncategorizedColorString == color.description {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .background(
                                            Circle()
                                                .stroke(style: StrokeStyle(lineWidth: 3))
                                                .foregroundStyle(color.gradient)
                                                .padding(-2)
                                        )
                                        .onTapGesture {
                                            settings.uncategorizedColorString = color.description
                                        }
                                }
                                else {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .onTapGesture {
                                            settings.uncategorizedColorString = color.description
                                        }
                                }
                                
                            }
                        }
                        HStack(spacing: 25) {
                            ForEach(colors[8..<12], id: \.self) { color in
                                if settings.uncategorizedColorString == color.description {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .background(
                                            Circle()
                                                .stroke(style: StrokeStyle(lineWidth: 3))
                                                .foregroundStyle(color.gradient)
                                                .padding(-2)
                                        )
                                        .onTapGesture {
                                            settings.uncategorizedColorString = color.description
                                        }
                                }
                                else {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .onTapGesture {
                                            settings.uncategorizedColorString = color.description
                                        }
                                }
                                
                            }
                        }
                        HStack(spacing: 25) {
                            ForEach(colors[12..<14], id: \.self) { color in
                                if settings.uncategorizedColorString == color.description {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .background(
                                            Circle()
                                                .stroke(style: StrokeStyle(lineWidth: 3))
                                                .foregroundStyle(color.gradient)
                                                .padding(-2)
                                        )
                                        .onTapGesture {
                                            settings.uncategorizedColorString = color.description
                                        }
                                }
                                else {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .onTapGesture {
                                            settings.uncategorizedColorString = color.description
                                        }
                                }
                                
                            }
                        }
                    }
                    .padding()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundColor)
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.topBarTrailing) {
                Button {
                    dismiss()
                    tabManager.turnOn()
                } label: {
                    Text("Done")
                }
            }
        }
        .navigationTitle("Select Color")
        .navigationBarBackButtonHidden()
        .background(Color(Color.backgroundColor))
        .onAppear(perform: tabManager.turnOff)
    }
}

