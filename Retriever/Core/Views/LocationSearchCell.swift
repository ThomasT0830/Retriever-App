//
//  LocationSearchCell.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/23.
//

import SwiftUI

struct LocationSearchCell: View {
    let title: String
    let subtitle: String
    let imageName: String
    
    var body: some View {
        VStack (alignment: .leading){
            HStack (spacing: 15){
                Image(systemName: imageName)
                    .resizable()
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                    .frame(width: 40, height: 40)
                VStack (alignment: .leading, spacing: 5){
                    Text(title)
                        .font(.body)
                    if subtitle != "" {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundStyle(Color(.gray))
                    }
                }
            }
            .padding(.vertical, 8)
            Divider()
        }
    }
}

#Preview {
    LocationSearchCell(title: "Taipei American School", subtitle: "800 Zhongshan North Road, Section 6, Taipei, Taiwan, ROC", imageName: "mappin.circle.fill")
}
