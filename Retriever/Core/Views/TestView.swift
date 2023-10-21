//
//  TestView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/20.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20){
                VStack(alignment: .leading, spacing: 10){
                    Text("Category")
                        .foregroundColor(.white)
                        .font(.body.bold())
                        .padding(.vertical, 5)
                        .padding(.horizontal, 15)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 5))
                    HStack {
                        Text("Task")
                            .font(.title.bold())
                    }
                    Text("Task")
                        .font(.title2)
                }
                VStack(spacing: 8){
                    HStack(spacing: 15){
                        Image(systemName: "mappin")
                        Text("Text")
                    }
                    HStack(spacing: 15){
                        Image(systemName: "car")
                        Text("Text")
                    }
                    HStack(spacing: 15){
                        Image(systemName: "figure.walk")
                        Text("Text")
                    }
                    HStack(spacing: 15){
                        Image(systemName: "bus.fill")
                        Text("Text")
                    }
                    HStack(spacing: 15){
                        Image(systemName: "calendar")
                        Text("Text")
                    }
                    HStack(spacing: 15){
                        Image(systemName: "clock")
                        Text("Text")
                    }
                    HStack(spacing: 15){
                        Image(systemName: "repeat")
                        Text("Text")
                    }
                }
                .font(.title2)
                
                VStack(alignment: .leading, spacing: 8){
                    Text("Notes:")
                        .font(.title2.bold())
                    Text("Ut luctus malesuada nunc, sed placerat leo malesuada non. Ut tempor tortor nunc, a porttitor libero accumsan eu. Mauris aliquet massa dolor, non tempor neque laoreet sed. Vestibulum sed euismod ante. Nullam eget ipsum finibus, fringilla purus eget, efficitur libero. Sed vel placerat orci. Integer volutpat volutpat eros nec pulvinar.")
                }
            }
            .padding()
            .padding()
            .frame(maxWidth: .infinity)
            .background(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(Color.backgroundColor))
    }
}

#Preview {
    TestView()
}
