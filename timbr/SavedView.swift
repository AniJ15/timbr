//
//  SavedView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct SavedView: View {
    var body: some View {
        ZStack {
            Color.timbrDark.ignoresSafeArea()
            
            VStack {
                Text("Saved")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

