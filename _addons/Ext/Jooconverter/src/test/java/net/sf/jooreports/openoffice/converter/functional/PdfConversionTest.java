//
// JOOConverter - The Open Source Java/OpenOffice Document Converter
// Copyright (C) 2004-2006 - Mirko Nasato <mirko@artofsolving.com>
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// http://www.gnu.org/copyleft/lesser.html
//
package net.sf.jooreports.openoffice.converter.functional;

import java.io.File;
import java.io.IOException;

import net.sf.jooreports.converter.DocumentFamily;
import net.sf.jooreports.converter.DocumentFormat;
import net.sf.jooreports.converter.util.FileType;

import org.pdfbox.pdmodel.PDDocument;
import org.pdfbox.util.PDFTextStripper;

/**
 * All known input formats should be exportable to PDF. Since PDF is
 * the most popular export format we also check the content. 
 */
public class PdfConversionTest extends AbstractFunctionalConversionTest {

	private String convertAndCheckPdf(String fileName) throws IOException {
		File outputFile = convertAndCheck(fileName, "pdf", FileType.PDF);
		return readPdfText(outputFile);
	}

	private void assertContains(String content, String expected) throws IOException {
		if (content.indexOf(expected) == -1) {
			fail("string not found: \"" + expected + "\"; content is: " + content);
		}
	}

	private String readPdfText(File pdfFile) throws IOException {
	    PDFTextStripper textStripper = new PDFTextStripper();
	    PDDocument document = PDDocument.load(pdfFile);
	    String text = textStripper.getText(document);
	    document.close();
	    return text.trim();
	}

	public void testOdtToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.odt");
		assertEquals("incorrect pdf content", "Hello from an OpenDocument Text!", pdfContent);
	}

	public void testSxwToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.sxw");
		assertEquals("incorrect pdf content", "Hello from an OpenOffice.org 1.0 Text Document!", pdfContent);		
	}

	public void testDocToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.doc");
		assertEquals("incorrect pdf content", "Hello from a Microsoft Word Document!", pdfContent);		
	}

	public void testRtfToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.rtf");
		assertEquals("incorrect pdf content", "Hello from a RTF Document!", pdfContent);
	}

	//TODO: find a WordPerfect document
	public void _testWpdToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.wpd");
		assertEquals("incorrect pdf content", "Hello from a WordPerfect document!", pdfContent);		
	}

	public void testHtmlToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.html");
		assertEquals("incorrect pdf content", "Hello from an HTML page!", pdfContent);
	}

	public void testOdsToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.ods");
		assertContains(pdfContent, "Hello from an OpenDocument Spreadsheet!");		
	}

	public void testSxcToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.sxc");
		assertContains(pdfContent, "Hello from an OpenOffice.org 1.0 Spreadsheet!");		
	}

	public void testXlsToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.xls");
		assertContains(pdfContent, "Hello from a Microsoft Excel Spreadsheet!");		
	}

	public void testOdpToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.odp");
		assertEquals("incorrect pdf content", "Hello from an OpenDocument Presentation!", pdfContent);		
	}

	public void testSxiToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.sxi");
		assertEquals("incorrect pdf content", "Hello from an OpenOffice.org 1.0 Presentation!", pdfContent);		
	}

	public void testPptToPdf() throws IOException {
		String pdfContent = convertAndCheckPdf("hello.ppt");
		assertEquals("incorrect pdf content", "Hello from a Microsoft PowerPoint Presentation!", pdfContent);		
	}

	public void testCustomExportOption() throws IOException {
		String defaultPdfContent = convertAndCheckPdf("two-pages.odt");
		assertEquals("incorrect pdf content", "First page\nSecond page", defaultPdfContent);
		
		// normally configured in the registry
		DocumentFormat customPdfFormat = new DocumentFormat("PDF", "application/pdf", "pdf");
		customPdfFormat.setExportFilter(DocumentFamily.TEXT, "writer_pdf_Export");
		// export the first page only (easy to verify)
		customPdfFormat.setExportOption("PageRange", "1");
		
		File inputFile = getTestFile("two-pages.odt");
		File outputFile = createTempFile("pdf");
		getDocumentConverter().convert(inputFile, outputFile, customPdfFormat);
		checkOutputFile(outputFile, FileType.PDF);
		String customPdfContent = readPdfText(outputFile);
		assertEquals("incorrect pdf content", "First page", customPdfContent);		
	}
}
