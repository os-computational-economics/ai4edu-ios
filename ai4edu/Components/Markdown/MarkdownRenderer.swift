//
//  MarkdownRenderer.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//  Referencing code from AI4EDU Research

import SwiftUI
import WebKit

// MARK: - Markdown Text View

struct MarkdownText: View {
    let text: String
    let isFromUser: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseBlocks(text), id: \.id) { block in
                switch block.type {
                case .text:
                    formattedText(block.content)
                        .foregroundColor(isFromUser ? .white : Color(.darkText))
                
                case .heading1:
                    Text(block.content)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        .foregroundColor(isFromUser ? .white : Color(.darkText))
                
                case .heading2:
                    Text(block.content)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                        .padding(.top, 6)
                        .padding(.bottom, 2)
                        .foregroundColor(isFromUser ? .white : Color(.darkText))
                
                case .heading3:
                    Text(block.content)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.medium)
                        .padding(.top, 4)
                        .padding(.bottom, 2)
                        .foregroundColor(isFromUser ? .white : Color(.darkText))
                
                case .code:
                    CodeBlockView(code: block.content, language: block.language ?? "")
                
                case .latex:
                    LaTeXView(latex: block.content)
                
                case .codeInline:
                    Text(block.content)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(isFromUser ? 
                                   Color.white.opacity(0.2) : 
                                   Color(UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1.0)))
                        .cornerRadius(4)
                        .foregroundColor(isFromUser ? .white : Color(.darkText))
                }
            }
        }
    }
    
    private func formattedText(_ text: String) -> Text {
        let parts = parseInlineFormatting(text)
        var textView = Text("")
        
        for part in parts {
            var partText = Text(part.text)
            
            if part.isBold {
                partText = partText.bold()
            }
            if part.isItalic {
                partText = partText.italic()
            }
            if part.isCode {
                partText = partText
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isFromUser ? .white : Color(.darkText))
            }
            
            textView = textView + partText
        }
        
        return textView
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
    let code: String
    let language: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if !language.isEmpty {
                    Text(language)
                        .font(.caption)
                        .padding(.leading, 8)
                        .padding(.top, 4)
                        .foregroundColor(.secondary)
                }
                
                SyntaxHighlightedText(code: code, language: language)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(UIColor(red: 0.15, green: 0.16, blue: 0.21, alpha: 1.0))) // Dark background for code
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
    }
}

struct SyntaxHighlightedText: View {
    let code: String
    let language: String
    
    var body: some View {
        let attributedString = highlightSyntax(code: code, language: language)
        Text(AttributedString(attributedString))
            .font(.system(.body, design: .monospaced))
    }
    
    private func highlightSyntax(code: String, language: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: code)
        
