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
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .padding()
                }
                Spacer()
            }
            
            PDFKitView(url: url)
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update the view if needed
    }
}
