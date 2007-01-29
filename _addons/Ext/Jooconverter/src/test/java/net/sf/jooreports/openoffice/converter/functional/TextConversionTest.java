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

import net.sf.jooreports.converter.util.FileType;

public class TextConversionTest extends AbstractFunctionalConversionTest {

	public void testOdtToTxt() throws IOException {
		File outputFile = convertAndCheck("hello.odt", "txt", FileType.TXT);
		assertEquals("output content", "Hello from an OpenDocument Text!", readTextContent(outputFile));
	}

	public void testOdtToDoc() throws IOException {
		convertAndCheck("hello.odt", "doc", FileType.MSOFFICE);
	}

	public void testOdtToRtf() throws IOException {
		convertAndCheck("hello.odt", "rtf", FileType.RTF);
	}

	public void testOdtToSxw() throws IOException {
		convertAndCheck("hello.odt", "sxw", FileType.SXW);
	}

	public void testOdtToHtml() throws IOException {
		convertAndCheck("hello.odt", "html", FileType.HTML);
	}

	public void testOdtToXhtml() throws IOException {
		convertAndCheck("hello.odt", "xhtml", FileType.XHTML);
	}

	public void testDocToOdt() throws IOException {
		convertAndCheck("hello.doc", "odt", FileType.ODT);
	}

	public void testSxwToOdt() throws IOException {
		convertAndCheck("hello.sxw", "odt", FileType.ODT);
	}

	public void testRtfToOdt() throws IOException {
		convertAndCheck("hello.rtf", "odt", FileType.ODT);
	}

	public void testHtmlToOdt() throws IOException {
		convertAndCheck("hello.html", "odt", FileType.ODT);
	}
}
