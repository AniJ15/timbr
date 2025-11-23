//
//  ExploreView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct ExploreView: View {
    var body: some View {
        ZStack {
            Color.timbrDark.ignoresSafeArea()
            
            VStack {
                Text("Explore")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

