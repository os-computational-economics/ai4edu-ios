//
//  PDFViewer.swift
//  ai4edu
//
//  Created by Sam Jin on 4/13/25.
//

import SwiftUI
import PDFKit

struct PDFViewer: View {
    let url: URL
    let fileName: String
    @Binding var showPDFViewer: Bool
    @State private var isContentVisible: Bool = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
                .opacity(isContentVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: isContentVisible)
            
            VStack(spacing: 0) {
                HStack {
                    Text(fileName)
                        .font(.headline)
                        .lineLimit(1)
                        .padding(.leading)
                        .opacity(isContentVisible ? 1 : 0)
                        .offset(y: isContentVisible ? 0 : -20)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isContentVisible = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showPDFViewer = false
                            }
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding()
                            .opacity(isContentVisible ? 1 : 0)
                            .offset(y: isContentVisible ? 0 : -20)
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(UIColor.separator)),
                    alignment: .bottom
                )
                
                // PDF View
                PDFKitView(url: url)
                    .edgesIgnoringSafeArea(.bottom)
                    .opacity(isContentVisible ? 1 : 0)
                    .offset(y: isContentVisible ? 0 : 20)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isContentVisible = true
            }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // TODO: Update
    }
}
