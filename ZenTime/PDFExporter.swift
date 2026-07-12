import AppKit

/// Renders a styled PDF report of per-question times, highlighting over-time questions.
/// Uses only CoreGraphics / AppKit (no third-party dependencies).
enum PDFExporter {

    @MainActor
    static func makePDF(store: ExamStore) -> Data? {
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }

        let margin: CGFloat = 48
        let contentWidth = mediaBox.width - margin * 2

        // Column layout: x offset from the left margin + the width allotted to each cell.
        let colNum: CGFloat = 0,        wNum: CGFloat = 26
        let colName: CGFloat = 34,      wName: CGFloat = 208
        let colMarks: CGFloat = 250,    wMarks: CGFloat = 58
        let colExpected: CGFloat = 316, wExpected: CGFloat = 84
        let colActual: CGFloat = 408,   wActual: CGFloat = contentWidth - 408
        let rowHeight: CGFloat = 26

        var pageOpen = false
        var y: CGFloat = 0

        func beginPage() {
            ctx.beginPDFPage(nil)
            pageOpen = true
            let nsctx = NSGraphicsContext(cgContext: ctx, flipped: false)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = nsctx
            y = mediaBox.height - margin
        }
        func endPage() {
            guard pageOpen else { return }
            NSGraphicsContext.restoreGraphicsState()
            ctx.endPDFPage()
            pageOpen = false
        }

        // Text helpers. y is a top-of-line coordinate in flipped-from-top terms;
        // convert to bottom-left origin when drawing. `width` bounds the cell so
        // adjacent columns never overlap; text is truncated rather than wrapped.
        func draw(_ string: String, at x: CGFloat, top: CGFloat, attrs: [NSAttributedString.Key: Any], height: CGFloat = 18, width: CGFloat? = nil) {
            let w = width ?? (contentWidth - x)
            let rect = CGRect(x: margin + x, y: top - height, width: w, height: height)
            (string as NSString).draw(in: rect, withAttributes: attrs)
        }

        let truncate = NSMutableParagraphStyle()
        truncate.lineBreakMode = .byTruncatingTail

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 26, weight: .semibold),
            .foregroundColor: NSColor(calibratedRed: 0.28, green: 0.34, blue: 0.14, alpha: 1),
        ]
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.darkGray,
        ]
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: truncate,
        ]
        func cellAttrs(over: Bool) -> [NSAttributedString.Key: Any] {
            [
                .font: NSFont.systemFont(ofSize: 12, weight: over ? .semibold : .regular),
                .foregroundColor: over ? NSColor(calibratedRed: 0.72, green: 0.16, blue: 0.16, alpha: 1) : NSColor.black,
                .paragraphStyle: truncate,
            ]
        }

        // Fill a rounded band behind a row.
        func band(top: CGFloat, height: CGFloat, color: NSColor) {
            let rect = CGRect(x: margin, y: top - height, width: contentWidth, height: height)
            let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
            color.setFill()
            path.fill()
        }

        beginPage()

        // Header.
        draw("ZenTime — Exam Time Report", at: 0, top: y, attrs: titleAttrs, height: 30)
        y -= 32
        let examName = store.examName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !examName.isEmpty {
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 15, weight: .medium),
                .foregroundColor: NSColor.darkGray,
                .paragraphStyle: truncate,
            ]
            draw(examName, at: 0, top: y, attrs: nameAttrs, height: 20, width: contentWidth)
            y -= 24
        }
        y -= 6
        let marksStr = store.totalMarks == store.totalMarks.rounded()
            ? String(Int(store.totalMarks)) : String(format: "%.1f", store.totalMarks)
        draw("Total time: \(store.totalSeconds.hms)     Total marks: \(marksStr)     Questions: \(store.questions.count)",
             at: 0, top: y, attrs: subAttrs)
        y -= 18
        let perMark = store.timePerMark
        draw("Time budget per mark: \(String(format: "%.1f", perMark))s",
             at: 0, top: y, attrs: subAttrs)
        y -= 30

        // Table header — redrawn at the top of every page.
        func drawTableHeader() {
            band(top: y, height: rowHeight, color: NSColor(calibratedRed: 0.34, green: 0.40, blue: 0.18, alpha: 1))
            let headerTop = y - 4
            draw("#", at: colNum + 8, top: headerTop, attrs: headerAttrs, width: wNum)
            draw("Question", at: colName, top: headerTop, attrs: headerAttrs, width: wName)
            draw("Marks", at: colMarks, top: headerTop, attrs: headerAttrs, width: wMarks)
            draw("Expected", at: colExpected, top: headerTop, attrs: headerAttrs, width: wExpected)
            draw("Actual", at: colActual, top: headerTop, attrs: headerAttrs, width: wActual)
            y -= rowHeight + 4
        }
        drawTableHeader()

        // Rows.
        for (i, q) in store.questions.enumerated() {
            if y < margin + rowHeight * 2 {
                endPage()
                beginPage()
                drawTableHeader()
            }

            let expected = store.expectedTime(for: q)
            let over = q.elapsed > expected + 0.5   // small tolerance

            if over {
                band(top: y, height: rowHeight, color: NSColor(calibratedRed: 0.98, green: 0.90, blue: 0.90, alpha: 1))
            } else if i % 2 == 1 {
                band(top: y, height: rowHeight, color: NSColor(calibratedWhite: 0.95, alpha: 1))
            }

            let rowTop = y - 4
            let attrs = cellAttrs(over: over)
            let qMarks = q.marks == q.marks.rounded() ? String(Int(q.marks)) : String(format: "%.1f", q.marks)

            draw("\(i + 1)", at: colNum + 8, top: rowTop, attrs: attrs, width: wNum)
            draw(q.name, at: colName, top: rowTop, attrs: attrs, width: wName)
            draw(qMarks, at: colMarks, top: rowTop, attrs: attrs, width: wMarks)
            draw(expected.hms, at: colExpected, top: rowTop, attrs: attrs, width: wExpected)
            let actualText = over ? "\(q.elapsed.hms)  ⚠︎ Over" : q.elapsed.hms
            draw(actualText, at: colActual, top: rowTop, attrs: attrs, height: 18, width: wActual)

            y -= rowHeight + 2
        }

        // Footer note — guard against running off the bottom of the last page.
        if y < margin + 24 {
            endPage()
            beginPage()
        }
        y -= 14
        draw("Highlighted rows exceeded their fair time budget (marks × time-per-mark).",
             at: 0, top: y, attrs: subAttrs)

        endPage()
        ctx.closePDF()
        return pdfData as Data
    }

    /// Presents a save panel and writes the PDF. Returns the saved URL, or nil if cancelled/failed.
    @discardableResult
    @MainActor
    static func savePDF(store: ExamStore) -> URL? {
        guard let data = makePDF(store: store) else { return nil }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        let name = store.examName.trimmingCharacters(in: .whitespacesAndNewlines)
        panel.nameFieldStringValue = name.isEmpty
            ? "ZenTime Report.pdf"
            : "ZenTime — \(name).pdf"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        do {
            try data.write(to: url)
            return url
        } catch {
            NSLog("ZenTime PDF save error: \(error.localizedDescription)")
            return nil
        }
    }
}
