//
//  ContentView.swift
//  Captain
//
//  Created by Hana Osman on 3/4/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // 1. Background
            Color.white
                .ignoresSafeArea()

            VStack {
                // 2. App Title
                Text("CAPTAIN") .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.top, 48)
                    .frame(maxWidth: .infinity, alignment: .center)

                // bring the logo and buttons closer to the title
                Spacer(minLength: 8)

                // 3. Circular logo with gradient background
                ZStack {
                    //Circle()
                        //.fill(
                            //LinearGradient(
                                //gradient: Gradient(colors: [Color(red: 0.72, green: 0.86, blue: 0.93), Color(red: 0.55, green: 0.75, blue: 0.88)]),
                                //startPoint: .topLeading,
                                //endPoint: .bottomTrailing
                          //  )
                        //)
                        //.frame(width: 220, height: 220)
                        //.shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)

                    Image("CaptainLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 350, height: 350)
                }
                .padding(.bottom, 64)

                Spacer().frame(height: 12)

                // 4. Buttons
                VStack(spacing: 18) {
                    Button(action: {
                        print("Log In tapped")
                    }) {
                        Text("LOG IN")
                            .font(.headline)
                    }
                    .buttonStyle(PillButtonStyle(colors: [Color(red: 0.78, green: 0.94, blue: 0.99), Color(red: 0.68, green: 0.91, blue: 0.98)], foreground: .black))

                    Button(action: {
                        print("Sign Up tapped")
                    }) {
                        Text("SIGN UP")
                            .font(.headline)
                    }
                    .buttonStyle(PillButtonStyle(colors: [Color(red: 0.84, green: 0.87, blue: 0.98), Color(red: 0.72, green: 0.79, blue: 0.96)], foreground: .black))
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 67)
            }
        }
    }
}

// Reusable pill-style button
struct PillButtonStyle: ButtonStyle {
    var colors: [Color]
    var foreground: Color = .black

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foreground)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom))

                    // soft inner highlight
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        .blendMode(.screen)
                        .padding(0.5)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.08 : 0.18), radius: configuration.isPressed ? 6 : 12, x: 0, y: configuration.isPressed ? 3 : 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}


#Preview {
    ContentView()
}