        // Base font and color
        let wholeRange = NSRange(location: 0, length: code.count)
        let baseFontAttribute: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.white
        ]
        attributedString.addAttributes(baseFontAttribute, range: wholeRange)
        
        // Define regex patterns and colors for common syntax elements
        let patterns: [(pattern: String, color: UIColor)] = [
            // Keywords
            (#"(^|\s+)(func|let|var|if|else|for|while|return|class|struct|enum|import|switch|case|guard|break|continue|public|private|internal|static|override|mutating|throw|throws|try|catch)(\s+|$|\(|\{)"#, UIColor(red: 0.91, green: 0.45, blue: 0.83, alpha: 1.0)),
            
            // Strings
            (#"\".*?\""#, UIColor(red: 0.98, green: 0.65, blue: 0.30, alpha: 1.0)),
            (#"\'.*?\'"#, UIColor(red: 0.98, green: 0.65, blue: 0.30, alpha: 1.0)),
            
            // Numbers
            (#"(\s+|\(|^)(\d+)(\s+|\)|$|\.|,|;)"#, UIColor(red: 0.45, green: 0.82, blue: 0.96, alpha: 1.0)),
            
            // Comments
            (#"//.*?(\n|$)"#, UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1.0)),
            
            // Function calls
            (#"(\w+)\("#, UIColor(red: 0.36, green: 0.96, blue: 0.85, alpha: 1.0)),
            
            // Python-specific
            (#"(^|\s+)(def|print|import|from|as|with|in|is|not|or|and|True|False|None)(\s+|$|\(|\:)"#, UIColor(red: 0.91, green: 0.45, blue: 0.83, alpha: 1.0)),
            
            // JavaScript-specific
            (#"(^|\s+)(const|function|this|typeof|new|undefined|null)(\s+|$|\(|\{)"#, UIColor(red: 0.91, green: 0.45, blue: 0.83, alpha: 1.0)),
        ]
        
        // Apply syntax highlighting based on regex patterns
        for (pattern, color) in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.count))
                
                for match in matches {
                    // If there's a captured group, highlight just that
                    if match.numberOfRanges > 1 {
                        for i in 1..<match.numberOfRanges {
                            let range = match.range(at: i)
                            if range.location != NSNotFound {
                                attributedString.addAttribute(.foregroundColor, value: color, range: range)
                            }
                        }
                    } else {
                        // Otherwise highlight the whole match
                        attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
                    }
                }
            } catch {
                // Error creating regex
            }
        }
        
        return attributedString
    }
}

// MARK: - LaTeX Renderer

struct LaTeXView: View {
    let latex: String
    @State private var height: CGFloat = 50
    
    var body: some View {
        WebView(html: latexHTML(latex: latex), dynamicHeight: $height)
            .frame(height: height)
            .cornerRadius(8)
    }
    
    private func latexHTML(latex: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
            <style>
                body {
                    font-size: 16px;
                    padding: 8px;
                    margin: 0;
                    background-color: rgba(245, 245, 245, 0.3);
                    border-radius: 8px;
                }
                .math-container {
                    overflow-x: auto;
                    padding: 4px;
                }
            </style>
        </head>
        <body>
            <div class="math-container">
                \\(\(latex)\\)
            </div>
            <script>
                window.onload = function() {
                    setTimeout(function() {
                        window.webkit.messageHandlers.heightObserver.postMessage(document.body.scrollHeight);
                    }, 300);
                }
            </script>
        </body>
        </html>
        """
    }
}

// MARK: - WebView for LaTeX Rendering

struct WebView: UIViewRepresentable {
    let html: String
    @Binding var dynamicHeight: CGFloat
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        
        let userController = WKUserContentController()
        userController.add(context.coordinator, name: "heightObserver")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userController
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { (height, error) in
                if let height = height as? CGFloat {
                    self.parent.dynamicHeight = height
                }
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "heightObserver", let height = message.body as? CGFloat {
                self.parent.dynamicHeight = height
            }
        }
    }
}

// MARK: - Content Block Parsing

struct ContentBlock: Identifiable {
    enum BlockType {
        case text
        case code
        case latex
        case codeInline
        case heading1
        case heading2
        case heading3
    }
    
    let id = UUID()
    let type: BlockType
    let content: String
    let language: String?
}

// Parse text into content blocks (regular text, code blocks, LaTeX)
func parseBlocks(_ text: String) -> [ContentBlock] {
    var blocks: [ContentBlock] = []
    
    // Regex patterns
    let codeBlockPattern = #"```([a-zA-Z]*)\n([\s\S]*?)```"# // Code blocks with optional language
    let latexPattern = #"\$\$([\s\S]*?)\$\$"# // LaTeX blocks between $$
    let heading1Pattern = #"^# (.+)$"# // Heading 1 (# Heading)
    let heading2Pattern = #"^## (.+)$"# // Heading 2 (## Heading)
    let heading3Pattern = #"^### (.+)$"# // Heading 3 (### Heading)
    
    // Split into lines to process headings
    let lines = text.components(separatedBy: .newlines)
    var processedText = ""
    var currentBlock = ""
    
    for (index, line) in lines.enumerated() {
        // Check for headings
        if let regex = try? NSRegularExpression(pattern: heading1Pattern, options: []) {
            let nsLine = line as NSString
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsLine.length))
            
            if !matches.isEmpty {
                // If we have accumulated text, add it as a block
                if !currentBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    blocks.append(ContentBlock(type: .text, content: currentBlock, language: nil))
                    currentBlock = ""
                }
                
                // Extract heading content
                if let match = matches.first, match.numberOfRanges > 1 {
                    let contentRange = match.range(at: 1)
                    let headingContent = nsLine.substring(with: contentRange)
                    blocks.append(ContentBlock(type: .heading1, content: headingContent, language: nil))
                }
                continue
            }
        }
        
        // Check for heading 2
        if let regex = try? NSRegularExpression(pattern: heading2Pattern, options: []) {
            let nsLine = line as NSString
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsLine.length))
            
            if !matches.isEmpty {
                // If we have accumulated text, add it as a block
                if !currentBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    blocks.append(ContentBlock(type: .text, content: currentBlock, language: nil))
                    currentBlock = ""
                }
                
                // Extract heading content
                if let match = matches.first, match.numberOfRanges > 1 {
                    let contentRange = match.range(at: 1)
                    let headingContent = nsLine.substring(with: contentRange)
                    blocks.append(ContentBlock(type: .heading2, content: headingContent, language: nil))
                }
                continue
            }
        }
        
        // Check for heading 3
        if let regex = try? NSRegularExpression(pattern: heading3Pattern, options: []) {
            let nsLine = line as NSString
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsLine.length))
            
            if !matches.isEmpty {
                // If we have accumulated text, add it as a block
                if !currentBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    blocks.append(ContentBlock(type: .text, content: currentBlock, language: nil))
                    currentBlock = ""
                }
                
                // Extract heading content
                if let match = matches.first, match.numberOfRanges > 1 {
                    let contentRange = match.range(at: 1)
                    let headingContent = nsLine.substring(with: contentRange)
                    blocks.append(ContentBlock(type: .heading3, content: headingContent, language: nil))
                }
                continue
            }
        }
        
        // If not a heading, add to current block
        currentBlock += line
        
        // Add newline if not the last line
        if index < lines.count - 1 {
            currentBlock += "\n"
        }
    }
    
    // Add any remaining text
    if !currentBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        processedText = currentBlock
    }
    
    // Process the remaining text for code blocks and LaTeX
    if !processedText.isEmpty {
        // Process code blocks
        var remainingText = processedText
        
        // Extract code blocks
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) {
            let nsString = remainingText as NSString
            let matches = regex.matches(in: remainingText, options: [], range: NSRange(location: 0, length: nsString.length))
            
            var lastEndIndex = 0
            
            for match in matches {
                let codeRange = match.range(at: 0)
                let languageRange = match.range(at: 1)
                let contentRange = match.range(at: 2)
                
                // Add text before code block
                if codeRange.location > lastEndIndex {
                    let textRange = NSRange(location: lastEndIndex, length: codeRange.location - lastEndIndex)
                    let textContent = nsString.substring(with: textRange)
                    if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        blocks.append(ContentBlock(type: .text, content: textContent, language: nil))
                    }
                }
                
                // Add code block
                let language = languageRange.length > 0 ? nsString.substring(with: languageRange) : ""
                let content = nsString.substring(with: contentRange)
                blocks.append(ContentBlock(type: .code, content: content, language: language))
                
                lastEndIndex = codeRange.location + codeRange.length
            }
            
            // Add remaining text
            if lastEndIndex < nsString.length {
                let textRange = NSRange(location: lastEndIndex, length: nsString.length - lastEndIndex)
                remainingText = nsString.substring(with: textRange)
            } else {
                remainingText = ""
            }
        }
        
        // Only process LaTeX if there's remaining text
        if !remainingText.isEmpty {
            // Process LaTeX blocks (same as before)
            if let regex = try? NSRegularExpression(pattern: latexPattern, options: []) {
                let nsString = remainingText as NSString
                let matches = regex.matches(in: remainingText, options: [], range: NSRange(location: 0, length: nsString.length))
                
                var lastEndIndex = 0
                
                for match in matches {
                    let latexBlockRange = match.range(at: 0)
                    let latexContentRange = match.range(at: 1)
                    
                    // Add text before LaTeX block
                    if latexBlockRange.location > lastEndIndex {
                        let textRange = NSRange(location: lastEndIndex, length: latexBlockRange.location - lastEndIndex)
                        let textContent = nsString.substring(with: textRange)
                        if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            blocks.append(ContentBlock(type: .text, content: textContent, language: nil))
                        }
                    }
                    
                    // Add LaTeX block
                    let content = nsString.substring(with: latexContentRange)
                    blocks.append(ContentBlock(type: .latex, content: content, language: nil))
                    
                    lastEndIndex = latexBlockRange.location + latexBlockRange.length
                }
                
                // Add remaining text
                if lastEndIndex < nsString.length {
                    let textRange = NSRange(location: lastEndIndex, length: nsString.length - lastEndIndex)
                    let textContent = nsString.substring(with: textRange)
                    if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        blocks.append(ContentBlock(type: .text, content: textContent, language: nil))
                    }
                }
            } else {
                // If no LaTeX was found, add remaining text as a text block
                if !remainingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    blocks.append(ContentBlock(type: .text, content: remainingText, language: nil))
                }
            }
        }
    }
    
    // If no blocks were created, return the original text as a single block
    if blocks.isEmpty {
        blocks.append(ContentBlock(type: .text, content: text, language: nil))
    }
    
    return blocks
}

// MARK: - Inline Text Formatting

struct TextPart {
    let text: String
    let isBold: Bool
    let isItalic: Bool
    let isCode: Bool
}

func parseInlineFormatting(_ text: String) -> [TextPart] {
    var parts: [TextPart] = []
    
    // Regex patterns for bold, italic, and inline code
    let inlineCodePattern = #"`(.*?)`"#
    
    // First, find all inline code since it can contain asterisks
    if let regex = try? NSRegularExpression(pattern: inlineCodePattern, options: []) {
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var lastEndIndex = 0
        
        for match in matches {
            let codeRange = match.range(at: 0)
            let contentRange = match.range(at: 1)
            
            // Add text before code
            if codeRange.location > lastEndIndex {
                let textRange = NSRange(location: lastEndIndex, length: codeRange.location - lastEndIndex)
                let textContent = nsString.substring(with: textRange)
                parseBoldItalic(textContent, addTo: &parts)
            }
            
            // Add code part
            let content = nsString.substring(with: contentRange)
            parts.append(TextPart(text: content, isBold: false, isItalic: false, isCode: true))
            
            lastEndIndex = codeRange.location + codeRange.length
        }
        
        // Add remaining text
        if lastEndIndex < nsString.length {
            let textRange = NSRange(location: lastEndIndex, length: nsString.length - lastEndIndex)
            let textContent = nsString.substring(with: textRange)
            parseBoldItalic(textContent, addTo: &parts)
        } else if matches.isEmpty {
            // If no inline code, just parse for bold/italic
            parseBoldItalic(text, addTo: &parts)
        }
    } else {
        // If regex fails, add the whole text as a plain part
        parts.append(TextPart(text: text, isBold: false, isItalic: false, isCode: false))
    }
    
    return parts
}

// Helper function to parse bold and italic formatting
func parseBoldItalic(_ text: String, addTo parts: inout [TextPart]) {
    // If text is empty, don't add anything
    if text.isEmpty {
        return
    }
    
    // Try to find bold text first
    if let regex = try? NSRegularExpression(pattern: #"\*\*(.*?)\*\*"#, options: []) {
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var lastEndIndex = 0
        
        for match in matches {
            let boldRange = match.range(at: 0)
            let contentRange = match.range(at: 1)
            
            // Add text before bold
            if boldRange.location > lastEndIndex {
                let textRange = NSRange(location: lastEndIndex, length: boldRange.location - lastEndIndex)
                let textContent = nsString.substring(with: textRange)
                parseItalic(textContent, addTo: &parts)
            }
            
            // Add bold part
            let content = nsString.substring(with: contentRange)
            parts.append(TextPart(text: content, isBold: true, isItalic: false, isCode: false))
            
            lastEndIndex = boldRange.location + boldRange.length
        }
        
        // Add remaining text
        if lastEndIndex < nsString.length {
            let textRange = NSRange(location: lastEndIndex, length: nsString.length - lastEndIndex)
            let textContent = nsString.substring(with: textRange)
            parseItalic(textContent, addTo: &parts)
        } else if matches.isEmpty {
            // If no bold text, just parse for italic
            parseItalic(text, addTo: &parts)
        }
    } else {
        // If regex fails, try to parse for italic
        parseItalic(text, addTo: &parts)
    }
}

// Helper function to parse italic formatting
func parseItalic(_ text: String, addTo parts: inout [TextPart]) {
    // If text is empty, don't add anything
    if text.isEmpty {
        return
    }
    
    if let regex = try? NSRegularExpression(pattern: #"\*(.*?)\*"#, options: []) {
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var lastEndIndex = 0
        
        for match in matches {
            let italicRange = match.range(at: 0)
            let contentRange = match.range(at: 1)
            
            // Add text before italic
            if italicRange.location > lastEndIndex {
                let textRange = NSRange(location: lastEndIndex, length: italicRange.location - lastEndIndex)
                let textContent = nsString.substring(with: textRange)
                if !textContent.isEmpty {
                    parts.append(TextPart(text: textContent, isBold: false, isItalic: false, isCode: false))
                }
            }
            
            // Add italic part
            let content = nsString.substring(with: contentRange)
            parts.append(TextPart(text: content, isBold: false, isItalic: true, isCode: false))
            
            lastEndIndex = italicRange.location + italicRange.length
        }
        
        // Add remaining text
        if lastEndIndex < nsString.length {
            let textRange = NSRange(location: lastEndIndex, length: nsString.length - lastEndIndex)
            let textContent = nsString.substring(with: textRange)
            if !textContent.isEmpty {
                parts.append(TextPart(text: textContent, isBold: false, isItalic: false, isCode: false))
            }
        } else if matches.isEmpty {
            // If no italic text, add whole text as plain
            parts.append(TextPart(text: text, isBold: false, isItalic: false, isCode: false))
        }
    } else {
        // If regex fails, add the whole text as a plain part
        parts.append(TextPart(text: text, isBold: false, isItalic: false, isCode: false))
    }
}
