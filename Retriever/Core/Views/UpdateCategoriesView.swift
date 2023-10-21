//
//  UpdateCategoriesView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/8.
//

import SwiftUI
import SwiftData

struct UpdateCategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @EnvironmentObject var tabManager: TabManager
    
    @Bindable var category: Category
    
    @Query private var categories: [Category]
    
    @State private var title: String = ""
    @State private var selectedColor: String = Color.blue.description
    @State private var showAlert = false
    
    var colors: [Color] = [.red, .pink, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .brown, .gray, .black]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                VStack(spacing: 8) {
                    TextField("Category Name", text: $title)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                    Divider()
                    VStack(alignment: .center) {
                        HStack(spacing: 25) {
                            ForEach(colors[0..<4], id: \.self) { color in
                                if selectedColor == color.description {
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
                                            selectedColor = color.description
                                        }
                                }
                                else {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .onTapGesture {
                                            selectedColor = color.description
                                        }
                                }
                                
                            }
                        }
                        HStack(spacing: 25) {
                            ForEach(colors[4..<8], id: \.self) { color in
                                if selectedColor == color.description {
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
                                            selectedColor = color.description
                                        }
                                }
                                else {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .onTapGesture {
                                            selectedColor = color.description
                                        }
                                }
                                
                            }
                        }
                        HStack(spacing: 25) {
                            ForEach(colors[8..<12], id: \.self) { color in
                                if selectedColor == color.description {
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
                                            selectedColor = color.description
                                        }
                                }
                                else {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .onTapGesture {
                                            selectedColor = color.description
                                        }
                                }
                                
                            }
                        }
                        HStack(spacing: 25) {
                            ForEach(colors[12..<14], id: \.self) { color in
                                if selectedColor == color.description {
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
                                            selectedColor = color.description
                                        }
                                }
                                else {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                        .padding(3)
                                        .onTapGesture {
                                            selectedColor = color.description
                                        }
                                }
                                
                            }
                        }
                    }
                    .padding()
                }
                .padding()
                .background(.white, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundColor)
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
            if title.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                ToolbarItem(placement: ToolbarItemPlacement.topBarTrailing) {
                    Button {
                        if !duplicateCategory(Category(title: title, colorString: selectedColor.description)) || category.title == title {
                            category.title = title
                            category.colorString = selectedColor.description
                            
                            dismiss()
                            selectedColor = Color.blue.description
                        }
                        else {
                            showAlert = true
                        }
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
        .navigationTitle("Edit Category")
        .navigationBarBackButtonHidden()
        .background(Color(Color.backgroundColor))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Category Already Exists"), message: Text("Create a category with a different name!"))
        }
        .onAppear {
            tabManager.turnOff()
            title = category.title
            selectedColor = category.colorString
        }
        // .onAppear(perform: tabManager.turnOff)
    }
    
    func duplicateCategory(_ category: Category) -> Bool {
        for c in categories {
            if category.title == c.title {
                return true
            }
        }
        return false
    }
}
