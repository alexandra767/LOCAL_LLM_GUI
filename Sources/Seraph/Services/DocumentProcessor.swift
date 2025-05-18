import Foundation
import Vision
import PDFKit
import ImageIO
import SwiftUI
import AppKit

class DocumentProcessor: ObservableObject {
    @Published var processingProgress: Double = 0.0
    @Published var processingError: Error?
    
    func processFile(at url: URL) async throws -> DocumentAttachment {
        guard let type = DocumentType.allCases.first(where: { type in
            type.supportedExtensions.contains(url.pathExtension.lowercased())
        }) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported file type"])
        }
        
        let content: String
        switch type {
        case .text, .markdown:
            content = try String(contentsOf: url)
        case .pdf:
            content = try await processPDF(at: url)
        case .image:
            content = try await processImage(at: url)
        }
        
        return DocumentAttachment(
            name: url.lastPathComponent,
            type: type,
            content: content
        )
    }
    
    private func processPDF(at url: URL) async throws -> String {
        let pdf = PDFDocument(url: url)
        guard let pdf else { throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load PDF"]) }
        
        var content = ""
        for i in 0..<pdf.pageCount {
            guard let page = pdf.page(at: i) else { continue }
            content += page.string ?? ""
            processingProgress = Double(i + 1) / Double(pdf.pageCount)
        }
        return content
    }
    
    private func processImage(at url: URL) async throws -> String {
        guard let image = NSImage(contentsOf: url) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to CGImage"])
        }
        
        // Use a continuation to handle the callback-based VNRecognizeTextRequest
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                DispatchQueue.main.async {
                    self.processingProgress = 1.0
                }
                
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            do {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func extractMetadata(from url: URL) -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        // Get file attributes
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            metadata["size"] = attributes[.size] as? Int
            metadata["creationDate"] = attributes[.creationDate] as? Date
            metadata["modificationDate"] = attributes[.modificationDate] as? Date
        } catch {
            print("Error extracting metadata: \(error)")
        }
        
        // Get image metadata
        if url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "jpeg" {
            if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
               let metadataDict = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                metadata["imageMetadata"] = metadataDict
            }
        }
        
        return metadata
    }
}
