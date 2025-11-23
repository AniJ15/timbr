//
//  ProfileView.swift
//  timbr
//
//  Created by Priya Gokhale on 11/15/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.timbrDark.ignoresSafeArea()
            
            VStack {
                Text("Profile")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

