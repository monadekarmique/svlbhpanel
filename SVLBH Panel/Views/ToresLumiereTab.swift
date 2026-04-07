// SVLBHPanel — Views/ToresLumiereTab.swift
// v7.5.0 — Tores de Lumière · Champ Toroidal hDOM

import SwiftUI
import WebKit

struct ToresLumiereTab: View {
    var body: some View {
        ToresWebView()
            .ignoresSafeArea()
    }
}

struct ToresWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.96, green: 0.93, blue: 0.89, alpha: 1)
        webView.scrollView.bounces = false
        if let url = Bundle.main.url(forResource: "tores-lumiere", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
