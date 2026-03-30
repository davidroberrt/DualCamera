//
//  ContentView.swift
//  Dual Camera
//
//  Created by David Robert on 29/03/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = DualCameraViewModel()
    
    // posição acumulada
    @State private var position: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    
    // tamanho da miniatura
    let miniSize = CGSize(width: 130, height: 190)
    let margin: CGFloat = 16
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // BACKGROUND (tela cheia)
                MultiCameraPreview(
                    session: vm.session,
                    cameraPosition: vm.isFrontPrimary ? .front : .back
                )
                .ignoresSafeArea()
                
                // MINI CAMERA (overlay)
                MultiCameraPreview(
                    session: vm.session,
                    cameraPosition: vm.isFrontPrimary ? .back : .front
                )
                .frame(width: miniSize.width, height: miniSize.height)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(radius: 10)
                .position(currentPosition(in: geo.size))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            position.x += value.translation.width
                            position.y += value.translation.height
                            
                            // 🔥 CLAMP (limite da tela)
                            position = clampedPosition(in: geo.size)
                            
                            dragOffset = .zero
                        }
                )
                .onTapGesture {
                    withAnimation(.spring()) {
                        vm.isFrontPrimary.toggle()
                    }
                }
                
                // BOTÃO GRAVAR
                VStack {
                    Spacer()
                    
                    Button(action: { vm.toggleRecording() }) {
                        Circle()
                            .fill(vm.isRecording ? Color.red : Color.white)
                            .frame(width: 75, height: 75)
                            .overlay(
                                Circle().stroke(Color.black.opacity(0.1), lineWidth: 5)
                            )
                    }
                    .padding(.bottom, 40)
                }
            }
            .onAppear {
                // posição inicial (top-right)
                position = CGPoint(
                    x: geo.size.width - miniSize.width/2 - margin,
                    y: miniSize.height/2 + margin + 40
                )
            }
        }
    }
    
    // posição atual (com drag)
    private func currentPosition(in size: CGSize) -> CGPoint {
        CGPoint(
            x: position.x + dragOffset.width,
            y: position.y + dragOffset.height
        )
    }
    
    // 🔥 trava dentro da tela
    private func clampedPosition(in size: CGSize) -> CGPoint {
        let halfW = miniSize.width / 2
        let halfH = miniSize.height / 2
        
        let minX = halfW + margin
        let maxX = size.width - halfW - margin
        
        let minY = halfH + margin
        let maxY = size.height - halfH - margin
        
        return CGPoint(
            x: min(max(position.x, minX), maxX),
            y: min(max(position.y, minY), maxY)
        )
    }
}
